#!/usr/bin/env bash
# devflow installer.
#   ./install.sh --local | --remote          full install
#   ./install.sh --languages                 install mise only (no link/shell)
#   ./install.sh --local --languages         full + mise
#   ./install.sh --remote --languages        full + mise

set -euo pipefail

DEVFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEVFLOW_ROOT

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
  C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_DIM=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

log()  { printf "%s==>%s %s\n" "${C_BLUE}${C_BOLD}" "${C_RESET}" "$*"; }
ok()   { printf "%s ok %s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn() { printf "%s !  %s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }
die()  { printf "%s x  %s %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; exit 1; }

MODE=""
SKIP_PACKAGES=0
SKIP_SHELL=0
INSTALL_LANGUAGES=0

usage() {
  cat <<USAGE
usage:
  ./install.sh --local              macOS install
  ./install.sh --remote             Linux server install (no GUI)
  ./install.sh --languages          install mise only (combine with --local/--remote for full bootstrap + mise)
  --skip-packages                   don't install packages
  --skip-shell                      don't change the login shell
  -h, --help                        show this
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local)         MODE="local";          shift ;;
    --remote)        MODE="remote";         shift ;;
    --languages)     INSTALL_LANGUAGES=1;   shift ;;
    --skip-packages) SKIP_PACKAGES=1;       shift ;;
    --skip-shell)    SKIP_SHELL=1;          shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage; die "unknown argument: $1" ;;
  esac
done

# Locate the mise binary even when ~/.local/bin isn't on the script's PATH yet.
# install-mise.sh writes to ~/.local/bin/mise (curl) or /opt/homebrew/bin/mise (brew).
find_mise() {
  if   command -v mise >/dev/null 2>&1; then command -v mise
  elif [[ -x "$HOME/.local/bin/mise" ]]; then printf "%s" "$HOME/.local/bin/mise"
  elif [[ -x /opt/homebrew/bin/mise   ]]; then printf "%s" /opt/homebrew/bin/mise
  elif [[ -x /usr/local/bin/mise      ]]; then printf "%s" /usr/local/bin/mise
  fi
}

run_mise_install() {
  local mise_bin
  mise_bin="$(find_mise)"
  if [[ -z "$mise_bin" ]]; then
    warn "mise not found on PATH after install; skipping 'mise install'"
    warn "  run manually after exec zsh -l"
    return 0
  fi
  log "mise install (downloading declared language versions, may take a while)"
  if "$mise_bin" install; then
    ok "mise install complete"
    "$mise_bin" current 2>/dev/null | sed 's/^/   /' || true
  else
    warn "mise install reported errors; re-run after 'exec zsh -l'"
  fi
}

# --languages alone: only install mise, no full bootstrap.
if [[ -z "$MODE" && "$INSTALL_LANGUAGES" -eq 1 ]]; then
  log "detect-os"
  # shellcheck source=scripts/detect-os.sh
  source "$DEVFLOW_ROOT/scripts/detect-os.sh"
  ok "OS=$OS${DISTRO:+ DISTRO=$DISTRO}"

  log "install mise"
  bash "$DEVFLOW_ROOT/scripts/install-mise.sh"

  log "link mise global config"
  mkdir -p "$HOME/.config/mise"
  ln -sfn "$DEVFLOW_ROOT/configs/mise/config.toml" "$HOME/.config/mise/config.toml"
  ok "$HOME/.config/mise/config.toml"

  run_mise_install

  cat <<NEXT

Install complete.

Your current shell is still using the old environment.

Run: exec zsh -l

Then:
  mise doctor             confirm 'activated: yes'
  mise current            show active versions

NEXT
  exit 0
fi

[[ -n "$MODE" ]] || { usage; die "--local, --remote, or --languages is required"; }
export DEVFLOW_MODE="$MODE"

printf "%sdevflow%s mode=%s languages=%s root=%s\n" \
  "${C_BOLD}" "${C_RESET}" "$MODE" "$INSTALL_LANGUAGES" "$DEVFLOW_ROOT"

log "detect-os"
# shellcheck source=scripts/detect-os.sh
source "$DEVFLOW_ROOT/scripts/detect-os.sh"
ok "OS=$OS${DISTRO:+ DISTRO=$DISTRO}"

if [[ "$MODE" == "local" && "$OS" != "macos" ]]; then
  die "--local is for macOS. Use --remote on Linux."
fi

if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
  warn "skipping packages"
else
  log "install packages"
  bash "$DEVFLOW_ROOT/scripts/install-packages.sh"
fi

log "backup existing dotfiles"
bash "$DEVFLOW_ROOT/scripts/backup-existing.sh"

log "link configs"
bash "$DEVFLOW_ROOT/scripts/link-configs.sh"

if [[ "$INSTALL_LANGUAGES" -eq 1 ]]; then
  log "install mise"
  bash "$DEVFLOW_ROOT/scripts/install-mise.sh"
  run_mise_install
fi

if [[ "$SKIP_SHELL" -eq 1 ]]; then
  warn "skipping shell change"
else
  log "set shell"
  bash "$DEVFLOW_ROOT/scripts/set-shell.sh"
fi

log "link devflow command"
mkdir -p "$HOME/.local/bin"
ln -sfn "$DEVFLOW_ROOT/bin/devflow" "$HOME/.local/bin/devflow"
ok "$HOME/.local/bin/devflow"

log "healthcheck (pre-reload)"
DEVFLOW_PREINSTALL=1 bash "$DEVFLOW_ROOT/scripts/healthcheck.sh" || \
  warn "some tools missing (see above)"

# Seed ~/.zshrc.local from the example if the user doesn't have one.
# Never overwrite — this file holds secrets.
if [[ ! -e "$HOME/.zshrc.local" ]]; then
  cp "$DEVFLOW_ROOT/configs/zsh/zshrc.local.example" "$HOME/.zshrc.local"
  ok "seeded $HOME/.zshrc.local from the example (edit it for secrets/host env)"
fi

cat <<NEXT

Install complete.

Your current shell is still using the old environment.

Run: exec zsh -l

Then:
  devflow doctor          verify the install
  devflow session work    start a tmux session

Secrets and host-specific env live in ~/.zshrc.local
(sourced last; not tracked by devflow).
NEXT

if [[ "$INSTALL_LANGUAGES" -eq 1 ]]; then
  cat <<'MISE'

After exec zsh -l, mise commands:
  mise doctor             confirm 'activated: yes'
  mise current            show active versions
  mise use -g node@lts    change a global default
  mise use node@20        set a project-local override
  devflow debug           full PATH diagnostic if anything looks off

MISE
fi
