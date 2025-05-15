vim.keymap.set("n", "<leader>ct", "<cmd>tabclose<CR>", { silent = true, noremap = true, desc = "Close current tab" })
vim.keymap.set(
	"n",
	"<leader>st",
	"<cmd>tab split<CR>",
	{ silent = true, noremap = true, desc = "Split window into new tab" }
)

vim.api.nvim_create_autocmd("FileType", {
	pattern = "man",
	callback = function()
		vim.keymap.set(
			"n",
			"gd",
			"<cmd>Man<CR>",
			{ buffer = true, noremap = true, silent = true, desc = "Open Man Page" }
		)
	end,
})

-- Shared variable to hold last directory
local last_cwd = vim.fn.getcwd()

-- Track directory changes and save the old one
vim.api.nvim_create_autocmd("DirChanged", {
	callback = function(args)
		if args and args.old and args.old ~= "" then
			last_cwd = args.old
		end
	end,
})

-- Map <leader>cb to jump back
vim.keymap.set("n", "<leader>cb", function()
	if last_cwd and vim.fn.isdirectory(last_cwd) == 1 then
		vim.cmd("cd " .. vim.fn.fnameescape(last_cwd))
		vim.notify("cd → " .. last_cwd, vim.log.levels.INFO, { title = "Working Directory" })
	else
		vim.notify("No previous directory found", vim.log.levels.WARN)
	end
end, { noremap = true, silent = true, desc = "cd back to previous dir" })

vim.keymap.set("n", "<leader>cd", function()
	local dir = vim.fn.expand("%:p:h")
	vim.cmd("cd " .. dir)
	vim.notify("cd → " .. dir, vim.log.levels.INFO, { title = "Working Directory" })
end, { noremap = true, silent = true, desc = "cd to file dir" })
