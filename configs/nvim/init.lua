-- ~/.config/nvim/init.lua
-- minimal starter. no plugin manager, no LSP. add your own under lua/.

vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = "yes"
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.linebreak      = true

opt.expandtab   = true
opt.shiftwidth  = 2
opt.tabstop     = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

opt.mouse         = "a"
opt.clipboard     = "unnamedplus"
opt.splitbelow    = true
opt.splitright    = true
opt.termguicolors = true
opt.timeoutlen    = 400
opt.updatetime    = 250
opt.undofile      = true
opt.swapfile      = false
opt.backup        = false
opt.confirm       = true

opt.showmode    = false
opt.laststatus  = 3
opt.pumheight   = 12
opt.completeopt = { "menu", "menuone", "noselect" }

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
end

map("n", "<leader>w", ":w<CR>",  "write")
map("n", "<leader>q", ":q<CR>",  "quit")
map("n", "<Esc>",     ":nohlsearch<CR>", "clear search hl")

-- window nav (mirrors tmux)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- keep cursor centered
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- keep visual selection on indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- move selected lines
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- explicit system clipboard yank (works when unnamedplus isn't wired)
map({ "n", "v" }, "<leader>y", '"+y', "yank to system clipboard")
map("n",          "<leader>Y", '"+Y', "yank line to system clipboard")

local aug = vim.api.nvim_create_augroup("devflow", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group    = aug,
  callback = function() vim.highlight.on_yank({ timeout = 150 }) end,
})

-- strip trailing whitespace, except in diff/patch
vim.api.nvim_create_autocmd("BufWritePre", {
  group    = aug,
  callback = function()
    local ft = vim.bo.filetype
    if ft == "diff" or ft == "patch" then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group    = aug,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

pcall(vim.cmd.colorscheme, "habamax")
