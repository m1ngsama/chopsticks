-- m1ngsama's neovim config

-- 行号
local set = vim.o
set.number = true
set.relativenumber = true

-- 剪贴板
set.clipboard = "unnamed"

-- copy后高亮
vim.api.nvim_create_autocmd({ "TextYankPost" }, {
	pattern = { "*" },
	callback = function()
		vim.highlight.on_yank({
			timeout = 300,
		})
	end,
})

-- keybindings
local opt = { noremap = true, silent = true }

vim.g.mapleader = " "

vim.keymap.set("n", "<C-l>", "<C-w>l", opt)
vim.keymap.set("n", "<C-h>", "<C-w>h", opt)
vim.keymap.set("n", "<C-j>", "<C-w>j", opt)
vim.keymap.set("n", "<C-k>", "<C-w>k", opt)
vim.keymap.set("n", "<leader>v", "<C-w>v", opt)
vim.keymap.set("n", "<leader>s", "<C-w>s", opt)
vim.keymap.set("n", "<leader>[", "<C-o>", opt)
vim.keymap.set("n", "<leader>]", "<C-i>", opt)

-- https://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
vim.keymap.set("n", "j", [[v:count ? 'j' : 'gj']], { noremap = true, expr = true })
vim.keymap.set("n", "k", [[v:count ? 'k' : 'gk']], { noremap = true, expr = true })

-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", --latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	{
		"RRethy/nvim-base16",
		lazy = true,
	},
	{
		cmd = "Telescope",
		keys = {
			{ "<leader>p", ":Telescope find_files<CR>", desc = "find files" },
			{ "<leader>P", ":Telescope live_grep<CR>", desc = "grep files" },
			{ "<leader>rs", ":Telescope resume<CR>", desc = "resume" },
			{ "<leader>q", ":Telescope oldfiles<CR>", desc = "old files" },
		},
		'nvim-telescope/telescope.nvim',
		tag = '0.1.3',
		dependencies = { 'nvim-lua/plenary.nvim' },
	},
})

vim.cmd.colorscheme("base16-tender")
