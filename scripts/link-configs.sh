#!/usr/bin/env bash
# Symlink configs into $HOME. Re-runnable.

set -euo pipefail

DEVFLOW_ROOT="${DEVFLOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DEVFLOW_MODE="${DEVFLOW_MODE:-local}"

mkdir -p "$HOME/.config"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
  printf "   %s -> %s\n" "$dst" "$src"
}

link "$DEVFLOW_ROOT/configs/zsh/zshrc"              "$HOME/.zshrc"
link "$DEVFLOW_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DEVFLOW_ROOT/configs/tmux/tmux.conf"         "$HOME/.tmux.conf"
link "$DEVFLOW_ROOT/configs/nvim"                   "$HOME/.config/nvim"
# mise global config — file-level link so mise can write its own state alongside.
link "$DEVFLOW_ROOT/configs/mise/config.toml"       "$HOME/.config/mise/config.toml"

if [[ "$DEVFLOW_MODE" == "local" ]]; then
  link "$DEVFLOW_ROOT/configs/ghostty"              "$HOME/.config/ghostty"
else
  printf "   skipping ghostty (remote)\n"
fi
