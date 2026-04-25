# zsh

One file: `configs/zsh/zshrc`. No framework, no plugin manager.
Starship is the prompt by default.

## PATH

```text
~/.local/bin
~/bin
<Homebrew prefix>/bin
... rest of $PATH ...
```

`~/.local/bin` is where `devflow` is symlinked and where Debian's
`fdfind`/`batcat` shims land as `fd`/`bat`.

## Env

```text
EDITOR / VISUAL     nvim
PAGER               less
LESS                -R --mouse --wheel-lines=3
LANG / LC_ALL       en_US.UTF-8 (only if not already set)
FZF_DEFAULT_COMMAND fd ... (if fd is installed)
```

## History

50000 entries, shared across sessions, deduped, timestamped. Leading
space hides a command from history.

## Options

```text
AUTO_CD                dir cd's into it
AUTO_PUSHD             cd pushes to dirstack
INTERACTIVE_COMMENTS   # comments at the prompt
```

## Completion

Lazy `compinit`, rebuilt at most once per day. Case-insensitive matching.

## Keys

`bindkey -e` (emacs). fzf bindings are sourced if present:
`Ctrl-T` files, `Ctrl-R` history, `Alt-C` cd.

## Aliases

```text
ls            eza --group-directories-first  (or ls)
ll            eza -lah --git --group-directories-first
lt            eza --tree --level=2 --group-directories-first
cat           bat --paging=never --style=plain  (if bat exists)
.. / ...      cd .. / cd ../..
g / gs / gd   git / git status -sb / git diff
gl            git log --oneline --graph --decorate -20
gco           git checkout
gp            git pull --rebase --autostash
tn <name>     tmux new-session -A -s <name>
ta <name>     tmux attach -t <name>
tls           tmux ls
```

## Developer tooling

Each block in `zshrc` is guarded — if the tool isn't installed the
block does nothing. No errors on a fresh box.

- **mise** (preferred): if `mise` is on PATH, `eval "$(mise activate
  zsh)"` runs and mise becomes the source of truth for node, python,
  go, rust, and anything else declared in `~/.config/mise/config.toml`
  or a project `.mise.toml`. See [`languages.md`](languages.md).
- **nvm** (legacy fallback): loaded from Homebrew or `~/.nvm` **only
  when mise is absent**. Includes the `.nvmrc` auto-switch hook.
- **pyenv** (legacy fallback): `PYENV_ROOT` defaults to `~/.pyenv`.
  Loaded **only when mise is absent**.
- **pnpm**: `PNPM_HOME` defaults to `~/Library/pnpm` on macOS and
  `~/.local/share/pnpm` on Linux. Independent of mise — added to `PATH`
  only if the directory exists.
- **certifi**: if `python3 -c 'import certifi'` works, `SSL_CERT_FILE`
  and `REQUESTS_CA_BUNDLE` get set. Costs ~100ms at startup; remove the
  block (or move it to `~/.zshrc.local`) if you don't need it.

## Secrets and host overrides: `~/.zshrc.local`

`~/.zshrc.local` is sourced at the very end of `.zshrc`. It is
git-ignored and never tracked by devflow. Use it for:

- API keys and tokens (never put these in `configs/zsh/zshrc`)
- work-only env (`AWS_PROFILE`, `KUBECONFIG`)
- machine-specific PATH entries
- aliases or functions that don't belong in the shared config

```sh
# ~/.zshrc.local
export OPENAI_API_KEY="..."
export AWS_PROFILE="staging"
alias k='kubectl'
```

The installer copies `configs/zsh/zshrc.local.example` to
`~/.zshrc.local` once, only if you don't already have one. That file
is never overwritten by re-running `install.sh`.

## Prompt

Starship if installed, otherwise a small fallback. devflow does not
use oh-my-zsh.
