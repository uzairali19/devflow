#!/usr/bin/env bash
# chsh to zsh if not already.

set -euo pipefail

say()  { printf "   %s\n" "$*"; }
warn() { printf "   ! %s\n" "$*" >&2; }

ZSH_BIN="$(command -v zsh || true)"
if [[ -z "$ZSH_BIN" ]]; then
  warn "zsh not installed, skipping"
  exit 0
fi

if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
  say "already zsh ($SHELL)"
  exit 0
fi

if [[ -r /etc/shells ]] && ! grep -qx "$ZSH_BIN" /etc/shells; then
  say "registering $ZSH_BIN in /etc/shells"
  if [[ "$EUID" -eq 0 ]]; then
    printf "%s\n" "$ZSH_BIN" >> /etc/shells
  else
    printf "%s\n" "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null || warn "couldn't write /etc/shells"
  fi
fi

say "chsh -s $ZSH_BIN"
if chsh -s "$ZSH_BIN" 2>/dev/null; then
  say "done. restart your terminal."
else
  warn "chsh failed; run manually: chsh -s $ZSH_BIN"
fi
