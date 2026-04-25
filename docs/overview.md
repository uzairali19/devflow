# Overview

## Layout

```text
install.sh                  entry point
bin/devflow                 runtime CLI
scripts/
  detect-os.sh              exports OS, DISTRO, ARCH
  install-packages.sh       brew on macOS, apt on Debian/Ubuntu
  backup-existing.sh        renames pre-existing dotfiles aside
  link-configs.sh           creates symlinks into $HOME
  set-shell.sh              chsh to zsh
  healthcheck.sh            verifies the toolchain
configs/
  ghostty/config
  zsh/zshrc
  starship/starship.toml
  tmux/tmux.conf
  nvim/init.lua
```

## Install flow

```text
install.sh --local|--remote
   detect-os.sh          OS / DISTRO / ARCH
   install-packages.sh   brew or apt
   backup-existing.sh    *.backup.devflow.<ts>
   link-configs.sh       symlinks into $HOME
   set-shell.sh          chsh -s $(which zsh)
   link bin/devflow into ~/.local/bin
   healthcheck.sh
```

## Local vs remote

`--local` runs Homebrew, installs Ghostty, links the Ghostty config.
`--remote` skips all of that and uses apt.

`--local` refuses to run on Linux. `--remote` will run on macOS if you
ever want a GUI-less profile there.

## Notes

Every script can be run on its own. `install.sh` is just the orchestrator.

Errors fail loud with `set -euo pipefail`. Nothing is overwritten without
a backup first.
