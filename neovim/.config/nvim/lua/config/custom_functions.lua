local create_cmd = vim.api.nvim_create_user_command

create_cmd("ToggleBackground", function()
	if vim.o.background == "dark" then
		vim.cmd("set bg=light")
	else
		vim.cmd("set bg=dark")
	end
end, {})

create_cmd("ToggleFloat", function()
	vim.cmd("ToggleTerm direction=float")
end, {})

create_cmd("FormatJSON", function()
	vim.cmd("%!python3 -m json.tool")
end, {})

-- Opens all quickfix files in new tabs - original inspiration  https://vimrcfu.com/snippet/143
create_cmd("Ctabs", function()
	local files = {}
	for _, entry in ipairs(vim.fn.getqflist()) do
		local filename = vim.fn.bufname(entry.bufnr)
		if filename ~= "" then
			files[filename] = true
		end
	end

	for file, _ in pairs(files) do
		vim.cmd("silent tabedit " .. vim.fn.fnameescape(file))
	end
end, {})

create_cmd("ToggleDiagnostics", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, {})
