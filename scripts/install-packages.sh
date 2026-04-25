#!/usr/bin/env bash
# Install packages. brew on macOS, apt on Debian/Ubuntu.

set -euo pipefail

DEVFLOW_ROOT="${DEVFLOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=detect-os.sh
source "$DEVFLOW_ROOT/scripts/detect-os.sh"

say()  { printf "   %s\n" "$*"; }
warn() { printf "   ! %s\n" "$*" >&2; }

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    say "installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  local formulae=(zsh starship tmux neovim git curl fzf ripgrep fd bat eza jq tree)
  local casks=(ghostty)

  say "brew update"
  brew update >/dev/null

  local missing=()
  for f in "${formulae[@]}"; do
    brew list --formula "$f" >/dev/null 2>&1 || missing+=("$f")
  done
  if (( ${#missing[@]} > 0 )); then
    say "brew install ${missing[*]}"
    brew install "${missing[@]}"
  fi

  local missing_casks=()
  for c in "${casks[@]}"; do
    brew list --cask "$c" >/dev/null 2>&1 || missing_casks+=("$c")
  done
  if (( ${#missing_casks[@]} > 0 )); then
    say "brew install --cask ${missing_casks[*]}"
    brew install --cask "${missing_casks[@]}" || warn "cask install had errors"
  fi
}

install_linux_apt() {
  local SUDO=""
  [[ "$EUID" -ne 0 ]] && SUDO="sudo"

  say "apt-get update"
  $SUDO apt-get update -y

  local pkgs=(zsh tmux neovim git curl fzf ripgrep fd-find bat jq tree ca-certificates)
  say "apt-get install ${pkgs[*]}"
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"

  # Debian renames: fdfind -> fd, batcat -> bat
  mkdir -p "$HOME/.local/bin"
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi

  if ! command -v starship >/dev/null 2>&1; then
    say "installing starship"
    curl -fsSL https://starship.rs/install.sh | $SUDO sh -s -- -y >/dev/null
  fi

  if ! command -v eza >/dev/null 2>&1; then
    $SUDO apt-get install -y eza >/dev/null 2>&1 || warn "eza not in apt on this release, skipping"
  fi
}

case "$OS" in
  macos) install_macos ;;
  linux)
    case "$DISTRO" in
      ubuntu|debian|raspbian|pop|linuxmint) install_linux_apt ;;
      *)
        warn "distro '$DISTRO' not auto-supported. Install manually:"
        warn "  zsh tmux neovim git curl fzf ripgrep fd bat eza jq tree starship"
        ;;
    esac
    ;;
esac
