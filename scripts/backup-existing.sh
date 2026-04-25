#!/usr/bin/env bash
# Move pre-existing dotfiles to <path>.backup.devflow.<UTC ts>.
# Existing devflow symlinks are left alone.

set -euo pipefail

DEVFLOW_ROOT="${DEVFLOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.tmux.conf"
  "$HOME/.config/nvim"
  "$HOME/.config/ghostty"
  "$HOME/.config/starship.toml"
  "$HOME/.config/mise/config.toml"
)

for path in "${TARGETS[@]}"; do
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf "   %s absent\n" "$path"
    continue
  fi
  if [[ -L "$path" ]] && [[ "$(readlink "$path")" == "$DEVFLOW_ROOT"* ]]; then
    printf "   %s already linked\n" "$path"
    continue
  fi
  backup="${path}.backup.devflow.${TS}"
  mv "$path" "$backup"
  printf "   %s -> %s\n" "$path" "$backup"
done
