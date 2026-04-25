# Languages and runtimes

devflow uses [mise](https://mise.jdx.dev/) for language and tool
version management. One tool replaces nvm, pyenv, rbenv, asdf, and
similar.

## Why mise

- one tool for many languages (node, python, go, rust, ...)
- faster shim model than nvm
- reads `.mise.toml`, `.nvmrc`, `.python-version`, `.tool-versions`
- per-project tool versions without per-language config
- doesn't slow down shell startup the way `nvm` does

## Install

mise is optional. Install it with the bootstrap:

```sh
./install.sh --languages              # mise only (no shell change, no full link)
./install.sh --local --languages      # full local + mise
./install.sh --remote --languages     # full remote + mise
```

After install, restart your shell so mise activates:

```sh
exec zsh -l
mise current
```

## Global defaults

The starting global config (`configs/mise/config.toml`) is symlinked to
`~/.config/mise/config.toml`:

```toml
[tools]
node = "lts"
python = "3.12"
go = "latest"
rust = "stable"

[settings]
experimental = true
```

Install everything declared there:

```sh
mise install
```

Change a global default at any time:

```sh
mise use -g node@lts
mise use -g python@3.12
mise use -g go@latest
mise use -g rust@stable
```

## Project overrides

Inside a project, set a tool version local to that directory:

```sh
mise use node@20        # writes/updates .mise.toml in the cwd
mise install            # install whatever .mise.toml asks for
mise current            # show what's active right here
```

`mise use` creates or edits `.mise.toml` in the current directory.
Commit it so your team picks up the same versions.

mise also reads legacy files for free: drop a `.nvmrc` in a node project
and it just works.

## What devflow does NOT install

By design, devflow stays out of services and databases:

- no MongoDB
- no PostgreSQL
- no Redis
- no message queues
- no application servers

Those belong to a project, not the dotfiles. Pick the right tool per
project — usually a `docker compose` file in the repo, or the project's
own setup script.

### Docker

Docker is optional and not installed by devflow. Install it separately:

- macOS: Docker Desktop or `brew install --cask docker`, OrbStack, colima
- Linux: distro package (`apt install docker.io`) or the official convenience script

### MongoDB / AVX warning

If you do install MongoDB on a VPS, be aware that recent MongoDB builds
require AVX CPU instructions. Older or low-tier VPS instances often
lack AVX, and `mongod` will silently exit on start. Check before
installing:

```sh
grep -m1 -o avx /proc/cpuinfo || echo "no AVX"
```

If you see "no AVX", use an older MongoDB build (4.4 is the last
non-AVX release) or a different instance type.

## Troubleshooting

### `mise current` shows the right versions but `node -v` shows an old one

This means mise is installed but your current shell hasn't activated it.
Old PATH entries from nvm or pyenv are still resolving first.

```sh
mise doctor              # check 'activated' and 'shims_on_path' lines
exec zsh -l              # reload the shell
mise doctor              # should now say activated: yes
```

If `exec zsh -l` doesn't fix it, the devflow `zshrc` may not be linked
to `~/.zshrc`. Confirm:

```sh
readlink ~/.zshrc        # should point to <devflow>/configs/zsh/zshrc
```

If that's wrong, re-run the installer:

```sh
./install.sh --local --languages
```

### Full diagnostic

```sh
devflow debug
```

Prints the active shell, full PATH (one entry per line, in order),
mise's `current` and `doctor` output, and resolved paths for `node`,
`python`, `go`, and `rustc`. Also flags when a tool resolves through
nvm or pyenv instead of mise.

### Healthcheck

```sh
devflow doctor
```

Fails (exit 1) if mise is installed but not activated, or if `node` /
`python` resolves through `~/.nvm` / `~/.pyenv` while mise is present.

### `~/.zshrc.local` putting nvm/pyenv back on PATH

`~/.zshrc.local` is sourced last so it can override anything. If it
re-exports `~/.nvm/...` or `~/.pyenv/shims` to PATH, those will win
over mise. Move version-manager PATH manipulation out of
`~/.zshrc.local`.

## Migrating from nvm/pyenv

You don't have to migrate. devflow's `zshrc` keeps nvm and pyenv
fallback blocks, but they only run when mise is **not** installed. If
you install mise, mise wins and the legacy blocks become inert
automatically.

Your existing `.nvmrc` and `.python-version` files continue to work
because mise reads them.
