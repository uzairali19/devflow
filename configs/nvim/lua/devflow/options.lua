-- options.lua — vim.opt settings only. No keymaps, no autocmds.

local opt = vim.opt

-- ui
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = 'yes'
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.linebreak      = true
opt.termguicolors  = true
opt.showmode       = false   -- statusline shows it
opt.laststatus     = 3
opt.pumheight      = 12
opt.completeopt    = { 'menu', 'menuone', 'noselect' }
opt.list           = true
opt.listchars      = { tab = '» ', trail = '·', nbsp = '␣' }
opt.inccommand     = 'split'

-- indent
opt.expandtab   = true
opt.shiftwidth  = 2
opt.tabstop     = 2
opt.softtabstop = 2
opt.smartindent = true

-- search
opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

-- splits
opt.splitbelow = true
opt.splitright = true

-- ux
opt.mouse       = 'a'
opt.timeoutlen  = 400
opt.updatetime  = 250
opt.undofile    = true
opt.swapfile    = false
opt.backup      = false
opt.confirm     = true

-- system clipboard. Deferred so a missing clipboard provider on a remote
-- box doesn't slow startup. Yanks reach the local clipboard via OSC52 when
-- the terminal supports it (Ghostty does).
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
