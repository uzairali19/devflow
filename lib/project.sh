# lib/project.sh — project scaffolding and navigation.
# Sourced by bin/devflow.
#
# Projects live in ~/projects by default; override with DEVFLOW_PROJECTS_DIR.
# `init NAME` also accepts a path (anything containing /) for one-offs.

_projects_dir() { printf "%s" "${DEVFLOW_PROJECTS_DIR:-$HOME/projects}"; }

_project_dest() {
  local name="$1"
  if [[ "$name" == */* ]]; then printf "%s" "$name"
  else printf "%s/%s" "$(_projects_dir)" "$name"
  fi
}

cmd_project() {
  local sub="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$sub" in
    init) _project_init "$@" ;;
    open) _project_open "$@" ;;
    *)    die "usage: devflow project init|open NAME" ;;
  esac
}

_project_init() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "usage: devflow project init NAME"

  local dest base src
  dest="$(_project_dest "$name")"
  base="$(basename "$dest")"
  [[ "$base" =~ ^[A-Za-z0-9._-]+$ ]] \
    || die "project name must be letters/digits/._- (got: $base)"
  [[ -e "$dest" ]] && die "refusing to touch existing path: $dest"

  src="$DEVFLOW_ROOT/templates/project"
  [[ -d "$src" ]] || die "templates missing: $src"

  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"

  # Fill placeholders in every markdown file EXCEPT the generator templates
  # (ADR-000-template.md, journal/experiment TEMPLATE.md) — those keep their
  # tokens so `devflow adr new` / `devflow journal today` can use them later.
  local f
  while IFS= read -r f; do
    replace_tokens "$f" PROJECT_NAME "$base" TODAY "$(today)"
  done < <(find "$dest" -name '*.md' ! -name 'ADR-000-template.md' ! -name 'TEMPLATE.md')

  if command -v git >/dev/null 2>&1; then
    git -C "$dest" init -q
    ok "created $dest (git initialized)"
  else
    ok "created $dest"
  fi

  cat <<EOF

  next steps:
    devflow project open $base     # tmux session in the project
    devflow adr new "First decision"
    devflow journal today
EOF
}

_project_open() {
  local name="${1:-}"
  [[ -n "$name" ]] || die "usage: devflow project open NAME"
  require_tmux

  local dest
  dest="$(_project_dest "$name")"
  [[ -d "$dest" ]] || die "no such project: $dest
  (create it with: devflow project init $name)"

  local session
  session="$(slug "$(basename "$dest")")"
  if [[ -n "${TMUX:-}" ]]; then
    tmux has-session -t "$session" 2>/dev/null \
      || tmux new-session -d -s "$session" -c "$dest"
    tmux switch-client -t "$session"
  else
    exec tmux new-session -A -s "$session" -c "$dest"
  fi
}
