local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = config_dir .. "/lua/?.lua;" .. package.path

local loaded, typst_tdf = pcall(require, "typst_tdf")
assert(loaded, "expected the typst_tdf module to exist")

local function assert_equal(actual, expected, message)
	assert(
		vim.deep_equal(actual, expected),
		(message or "values differ") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
	)
end

local function new_harness(options)
	options = options or {}
	local calls = {
		write = 0,
		run = {},
		spawn = {},
		notify = {},
		kill = {},
	}

	local process = {
		kill = function(_, signal)
			table.insert(calls.kill, signal)
		end,
	}

	local deps = {
		context = function()
			return options.context
				or {
					path = "/tmp/typst notes/journal.typ",
					herdr_env = "1",
					pane_id = "w1:p1",
				}
		end,
		write = function()
			calls.write = calls.write + 1
		end,
		run = function(argv, run_options)
			table.insert(calls.run, { argv = argv, options = run_options })
			if argv[1] == "typst" then
				return options.compile_result or { code = 0, stdout = "", stderr = "" }
			end
			if argv[1] == "herdr" and argv[3] == "split" then
				return options.split_result
					or { code = 0, stdout = '{"result":{"pane":{"pane_id":"w1:p2"}}}', stderr = "" }
			end
			return { code = 0, stdout = "", stderr = "" }
		end,
		spawn = function(argv, spawn_options)
			table.insert(calls.spawn, { argv = argv, options = spawn_options })
			return process
		end,
		decode = vim.json.decode,
		shellescape = vim.fn.shellescape,
		notify = function(message, level)
			table.insert(calls.notify, { message = message, level = level })
		end,
	}

	return typst_tdf.new(deps), calls
end

local function test_starts_preview_and_stops_it_on_second_toggle()
	local controller, calls = new_harness()

	assert(controller.toggle(), "expected the preview to start")
	assert(controller.is_active(), "expected an active preview")
	assert_equal(calls.write, 1, "buffer should be written before compiling")
	assert_equal(calls.run[1], {
		argv = { "typst", "compile", "/tmp/typst notes/journal.typ", "/tmp/typst notes/journal.pdf" },
		options = { cwd = "/tmp/typst notes", text = true },
	})
	assert_equal(calls.run[2], {
		argv = {
			"herdr",
			"pane",
			"split",
			"--current",
			"--direction",
			"right",
			"--ratio",
			"0.5",
			"--cwd",
			"/tmp/typst notes",
			"--no-focus",
		},
		options = { text = true },
	})
	assert_equal(calls.run[3], {
		argv = {
			"herdr",
			"pane",
			"run",
			"w1:p2",
			"env -u WEZTERM_EXECUTABLE -u TERM_PROGRAM tdf '/tmp/typst notes/journal.pdf'",
		},
		options = { text = true },
	})
	assert_equal(calls.spawn[1], {
		argv = { "typst", "watch", "/tmp/typst notes/journal.typ", "/tmp/typst notes/journal.pdf" },
		options = { cwd = "/tmp/typst notes", text = true },
	})

	assert(controller.toggle(), "expected the preview to stop")
	assert(not controller.is_active(), "expected preview state to be cleared")
	assert_equal(calls.kill, { 15 }, "watcher should receive SIGTERM")
	assert_equal(calls.run[4], {
		argv = { "herdr", "pane", "close", "w1:p2" },
		options = { text = true },
	})
end

local function test_rejects_non_herdr_context()
	local controller, calls = new_harness({
		context = {
			path = "/tmp/journal.typ",
			herdr_env = nil,
			pane_id = nil,
		},
	})

	assert(not controller.toggle(), "expected startup outside Herdr to fail")
	assert_equal(#calls.run, 0)
	assert(calls.notify[1].message:match("Herdr"), "expected a Herdr-specific error")
end

local function test_compile_failure_does_not_create_a_pane()
	local controller, calls = new_harness({
		compile_result = { code = 1, stdout = "", stderr = "Typst compilation failed" },
	})

	assert(not controller.toggle(), "expected failed compilation to abort startup")
	assert(not controller.is_active())
	assert_equal(#calls.run, 1, "only the compile command should run")
	assert_equal(#calls.spawn, 0)
	assert(calls.notify[1].message:match("Typst compilation failed"), "expected compiler output in the error")
end

local function test_setup_registers_the_toggle_command()
	local toggles = 0
	local stops = 0
	local controller = {
		toggle = function()
			toggles = toggles + 1
		end,
		stop = function(options)
			assert(options.silent)
			stops = stops + 1
		end,
	}

	typst_tdf.setup(controller)
	assert_equal(vim.fn.exists(":TypstTdfToggle"), 2)
	vim.cmd.TypstTdfToggle()
	assert_equal(toggles, 1)
	vim.api.nvim_exec_autocmds("VimLeavePre", {})
	assert_equal(stops, 1)
end

local function test_typst_plugin_config_sets_up_both_preview_modes()
	local specs = dofile(config_dir .. "/lua/plugins/util.lua")
	local function find_typst_preview(items)
		for _, item in ipairs(items) do
			if item[1] == "chomosuke/typst-preview.nvim" then
				return item
			end
			if type(item[1]) == "table" then
				local found = find_typst_preview(item)
				if found then
					return found
				end
			end
		end
	end

	local spec = assert(find_typst_preview(specs), "typst-preview.nvim spec not found")
	assert(type(spec.config) == "function", "typst-preview.nvim should configure TypstTdfToggle")

	local browser_setup = 0
	local tdf_setup = 0
	local previous_browser = package.loaded["typst-preview"]
	local previous_tdf = package.loaded.typst_tdf
	package.loaded["typst-preview"] = {
		setup = function(options)
			assert_equal(options, { follow_cursor = true })
			browser_setup = browser_setup + 1
		end,
	}
	package.loaded.typst_tdf = {
		setup = function()
			tdf_setup = tdf_setup + 1
		end,
	}

	spec.config(nil, { follow_cursor = true })
	package.loaded["typst-preview"] = previous_browser
	package.loaded.typst_tdf = previous_tdf

	assert_equal(browser_setup, 1)
	assert_equal(tdf_setup, 1)
end

test_starts_preview_and_stops_it_on_second_toggle()
test_rejects_non_herdr_context()
test_compile_failure_does_not_create_a_pane()
test_setup_registers_the_toggle_command()
test_typst_plugin_config_sets_up_both_preview_modes()

print("typst_tdf tests: ok")
