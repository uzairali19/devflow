# Neovim

Kickstart-style config: small `init.lua` that bootstraps `lazy.nvim` and
loads three modules under `lua/devflow/`.

```text
configs/nvim/
├── init.lua                           entry: leader, lazy bootstrap, requires
└── lua/devflow/
    ├── options.lua                    vim.opt only
    ├── keymaps.lua                    non-LSP keymaps + autocmds
    └── plugins.lua                    lazy.nvim spec table
```

## First run

The first time you launch `nvim`, lazy clones itself, then installs every
plugin and runs `:TSUpdate`, `mason.nvim` queues language-server installs
in the background, and `treesitter` builds the listed parsers. Sit
through the first 30–60 s.

To pre-install everything (CI, automation, fresh server):

```sh
nvim --headless "+Lazy! sync" +qa
```

This works on a server too, but Mason's LSP/formatter installs need
`go` / `python` / `npm` available — running `mise install` first is the
right order.

## Plugins

| Plugin                                  | Purpose                                       |
| --------------------------------------- | --------------------------------------------- |
| folke/lazy.nvim                         | Plugin manager (bootstrapped automatically)   |
| folke/tokyonight.nvim                   | Colorscheme (`tokyonight-night`)              |
| folke/which-key.nvim                    | Pop-up key hints                              |
| stevearc/oil.nvim                       | File explorer as a buffer                     |
| nvim-telescope/telescope.nvim           | Fuzzy finder                                  |
| nvim-telescope/telescope-fzf-native.nvim| Native sorter (built with `make`)             |
| nvim-treesitter/nvim-treesitter         | Syntax highlighting + indent                  |
| neovim/nvim-lspconfig                   | LSP client configs                            |
| williamboman/mason.nvim                 | Installs LSP/formatter binaries               |
| williamboman/mason-lspconfig.nvim       | Bridges Mason ↔ lspconfig                     |
| WhoIsSethDaniel/mason-tool-installer    | Auto-install formatters listed in config      |
| hrsh7th/nvim-cmp + sources              | Completion (LSP, snippets, buffer, path)      |
| L3MON4D3/LuaSnip                        | Snippet engine                                |
| stevearc/conform.nvim                   | Format-on-save runner                         |
| christoomey/vim-tmux-navigator          | `Ctrl-hjkl` across nvim splits + tmux panes   |

## Languages out of the box

**Targets Neovim 0.11+.** LSP setup uses `vim.lsp.config()` + `vim.lsp.enable()`
directly — the deprecated `require('lspconfig').<name>.setup()` path is
not used (it triggers a deprecation warning that mentions `"framework"`).

LSP servers (installed by Mason):

| Server          | Languages                            |
| --------------- | ------------------------------------ |
| `lua_ls`        | Lua                                  |
| `ts_ls`         | TypeScript, JavaScript, React (.tsx) |
| `gopls`         | Go                                   |
| `pyright`       | Python                               |
| `rust_analyzer` | Rust                                 |
| `bashls`        | Bash, sh                             |
| `jsonls`        | JSON                                 |
| `yamlls`        | YAML                                 |
| `html`          | HTML                                 |
| `cssls`         | CSS                                  |
| `tailwindcss`   | Tailwind class completion            |

Each server is set up under `pcall`, so a missing or renamed server
warns once (`devflow: LSP <name> skipped — ...`) without breaking
startup. The `ts_ls` ↔ `tsserver` rename is auto-detected from the
runtime path.

Formatters (via Mason + conform): `stylua`, `prettier`, `shfmt`,
`gofumpt`, `goimports`, `ruff` (also handles import sort).

Treesitter parsers: bash, css, go, html, javascript, json, lua,
markdown, markdown_inline, python, rust, tsx, typescript, vim, vimdoc,
yaml. New filetypes auto-install when first opened.

## Keymaps

Leader is **Space**.

### Find (Telescope)

```text
<leader>ff      find files
<leader>fg      live grep
<leader>fb      buffers
<leader>fh      help tags
<leader>fr      resume last picker
<leader>fd      diagnostics
<leader>fs      document symbols
<leader>fS      workspace symbols
<leader>/       fuzzy find in current buffer
<C-/>           which_key inside any picker (insert mode)
```

### File explorer (Oil)

```text
-               open parent directory
<leader>e       open Oil for current cwd
q   (in Oil)    close
g?  (in Oil)    show all Oil keymaps
```

Oil treats a directory as a buffer. Edit it like text and `:w` to apply
file/folder changes.

### LSP (set per-buffer when an LSP attaches)

```text
gd              go to definition
gD              go to declaration
gi              go to implementation
gr              references
gt              type definition
K               hover docs
<C-k>           signature help (insert mode)
<leader>rn      rename
<leader>ca      code action
```

### Diagnostics

```text
[d              previous diagnostic
]d              next diagnostic
<leader>de      line diagnostics (float)
<leader>dq      diagnostics → loclist
```

### Formatting

```text
<leader>fm      format buffer (manual)
:w              format-on-save runs automatically
```

### Editing

```text
<leader>w       :w
<leader>q       :q
<Esc>           clear search highlight
<C-d>/<C-u>     half-page jump (centered)
n / N           next / prev match (centered)
< / > (visual)  indent and keep selection
J / K (visual)  move selected lines down / up
<leader>y       yank to system clipboard explicitly
<leader>Y       yank line to system clipboard
```

### tmux navigation

`Ctrl-h`, `Ctrl-j`, `Ctrl-k`, `Ctrl-l` move between nvim splits.
At the edge of nvim's windows they fall through to the next **tmux**
pane in that direction.

The reverse direction (from a non-nvim tmux pane *into* nvim) needs a
matching snippet in `~/.tmux.conf`. devflow's tmux config is left
untouched here — add this if you want full bidirectional flow:

```tmux
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?|fzf)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
```

## Updating plugins

```text
:Lazy            open the lazy UI (status, install, update, log)
:Lazy update     update everything
:Lazy sync       update + install + clean
:Mason           manage LSP/formatter binaries
:MasonUpdate     update all installed binaries
:TSUpdate        update treesitter parsers
:checkhealth     overall sanity check (run after a fresh install)
```

Headless equivalent for scripts:

```sh
nvim --headless "+Lazy! sync"  +qa
nvim --headless "+MasonUpdate" +qa
nvim --headless "+TSUpdate"    +qa
```

## SSH / remote notes

- `vim.opt.clipboard = 'unnamedplus'` is set via `vim.schedule(...)` so
  a missing clipboard provider doesn't slow startup.
- On Ghostty (locally) → SSH → tmux → nvim, yanks reach the local
  clipboard via OSC52 if your nvim is recent enough (≥0.10) and the
  terminal supports it. If they don't, use `<leader>y` to be explicit
  or paste with `prefix ]` in tmux.
- `TERM=xterm-ghostty` is handled by devflow's zshrc fallback, so nvim
  starts in a known-good `xterm-256color` on remotes that lack the
  ghostty terminfo entry.
- First Mason install on a server is slow (downloads each LSP binary).
  Use `:Mason` to inspect progress, `:checkhealth mason` if anything
  looks stuck.

## Troubleshooting

### `module 'nvim-treesitter.configs' not found`

You ended up with an old checkout of nvim-treesitter's `main` branch
(the new architecture, no `configs` module). devflow pins the plugin to
`master`, but a previously cached checkout can be sticky. Reset it:

```sh
rm -rf ~/.local/share/nvim/lazy/nvim-treesitter
nvim --headless "+Lazy! sync" +qa
```

The config also wraps `require('nvim-treesitter.configs')` in `pcall`,
so even if this happens again the rest of nvim still starts and you'll
see a notification telling you what to run.

### Generic "lazy state looks weird"

```sh
rm -rf ~/.local/share/nvim/lazy ~/.local/share/nvim/lazy-rocks
nvim --headless "+Lazy! sync" +qa
```

Mason data is separate (`~/.local/share/nvim/mason/`), so this won't
re-download LSP binaries.

### LSP server reported as "not executable"

Mason hasn't finished installing it. Check `:Mason` for status. On a
fresh box, give it a minute on first launch.

## Editing the config

Everything lives in this repo — `~/.config/nvim` is a symlink. Edit:

```sh
nvim ~/.devflow/configs/nvim/lua/devflow/plugins.lua
```

Then `:Lazy reload` or restart nvim. Push your changes to keep remote
servers in sync via `devflow update`.
