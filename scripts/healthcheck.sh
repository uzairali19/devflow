#!/usr/bin/env bash
# Verify the toolchain. Exit 1 if any required tool is missing OR if
# mise is installed but not properly activated in the current shell.

set -uo pipefail

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_GREEN=$'\033[32m'; C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_GREEN=""; C_RED=""; C_YELLOW=""; C_DIM=""; C_BOLD=""
fi

REQUIRED=(zsh starship tmux nvim fzf rg fd bat)
OPTIONAL=(eza jq tree git curl mise)

# Debian renames. Plain case so this runs on macOS bash 3.2.
alt_for() {
  case "$1" in
    fd)  printf "fdfind" ;;
    bat) printf "batcat" ;;
    *)   printf "" ;;
  esac
}

resolve() {
  local name="$1" alt
  if command -v "$name" >/dev/null 2>&1; then command -v "$name"; return 0; fi
  alt="$(alt_for "$name")"
  if [[ -n "$alt" ]] && command -v "$alt" >/dev/null 2>&1; then command -v "$alt"; return 0; fi
  return 1
}

row()  { printf "   %-10s %s%s\n" "$1:" "$2" "${3:+ ${C_DIM}${3}${C_RESET}}"; }
warn() { printf "   %s ! %s %s\n" "${C_YELLOW}" "${C_RESET}" "$*"; }

failures=0

for tool in "${REQUIRED[@]}"; do
  if path="$(resolve "$tool")"; then
    row "$tool" "${C_GREEN}ok${C_RESET}" "$path"
  else
    row "$tool" "${C_RED}missing${C_RESET}"
    failures=$((failures + 1))
  fi
done

for tool in "${OPTIONAL[@]}"; do
  if path="$(resolve "$tool")"; then
    row "$tool" "${C_GREEN}ok${C_RESET}" "$path"
  else
    row "$tool" "${C_DIM}optional, missing${C_RESET}"
  fi
done

# ---------- mise integration check -----------------------------------------
# Only meaningful if mise is installed. mise has two valid load modes:
#   * `mise activate zsh` (rewrites PATH on every prompt; activated: yes)
#   * shims on PATH (no precmd hook; shims_on_path: yes)
# Either is fine. We only fail if NEITHER is true, or if a configured tool
# fails to resolve through mise.

mise_problems=0
if command -v mise >/dev/null 2>&1; then
  printf "\n   %smise%s\n" "${C_BOLD}" "${C_RESET}"

  doctor_out="$(mise doctor 2>&1 || true)"

  activated="unknown"
  shims_on_path="unknown"
  if printf "%s" "$doctor_out" | grep -qiE 'activated[[:space:]]*:[[:space:]]*yes'; then activated="yes"
  elif printf "%s" "$doctor_out" | grep -qiE 'activated[[:space:]]*:[[:space:]]*no';  then activated="no"
  fi
  if printf "%s" "$doctor_out" | grep -qiE 'shims_on_path[[:space:]]*:[[:space:]]*yes'; then shims_on_path="yes"
  elif printf "%s" "$doctor_out" | grep -qiE 'shims_on_path[[:space:]]*:[[:space:]]*no';  then shims_on_path="no"
  fi

  if [[ "$activated" == "yes" ]]; then
    row "mise" "${C_GREEN}activated${C_RESET}" "mise activate zsh"
  elif [[ "$shims_on_path" == "yes" ]]; then
    row "mise" "${C_GREEN}shims on path${C_RESET}"
  else
    warn "mise is installed but neither activated nor on shims PATH"
    warn "  add 'eval \"\$(mise activate zsh)\"' to your zshrc, or reload: ${C_BOLD}exec zsh -l${C_RESET}"
    mise_problems=$((mise_problems + 1))
  fi

  # Verify configured tools resolve through mise (not nvm/pyenv/system).
  # mise-managed paths always contain /mise/installs/ or /mise/shims/.
  for tool in node python go rustc; do
    # Skip tools mise doesn't have configured.
    mise current "$tool" >/dev/null 2>&1 || continue

    if ! command -v "$tool" >/dev/null 2>&1; then
      warn "$tool is configured in mise but not on PATH"
      mise_problems=$((mise_problems + 1))
      continue
    fi

    p="$(command -v "$tool")"
    case "$p" in
      *"/mise/installs/"*|*"/mise/shims/"*)
        row "$tool" "${C_GREEN}mise${C_RESET}" "$p"
        ;;
      *"/.nvm/"*)
        warn "$tool resolves via nvm: $p"
        mise_problems=$((mise_problems + 1))
        ;;
      *"/.pyenv/"*)
        warn "$tool resolves via pyenv: $p"
        mise_problems=$((mise_problems + 1))
        ;;
      *)
        warn "$tool does not resolve via mise: $p"
        mise_problems=$((mise_problems + 1))
        ;;
    esac
  done
fi

# ---------- exit -----------------------------------------------------------

if (( failures > 0 )); then
  printf "\n   %s%d required missing%s\n" "${C_RED}" "$failures" "${C_RESET}"
  exit 1
fi

if (( mise_problems > 0 )); then
  printf "\n   %s%d mise problem(s)%s — see warnings above\n" "${C_YELLOW}" "$mise_problems" "${C_RESET}"
  exit 1
fi
