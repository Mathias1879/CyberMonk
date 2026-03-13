vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.cmd("syntax on")

-- Basic keymap
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
