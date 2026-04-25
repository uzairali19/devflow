#!/usr/bin/env bash
# Install mise (language/tool version manager). Optional.

set -euo pipefail

DEVFLOW_ROOT="${DEVFLOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=detect-os.sh
source "$DEVFLOW_ROOT/scripts/detect-os.sh"

say()  { printf "   %s\n" "$*"; }
warn() { printf "   ! %s\n" "$*" >&2; }

if command -v mise >/dev/null 2>&1; then
  say "mise already installed: $(command -v mise) ($(mise --version 2>/dev/null | head -1))"
  exit 0
fi

case "$OS" in
  macos)
    if command -v brew >/dev/null 2>&1; then
      say "brew install mise"
      brew install mise
    else
      say "Homebrew not found, using official installer"
      curl -fsSL https://mise.run | sh
    fi
    ;;
  linux)
    say "installing mise via official installer (curl https://mise.run | sh)"
    curl -fsSL https://mise.run | sh
    ;;
  *)
    warn "OS=$OS not supported by this installer"
    exit 1
    ;;
esac

# The official installer drops mise at ~/.local/bin/mise.
if ! command -v mise >/dev/null 2>&1; then
  if [[ -x "$HOME/.local/bin/mise" ]]; then
    say "mise installed at $HOME/.local/bin/mise"
    say "ensure ~/.local/bin is on PATH (devflow's zshrc handles this)"
  else
    warn "mise install seemed to succeed but the binary isn't on PATH yet"
    warn "open a new shell or check your installer output"
  fi
fi
