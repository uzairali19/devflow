-- ~/.config/nvim/init.lua — devflow
-- Kickstart-style: small entry, real config split under lua/devflow/.
--   options.lua   editor settings
--   keymaps.lua   non-LSP keymaps + autocmds
--   plugins.lua   lazy.nvim spec table

vim.g.mapleader      = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = false   -- flip to true after installing a Nerd Font locally

require('devflow.options')
require('devflow.keymaps')

-- ---------- bootstrap lazy.nvim --------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup(require('devflow.plugins'), {
  ui = {
    -- Plain ASCII fallback when no Nerd Font is installed.
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘', config = '🛠', event = '📅', ft = '📂',
      init = '⚙', keys = '🗝', plugin = '🔌', runtime = '💻',
      require = '🌙', source = '📄', start = '🚀', task = '📌', lazy = '💤 ',
    },
  },
  change_detection = { notify = false },
})
