#!/usr/bin/env bash
# Dump the version-manager state of the current shell so PATH conflicts
# are easy to triage. Inherits PATH and env from whatever shell launched it.

set -uo pipefail

hr()  { printf -- '----------------------------------------------------------\n'; }
row() { printf "%-22s %s\n" "$1" "$2"; }

hr; echo "shell"; hr
row "SHELL"        "${SHELL:-(unset)}"
row "ZSH_VERSION"  "${ZSH_VERSION:-(not in zsh)}"
row "BASH_VERSION" "${BASH_VERSION:-(not in bash)}"
row "user"         "$(whoami)@$(hostname -s 2>/dev/null || hostname)"
row "TERM"         "${TERM:-(unset)}"
if [[ -n "${TERM:-}" ]] && infocmp "$TERM" >/dev/null 2>&1; then
  row "terminfo"   "ok"
else
  row "terminfo"   "missing — tmux/less/vim may fail with 'unsuitable terminal'"
fi

hr; echo "PATH (one entry per line, in order)"; hr
printf '%s\n' "${PATH:-}" | tr ':' '\n' | nl -ba

hr; echo "mise"; hr
if command -v mise >/dev/null 2>&1; then
  row "which mise" "$(command -v mise)"
  row "version"    "$(mise --version 2>&1 | head -1)"
  echo
  echo "mise current:"
  mise current 2>&1 | sed 's/^/  /'
  echo
  echo "mise doctor (summary):"
  # First ~25 lines of doctor cover activation status and shim path; the rest
  # is plugin detail not needed for triage.
  mise doctor 2>&1 | sed 's/^/  /' | head -40
else
  row "which mise" "(not installed)"
fi

# Different tools want different version flags. `go --version` errors out
# with "flag provided but not defined: --version"; it wants `go version`.
tool_version() {
  case "$1" in
    node)            "$1" -v        2>&1 | head -1 ;;
    go)              "$1" version   2>&1 | head -1 ;;
    python|python3|rustc|cargo|pnpm|npm)
                     "$1" --version 2>&1 | head -1 ;;
    *)               "$1" --version 2>&1 | head -1 ;;
  esac
}

hr; echo "language tools"; hr
for tool in node python python3 go rustc cargo pnpm npm; do
  if command -v "$tool" >/dev/null 2>&1; then
    p="$(command -v "$tool")"
    v="$(tool_version "$tool")"
    row "$tool"        "$p"
    row "  version"    "$v"
    case "$p" in
      *"/.nvm/"*)   row "  ! warning"  "resolved via nvm — mise should win when activated" ;;
      *"/.pyenv/"*) row "  ! warning"  "resolved via pyenv — mise should win when activated" ;;
      *"/mise/"*)   row "  ok"         "resolved via mise" ;;
    esac
  else
    row "$tool" "(not found)"
  fi
done

hr; echo "legacy version managers"; hr
row "NVM_DIR"     "${NVM_DIR:-(unset)}"
row "PYENV_ROOT"  "${PYENV_ROOT:-(unset)}"
row "PNPM_HOME"   "${PNPM_HOME:-(unset)}"
[[ -d "${NVM_DIR:-/nope}"    ]] && row "nvm dir present"   "yes"
[[ -d "${PYENV_ROOT:-/nope}" ]] && row "pyenv dir present" "yes"

hr
echo "If you see warnings above, your shell hasn't fully loaded the devflow"
echo "zshrc with mise activated. Try:"
echo
echo "  exec zsh -l"
echo "  mise doctor"
hr
