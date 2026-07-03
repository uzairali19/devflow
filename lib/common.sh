# lib/common.sh — shared helpers for devflow subcommands.
# Sourced by bin/devflow (which sets -euo pipefail); never executed directly.

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=""; C_BOLD=""; C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

log()  { printf "%s==>%s %s\n" "${C_BLUE}${C_BOLD}" "${C_RESET}" "$*"; }
ok()   { printf "%s ok %s %s\n" "${C_GREEN}" "${C_RESET}" "$*"; }
warn() { printf "%s !  %s %s\n" "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
die()  { printf "%s x  %s %s\n" "${C_RED}" "${C_RESET}" "$*" >&2; exit 1; }

# Ask before doing anything a user might regret.
# Usage: confirm "delete X?" || die "aborted"
confirm() {
  local reply
  read -r -p "${1:-continue?} [y/N] " reply
  [[ "$reply" == [Yy]* ]]
}

require_tmux() {
  command -v tmux >/dev/null 2>&1 || die "tmux not installed"
}

# "Worker is invisible to app" -> worker-is-invisible-to-app
slug() {
  printf "%s" "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9_-]+/-/g; s/^-+|-+$//g' \
    | cut -c1-48
}

today()         { date +%Y-%m-%d; }
today_compact() { date +%Y%m%d; }

# User-specific devflow config (servers.toml etc). Lives OUTSIDE the repo so
# real hosts/users/secrets can never be committed.
devflow_config_dir() { printf "%s/devflow" "${XDG_CONFIG_HOME:-$HOME/.config}"; }

# Open a file in $EDITOR when running interactively; otherwise just print the
# path. Keeps the generators usable from scripts/CI and easy to test.
# Set DEVFLOW_NO_EDITOR=1 to force print-only.
edit_file() {
  local file="$1"
  if [[ -t 0 && -t 1 && -z "${DEVFLOW_NO_EDITOR:-}" ]]; then
    "${EDITOR:-vi}" "$file"
  else
    printf "%s\n" "$file"
  fi
}

# Replace {{PLACEHOLDER}} tokens in a file, in place, using pure bash so
# titles containing sed metacharacters (/ & \) can't break anything.
# Usage: replace_tokens FILE KEY VALUE [KEY VALUE ...]
replace_tokens() {
  local file="$1"; shift
  local content
  content="$(<"$file")"
  while [[ $# -ge 2 ]]; do
    content="${content//"{{$1}}"/$2}"
    shift 2
  done
  printf "%s\n" "$content" >"$file"
}
