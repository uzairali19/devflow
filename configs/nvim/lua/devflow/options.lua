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

-- ---------- providers ------------------------------------------------------
-- Disable provider scripts devflow doesn't need. Each one nvim probes adds
-- startup cost and a checkhealth warning if the runtime is missing.
--   perl: no plugins use it.
--   node: we don't use any rplugin-node plugins.
--   ruby: never used.
-- Python is left enabled (some LSP/formatters benefit from pynvim being
-- available). To silence its checkhealth warning install pynvim into the
-- mise-managed python:  python -m pip install --user pynvim
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0

-- ---------- clipboard ------------------------------------------------------
-- yank/paste hit the system clipboard.
vim.opt.clipboard = 'unnamedplus'

-- Over SSH the remote has no pbcopy/xclip, so nvim's auto-detection fails
-- silently and yanks only land in the + register. Force the built-in OSC52
-- provider so the escape sequence travels:
--   nvim -> tmux -> ssh -> local terminal (Ghostty/iTerm/kitty) -> OS clipboard
-- Requires:
--   * nvim >= 0.10 (built-in vim.ui.clipboard.osc52)
--   * tmux >= 3.2 with `set -g set-clipboard on` (devflow's tmux.conf has it)
--   * a terminal that allows OSC52 writes (Ghostty does by default)
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
  if ok then
    vim.g.clipboard = {
      name  = 'OSC52',
      copy  = { ['+'] = osc52.copy('+'),  ['*'] = osc52.copy('*') },
      paste = { ['+'] = osc52.paste('+'), ['*'] = osc52.paste('*') },
    }
  end
end
