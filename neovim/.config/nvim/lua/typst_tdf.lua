local M = {}

local ERROR = vim.log.levels.ERROR
local WARN = vim.log.levels.WARN
local INFO = vim.log.levels.INFO

local function clean_output(value)
	return (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function default_dependencies()
	return {
		context = function()
			return {
				path = vim.api.nvim_buf_get_name(0),
				herdr_env = vim.env.HERDR_ENV,
				pane_id = vim.env.HERDR_PANE_ID,
			}
		end,
		write = function()
			vim.cmd.write()
		end,
		run = function(argv, options)
			return vim.system(argv, options):wait()
		end,
		spawn = function(argv, options)
			return vim.system(argv, options)
		end,
		decode = vim.json.decode,
		shellescape = vim.fn.shellescape,
		notify = vim.notify,
	}
end

local function result_message(prefix, result)
	local detail = clean_output(result.stderr)
	if detail == "" then
		detail = clean_output(result.stdout)
	end
	if detail == "" then
		return prefix
	end
	return prefix .. ":\n" .. detail
end

function M.new(deps)
	deps = deps or default_dependencies()
	local state = {
		pane_id = nil,
		watcher = nil,
	}

	local controller = {}

	local function close_pane(pane_id)
		local result = deps.run({ "herdr", "pane", "close", pane_id }, { text = true })
		if result.code ~= 0 then
			deps.notify(result_message("Could not close the Typst preview pane", result), WARN)
		end
	end

	function controller.is_active()
		return state.pane_id ~= nil or state.watcher ~= nil
	end

	function controller.stop(options)
		options = options or {}
		local watcher = state.watcher
		local pane_id = state.pane_id
		state.watcher = nil
		state.pane_id = nil

		if watcher then
			pcall(watcher.kill, watcher, 15)
		end
		if pane_id then
			close_pane(pane_id)
		end

		if not options.silent and (watcher or pane_id) then
			deps.notify("Typst tdf preview stopped", INFO)
		end
		return true
	end

	function controller.toggle()
		if controller.is_active() then
			return controller.stop()
		end

		local context = deps.context()
		local source = context.path or ""
		if source == "" or not source:lower():match("%.typ$") then
			deps.notify("TypstTdfToggle requires a saved .typ buffer", ERROR)
			return false
		end
		if context.herdr_env ~= "1" or not context.pane_id or context.pane_id == "" then
			deps.notify("TypstTdfToggle requires Neovim to be running inside Herdr", ERROR)
			return false
		end

		local wrote, write_error = pcall(deps.write)
		if not wrote then
			deps.notify("Could not save the Typst buffer:\n" .. tostring(write_error), ERROR)
			return false
		end

		local directory = source:match("^(.*)/[^/]+$") or "."
		local pdf = source:gsub("%.typ$", ".pdf")
		local compile = deps.run({ "typst", "compile", source, pdf }, { cwd = directory, text = true })
		if compile.code ~= 0 then
			deps.notify(result_message("Typst compilation failed", compile), ERROR)
			return false
		end

		local split = deps.run({
			"herdr",
			"pane",
			"split",
			"--current",
			"--direction",
			"right",
			"--ratio",
			"0.5",
			"--cwd",
			directory,
			"--no-focus",
		}, { text = true })
		if split.code ~= 0 then
			deps.notify(result_message("Could not create the Typst preview pane", split), ERROR)
			return false
		end

		local decoded_ok, decoded = pcall(deps.decode, split.stdout)
		local pane_id = decoded_ok and decoded.result and decoded.result.pane and decoded.result.pane.pane_id
		if not pane_id then
			deps.notify("Herdr did not return a pane ID for the Typst preview", ERROR)
			return false
		end

		local viewer_command = "env -u WEZTERM_EXECUTABLE -u TERM_PROGRAM tdf " .. deps.shellescape(pdf)
		local viewer = deps.run({ "herdr", "pane", "run", pane_id, viewer_command }, { text = true })
		if viewer.code ~= 0 then
			close_pane(pane_id)
			deps.notify(result_message("Could not start tdf", viewer), ERROR)
			return false
		end

		local spawned, watcher = pcall(
			deps.spawn,
			{ "typst", "watch", source, pdf },
			{ cwd = directory, text = true }
		)
		if not spawned then
			close_pane(pane_id)
			deps.notify("Could not start typst watch:\n" .. tostring(watcher), ERROR)
			return false
		end

		state.pane_id = pane_id
		state.watcher = watcher
		deps.notify("Typst tdf preview started", INFO)
		return true
	end

	return controller
end

local default_controller = M.new()

function M.setup(controller)
	controller = controller or default_controller
	pcall(vim.api.nvim_del_user_command, "TypstTdfToggle")
	vim.api.nvim_create_user_command("TypstTdfToggle", controller.toggle, {
		desc = "Toggle a tdf Typst preview in a Herdr pane",
	})

	local group = vim.api.nvim_create_augroup("TypstTdf", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			controller.stop({ silent = true })
		end,
	})
end

return M
