-- plugins.lua — lazy.nvim spec table.
-- Each entry is a self-contained block: plugin source + setup + keymaps.

return {
  -- ---------- colorscheme ---------------------------------------------------
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('tokyonight').setup({ style = 'night', terminal_colors = true })
      vim.cmd.colorscheme('tokyonight-night')
    end,
  },

  -- ---------- which-key (key hint UI) ---------------------------------------
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'modern',
      spec = {
        { '<leader>f', group = 'find / format' },
        { '<leader>d', group = 'diagnostics' },
        { '<leader>c', group = 'code' },
        { '<leader>r', group = 'rename / refactor' },
      },
    },
  },

  -- ---------- file manager: oil.nvim ----------------------------------------
  -- '-' opens parent directory; <leader>e opens Oil for the cwd.
  {
    'stevearc/oil.nvim',
    dependencies = { { 'nvim-tree/nvim-web-devicons', enabled = false } },
    lazy = false,
    config = function()
      require('oil').setup({
        default_file_explorer = true,
        view_options = { show_hidden = true },
        keymaps = {
          ['q']     = 'actions.close',
          ['<C-h>'] = false,        -- leave Ctrl-h for tmux/window nav
          ['<C-l>'] = false,
        },
      })
      vim.keymap.set('n', '-',         '<CMD>Oil<CR>', { desc = 'open parent (Oil)' })
      vim.keymap.set('n', '<leader>e', '<CMD>Oil<CR>', { desc = 'open Oil' })
    end,
  },

  -- ---------- telescope -----------------------------------------------------
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond  = function() return vim.fn.executable('make') == 1 end,
      },
    },
    config = function()
      local t = require('telescope')
      t.setup({
        defaults = {
          path_display = { 'truncate' },
          mappings = { i = { ['<C-/>'] = 'which_key' } },
        },
      })
      pcall(t.load_extension, 'fzf')

      local b = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', b.find_files,                { desc = 'find files' })
      vim.keymap.set('n', '<leader>fg', b.live_grep,                 { desc = 'live grep' })
      vim.keymap.set('n', '<leader>fb', b.buffers,                   { desc = 'buffers' })
      vim.keymap.set('n', '<leader>fh', b.help_tags,                 { desc = 'help' })
      vim.keymap.set('n', '<leader>fr', b.resume,                    { desc = 'resume picker' })
      vim.keymap.set('n', '<leader>fd', b.diagnostics,               { desc = 'diagnostics' })
      vim.keymap.set('n', '<leader>fs', b.lsp_document_symbols,      { desc = 'document symbols' })
      vim.keymap.set('n', '<leader>fS', b.lsp_dynamic_workspace_symbols, { desc = 'workspace symbols' })
      vim.keymap.set('n', '<leader>/',  b.current_buffer_fuzzy_find, { desc = 'fuzzy in buffer' })
    end,
  },

  -- ---------- treesitter ----------------------------------------------------
  -- Pinned to master. nvim-treesitter's `main` branch is the new
  -- architecture and drops the `nvim-treesitter.configs` module that
  -- this spec relies on; master stays stable.
  --
  -- If startup ever errors with "module 'nvim-treesitter.configs' not
  -- found", clear the cached checkout:
  --   rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
  --   nvim --headless "+Lazy! sync" +qa
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build  = ':TSUpdate',
    config = function()
      local ok, configs = pcall(require, 'nvim-treesitter.configs')
      if not ok then
        vim.schedule(function()
          vim.notify(
            'nvim-treesitter.configs not loadable. Try:\n' ..
            '  rm -rf ~/.local/share/nvim/lazy/nvim-treesitter\n' ..
            '  nvim --headless "+Lazy! sync" +qa',
            vim.log.levels.WARN)
        end)
        return
      end

      configs.setup({
        ensure_installed = {
          'bash', 'css', 'go', 'gomod', 'html', 'javascript', 'json',
          'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'tsx',
          'typescript', 'vim', 'vimdoc', 'yaml',
        },
        auto_install = true,
        highlight    = { enable = true, additional_vim_regex_highlighting = false },
        indent       = { enable = true },
      })
    end,
  },

  -- ---------- mason: install LSP / formatter binaries -----------------------
  { 'williamboman/mason.nvim',           opts = {} },
  { 'williamboman/mason-lspconfig.nvim', dependencies = { 'williamboman/mason.nvim' } },
  { 'WhoIsSethDaniel/mason-tool-installer.nvim', dependencies = { 'williamboman/mason.nvim' } },

  -- ---------- LSP -----------------------------------------------------------
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      -- Targets Neovim 0.11+. Uses vim.lsp.config / vim.lsp.enable so the
      -- deprecated `require('lspconfig').<name>.setup()` path is never hit
      -- (it triggers a warning that prints "framework" as a placeholder).
      -- nvim-lspconfig is still loaded — it provides the per-server
      -- defaults (cmd, root markers, filetypes) under its lsp/ directory.
      --
      -- Pick the right TS server name. Newer nvim-lspconfig provides ts_ls;
      -- the renamed tsserver is gone. Detect what the runtime actually has.
      local function pick_ts_server()
        if #vim.api.nvim_get_runtime_file('lsp/ts_ls.lua', false) > 0 then
          return 'ts_ls'
        end
        if #vim.api.nvim_get_runtime_file('lsp/tsserver.lua', false) > 0 then
          return 'tsserver'
        end
        return 'ts_ls'  -- best guess; pcall below will swallow if missing
      end

      local servers = {
        lua_ls = {
          settings = {
            Lua = { workspace = { checkThirdParty = false }, telemetry = { enable = false } },
          },
        },
        gopls         = {},
        pyright       = {},
        rust_analyzer = {},
        bashls        = {},
        jsonls        = {},
        yamlls        = {},
        html          = {},
        cssls         = {},
        tailwindcss   = {},
      }
      servers[pick_ts_server()] = {}

      require('mason').setup()
      require('mason-lspconfig').setup({
        ensure_installed = vim.tbl_keys(servers),
        -- mason-lspconfig v2 auto-enables installed servers via vim.lsp.enable.
        -- We do that ourselves below so the config is explicit and pcall-safe.
        automatic_enable = false,
      })

      require('mason-tool-installer').setup({
        ensure_installed = {
          'stylua', 'prettier', 'shfmt',
          'gofumpt', 'goimports', 'ruff',
        },
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_cmp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
      if ok_cmp then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- Configure + enable every server. A missing lsp/<name>.lua file (or
      -- a typo) only warns — it never breaks startup.
      local function setup_server(name, cfg)
        cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
        local ok, err = pcall(function()
          vim.lsp.config(name, cfg)
          vim.lsp.enable(name)
        end)
        if not ok then
          vim.schedule(function()
            vim.notify(('devflow: LSP %s skipped — %s'):format(name, err),
              vim.log.levels.WARN)
          end)
        end
      end

      for name, cfg in pairs(servers) do
        setup_server(name, cfg)
      end

      -- Per-buffer keymaps when an LSP attaches.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('devflow-lsp', { clear = true }),
        callback = function(ev)
          local m = function(lhs, rhs, desc, mode)
            vim.keymap.set(mode or 'n', lhs, rhs,
              { buffer = ev.buf, desc = desc, silent = true })
          end
          m('gd',         vim.lsp.buf.definition,      'go to definition')
          m('gD',         vim.lsp.buf.declaration,     'go to declaration')
          m('gi',         vim.lsp.buf.implementation,  'go to implementation')
          m('gr',         vim.lsp.buf.references,      'references')
          m('gt',         vim.lsp.buf.type_definition, 'type definition')
          m('K',          vim.lsp.buf.hover,           'hover docs')
          m('<C-k>',      vim.lsp.buf.signature_help,  'signature help', 'i')
          m('<leader>rn', vim.lsp.buf.rename,          'rename')
          m('<leader>ca', vim.lsp.buf.code_action,     'code action', { 'n', 'v' })
        end,
      })

      -- Diagnostic UI
      vim.diagnostic.config({
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        virtual_text = { spacing = 2, prefix = '●' },
      })
    end,
  },

  -- ---------- completion ----------------------------------------------------
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then return end
          return 'make install_jsregexp'
        end)(),
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp     = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        completion = { completeopt = 'menu,menuone,noselect' },
        mapping = cmp.mapping.preset.insert({
          ['<C-n>']     = cmp.mapping.select_next_item(),
          ['<C-p>']     = cmp.mapping.select_prev_item(),
          ['<CR>']      = cmp.mapping.confirm({ select = false }),
          ['<C-Space>'] = cmp.mapping.complete({}),
          ['<C-d>']     = cmp.mapping.scroll_docs(-4),
          ['<C-f>']     = cmp.mapping.scroll_docs(4),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        },
      })
    end,
  },

  -- ---------- formatting ----------------------------------------------------
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd   = { 'ConformInfo' },
    keys  = {
      {
        '<leader>fm',
        function() require('conform').format({ async = true, lsp_format = 'fallback' }) end,
        desc = 'format buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Skip format-on-save for filetypes whose formatters need extra config.
        local skip = { c = true, cpp = true }
        return {
          timeout_ms = 1000,
          lsp_format = skip[vim.bo[bufnr].filetype] and 'never' or 'fallback',
        }
      end,
      formatters_by_ft = {
        lua             = { 'stylua' },
        python          = { 'ruff_format', 'ruff_organize_imports' },
        javascript      = { 'prettier' },
        typescript      = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        json            = { 'prettier' },
        yaml            = { 'prettier' },
        markdown        = { 'prettier' },
        html            = { 'prettier' },
        css             = { 'prettier' },
        go              = { 'goimports', 'gofumpt' },
        rust            = { 'rustfmt' },
        sh              = { 'shfmt' },
        bash            = { 'shfmt' },
      },
    },
  },

  -- ---------- tmux navigation ----------------------------------------------
  -- Ctrl-h/j/k/l moves between nvim splits. When at the edge of nvim's
  -- windows, falls through to a tmux pane in that direction (calls
  -- `tmux select-pane`). Works without modifying ~/.tmux.conf.
  --
  -- For the *reverse* direction (tmux pane -> nvim split), add the matching
  -- bind-key snippet from vim-tmux-navigator's README to your tmux config.
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft', 'TmuxNavigateDown',
      'TmuxNavigateUp',   'TmuxNavigateRight', 'TmuxNavigatePrevious',
    },
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<CR>',  desc = 'pane left'  },
      { '<C-j>', '<cmd>TmuxNavigateDown<CR>',  desc = 'pane down'  },
      { '<C-k>', '<cmd>TmuxNavigateUp<CR>',    desc = 'pane up'    },
      { '<C-l>', '<cmd>TmuxNavigateRight<CR>', desc = 'pane right' },
    },
  },
}
