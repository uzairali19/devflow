#!/usr/bin/env bash
# Install packages. brew on macOS, apt on Debian/Ubuntu.

set -euo pipefail

DEVFLOW_ROOT="${DEVFLOW_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=detect-os.sh
source "$DEVFLOW_ROOT/scripts/detect-os.sh"

say()  { printf "   %s\n" "$*"; }
warn() { printf "   ! %s\n" "$*" >&2; }

# Required for OSC52 clipboard passthrough (nvim -> tmux -> ssh -> terminal).
# tmux 3.2 added the `set-clipboard on` semantics we rely on.
TMUX_MIN_MAJOR=3
TMUX_MIN_MINOR=2

# Bumped manually when we want to roll forward.
TMUX_SOURCE_VERSION="3.5a"

# Neovim minimum: 0.11 for vim.lsp.config; the keymaps module also needs
# vim.keymap (0.7+). apt on Ubuntu 22.04/24.04 and Debian 12 ships much
# older versions, so we install the official tarball from GitHub releases.
NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=11

nvim_version_ok() {
  command -v nvim >/dev/null 2>&1 || return 1
  local raw cleaned major minor
  # nvim --version prints "NVIM v0.11.0" on the first line.
  raw="$(nvim --version 2>/dev/null | head -1 | awk '{print $2}')"
  cleaned="${raw#v}"
  major="${cleaned%%.*}"
  minor="${cleaned#*.}"
  minor="${minor%%.*}"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
  if (( major > NVIM_MIN_MAJOR )); then return 0; fi
  if (( major == NVIM_MIN_MAJOR && minor >= NVIM_MIN_MINOR )); then return 0; fi
  return 1
}

# Install the official Neovim release tarball into ~/.local/nvim/ and
# link the binary into ~/.local/bin/nvim. Only called when apt's nvim
# is too old. The system /usr/bin/nvim (if any) stays in place but is
# shadowed by the front-of-PATH ~/.local/bin entry.
install_nvim_official() {
  local asset
  case "$(uname -m)" in
    x86_64|amd64)  asset="nvim-linux-x86_64.tar.gz" ;;
    aarch64|arm64) asset="nvim-linux-arm64.tar.gz"  ;;
    *)
      warn "no official Neovim binary for arch $(uname -m); apt version will be used"
      return 0
      ;;
  esac

  local url="https://github.com/neovim/neovim/releases/latest/download/$asset"
  local target="$HOME/.local/nvim"
  mkdir -p "$HOME/.local/bin"

  say "downloading official Neovim ($asset)"
  rm -rf "$target"
  mkdir -p "$target"
  curl -fsSL "$url" | tar xz -C "$target" --strip-components=1
  ln -sfn "$target/bin/nvim" "$HOME/.local/bin/nvim"
  export PATH="$HOME/.local/bin:$PATH"
  hash -r 2>/dev/null || true
  say "Neovim $(nvim --version | head -1 | awk '{print $2}') installed at ~/.local/nvim/"
}

tmux_version_ok() {
  command -v tmux >/dev/null 2>&1 || return 1
  local raw cleaned major minor
  raw="$(tmux -V 2>/dev/null | awk '{print $2}')"
  # "3.5a" -> "3.5", "3.2-rc1" -> "3.2"
  cleaned="$(printf '%s' "$raw" | sed 's/[^0-9.].*$//')"
  major="${cleaned%%.*}"
  minor="${cleaned#*.}"
  minor="${minor%%.*}"
  [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]] || return 1
  if (( major > TMUX_MIN_MAJOR )); then return 0; fi
  if (( major == TMUX_MIN_MAJOR && minor >= TMUX_MIN_MINOR )); then return 0; fi
  return 1
}

# Build a recent tmux into ~/.local/bin. Only called when the apt-installed
# tmux is too old for OSC52. Build cost: ~30s on a 1-vCPU VPS.
build_tmux_from_source() {
  local SUDO="${1:-}"
  say "building tmux ${TMUX_SOURCE_VERSION} from source (apt tmux too old for OSC52)"
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libevent-dev libncurses-dev pkg-config bison make gcc

  local workdir
  workdir="$(mktemp -d)"
  trap "rm -rf '$workdir'" RETURN

  ( cd "$workdir" \
    && curl -fsSL "https://github.com/tmux/tmux/releases/download/${TMUX_SOURCE_VERSION}/tmux-${TMUX_SOURCE_VERSION}.tar.gz" \
       | tar xz \
    && cd "tmux-${TMUX_SOURCE_VERSION}" \
    && ./configure --prefix="$HOME/.local" >/dev/null \
    && make -j"$(nproc)" >/dev/null \
    && make install >/dev/null
  )
  # Make the new tmux discoverable for the rest of this script run.
  export PATH="$HOME/.local/bin:$PATH"
  hash -r 2>/dev/null || true
  say "tmux $(tmux -V 2>/dev/null | awk '{print $2}') installed at ~/.local/bin/tmux"
}

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

  # brew always ships a recent tmux; sanity check anyway so the contract is
  # explicit (OSC52 needs ≥ 3.2).
  if tmux_version_ok; then
    say "tmux $(tmux -V | awk '{print $2}') ≥ ${TMUX_MIN_MAJOR}.${TMUX_MIN_MINOR} — OK for OSC52"
  else
    warn "brew tmux reports an unexpectedly old version; OSC52 may not work"
  fi

  if nvim_version_ok; then
    say "nvim $(nvim --version | head -1 | awk '{print $2}') ≥ ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} — OK"
  else
    warn "brew nvim reports an unexpectedly old version; devflow needs ≥ 0.11"
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

  # tmux ≥ 3.2 is mandatory for the OSC52 clipboard chain. apt's version is
  # fine on Ubuntu 22.04+ and Debian 11+; older releases need a source build.
  if tmux_version_ok; then
    say "tmux $(tmux -V | awk '{print $2}') ≥ ${TMUX_MIN_MAJOR}.${TMUX_MIN_MINOR} — OK for OSC52"
  else
    build_tmux_from_source "$SUDO"
  fi

  # Neovim ≥ 0.11 is mandatory for our LSP/clipboard config. apt's version
  # is too old on every current Debian/Ubuntu release; install the official
  # release tarball into ~/.local/nvim if needed.
  if nvim_version_ok; then
    say "nvim $(nvim --version | head -1 | awk '{print $2}') ≥ ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} — OK"
  else
    install_nvim_official
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
