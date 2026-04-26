-- keymaps.lua — non-LSP keymaps and core autocmds.
-- LSP-buffer keymaps live in plugins.lua next to the LSP setup.
-- Telescope/Oil/format keymaps live with their plugin specs.

local map = function(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs,
    vim.tbl_extend('keep', opts or {}, { silent = true, noremap = true }))
end

-- save
map('n', '<leader>w', ':w<CR>', { desc = 'write' })

-- close buffer (or fall back to Oil if it's the last one). Avoids the
-- empty [No Name] buffer that `:bd` leaves behind in Kickstart-style setups.
vim.keymap.set('n', '<leader>q', function()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  if #buffers > 1 then
    -- bp = previous buffer, bd # = delete the buffer we just left
    vim.cmd('bp | bd #')
  else
    local ok, oil = pcall(require, 'oil')
    if ok then
      oil.open()
    else
      vim.cmd('enew')
    end
  end
end, { silent = true, noremap = true, desc = 'close buffer or open Oil' })

-- clear search highlight
map('n', '<Esc>', ':nohlsearch<CR>')

-- centered jumps
map('n', '<C-d>', '<C-d>zz')
map('n', '<C-u>', '<C-u>zz')
map('n', 'n',     'nzzzv')
map('n', 'N',     'Nzzzv')

-- keep selection on indent
map('v', '<', '<gv')
map('v', '>', '>gv')

-- move visual selection
map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")

-- explicit system-clipboard yank (handy when unnamedplus isn't wired)
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'yank to system clipboard' })
map('n',          '<leader>Y', '"+Y')

-- diagnostics — Telescope LSP pickers cover the rest
map('n', '[d',         vim.diagnostic.goto_prev,    { desc = 'prev diagnostic' })
map('n', ']d',         vim.diagnostic.goto_next,    { desc = 'next diagnostic' })
map('n', '<leader>de', vim.diagnostic.open_float,   { desc = 'line diagnostics' })
map('n', '<leader>dq', vim.diagnostic.setloclist,   { desc = 'diagnostics → loclist' })

-- ---------- autocmds -------------------------------------------------------

local aug = vim.api.nvim_create_augroup('devflow', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = aug,
  callback = function() vim.highlight.on_yank({ timeout = 150 }) end,
})

-- strip trailing whitespace on save (skip diff/patch)
vim.api.nvim_create_autocmd('BufWritePre', {
  group = aug,
  callback = function()
    local ft = vim.bo.filetype
    if ft == 'diff' or ft == 'patch' then return end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- restore last cursor position
vim.api.nvim_create_autocmd('BufReadPost', {
  group = aug,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
