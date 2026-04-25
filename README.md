# Devflow

My dotfiles and bootstrap script. Works on macOS and Debian/Ubuntu.

## One-line install

### Remote Linux server

```sh
curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

What it does:

- installs base system packages (`build-essential`, `curl`, `git`, `ca-certificates`)
- clones or updates devflow into `~/devflow`
- runs `./install.sh --remote --languages`
- links configs and installs mise-managed runtimes

Supports Debian/Ubuntu (apt) and RHEL/Fedora (dnf/yum). Anything else,
install git/curl/build-tools manually then run `./install.sh --remote --languages`.

### Custom install directory

```sh
DEVFLOW_DIR="$HOME/.devflow" \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

### Custom branch

```sh
DEVFLOW_BRANCH=dev \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

### Custom repo

```sh
DEVFLOW_REPO_URL=git@github.com:you/devflow.git \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

Full details and troubleshooting in [`docs/bootstrap.md`](docs/bootstrap.md).

## Manual install

```sh
git clone https://github.com/uzairali19/devflow.git ~/devflow
cd ~/devflow

./install.sh --local                  # macOS
./install.sh --remote                 # Linux server
./install.sh --local --languages      # macOS + mise (node/python/go/rust)
./install.sh --remote --languages     # Linux + mise
./install.sh --languages              # add mise to an existing install
```

Flags:

```text
--languages        also install mise (language/runtime version manager)
--skip-packages    don't run the package installer
--skip-shell       don't change the login shell
-h, --help         usage
```

Existing dotfiles get renamed to `*.backup.devflow.<timestamp>` before
anything is linked. Re-running the installer is safe.

## Tools

zsh, starship, tmux, nvim, git, curl, fzf, ripgrep, fd, bat, eza, jq, tree.
Ghostty is added on macOS only.

## What gets linked

```text
~/.zshrc                  -> configs/zsh/zshrc
~/.tmux.conf              -> configs/tmux/tmux.conf
~/.config/starship.toml   -> configs/starship/starship.toml
~/.config/nvim            -> configs/nvim/
~/.config/mise/config.toml -> configs/mise/config.toml
~/.config/ghostty         -> configs/ghostty/    (macOS only)
~/.local/bin/devflow      -> bin/devflow
```

The installer also copies `configs/zsh/zshrc.local.example` to
`~/.zshrc.local` once, only if you don't already have one. That file is
never overwritten.

## Secrets and host-specific env

Anything that shouldn't be in git lives in `~/.zshrc.local`:

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="..."
export AWS_PROFILE="staging"
alias k='kubectl'
```

It's sourced at the very end of `.zshrc`, so it can override anything
above. It is git-ignored and never tracked by devflow.

Don't put secrets in `configs/zsh/zshrc` — that file is committed.

## Ghostty

The Ghostty config in this repo is a verbatim copy of my actual
`~/.config/ghostty/config`: GitHub Dark High Contrast theme,
JetBrainsMono Nerd Font 14, bar cursor, 16px padding, 200k scrollback,
black background at 0.75 opacity with 30px blur, my Super-key
splits/nav/copy/paste bindings, and `macos-option-as-alt = true` for
tmux Alt+hjkl.

devflow does not opinionate on terminal visuals. Edit
`configs/ghostty/config` freely; re-sync from `~/.config/ghostty/config`
whenever you change something there.

## Prompt

Starship by default. No oh-my-zsh, no plugin manager. Cold zsh startup
is fast.

## Languages and runtimes

devflow uses [mise](https://mise.jdx.dev/) as the language version
manager when `--languages` is passed. One tool for node, python, go,
rust, and more. Replaces nvm/pyenv/rbenv/asdf.

```sh
mise install                # install versions from the global config
mise current                # show what's active
mise use -g node@lts        # change a global default
mise use node@20            # set a project-local override
```

The starting global config is `configs/mise/config.toml` (node lts,
python 3.12, go latest, rust stable). Full guide in
[`docs/languages.md`](docs/languages.md).

### Other tooling in zsh

Loaded only when present, no errors if missing:

- `pnpm` (`~/Library/pnpm` on macOS, `~/.local/share/pnpm` on Linux)
- `nvm` and `pyenv` — kept as legacy fallbacks; only loaded when mise
  is **not** installed
- Python `certifi` for `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE`

### Not included

devflow does not install services or databases (MongoDB, Postgres,
Redis, etc.). Those belong per-project, usually via Docker. Docker
itself is not installed by devflow either — install separately if you
need it. See [`docs/languages.md`](docs/languages.md) for a MongoDB AVX
gotcha worth knowing about.

## devflow command

```text
devflow session [name]    new or attach tmux session
devflow sessions          list sessions
devflow doctor            run healthcheck
devflow update            git pull + re-link
devflow path              print repo root
```

## tmux keys

Prefix is `Ctrl-a`. Optimized for SSH and local workflow.

```text
prefix |          split horizontal
prefix -          split vertical
prefix h/j/k/l    move between panes
prefix HJKL       resize (repeatable, hold prefix)
Alt-h/j/k/l       resize (no prefix)
prefix [          copy mode (v select, y yank, Esc cancel)
prefix S          toggle synchronize-panes
prefix r          reload tmux.conf
```

Yank pipes to `pbcopy` on macOS, `wl-copy`/`xclip` on Linux. Mouse is
on. Splits inherit the current pane's cwd.

More in `docs/tmux.md`.

## Uninstall

There is no uninstaller. Remove the symlinks, restore from the
`*.backup.devflow.*` files, run `chsh` back to your old shell.
`~/.zshrc.local` is left in place.

## Roadmap

- `devflow sync <host>` to rsync the repo and run `--remote`
- Arch and Fedora package paths
- Optional nvim LSP layer behind a flag
