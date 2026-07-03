# lib/notes.sh — journal / adr / notes generators.
# Sourced by bin/devflow. All three are create-if-missing: an existing file
# is opened, never overwritten.
#
# Journals and ADRs are project-scoped (git root). Each prefers the
# project's own template (journal/TEMPLATE.md, decisions/ADR-000-template.md
# — scaffolded by `devflow project init`) and falls back to a built-in, so
# a project can evolve its formats without touching devflow.

# Project root = enclosing git repo, else the current directory.
_project_root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }

# devflow journal today
cmd_journal() {
  case "${1:-}" in
    today)
      local root dir file tpl
      root="$(_project_root)"
      dir="$root/journal"
      mkdir -p "$dir"
      file="$dir/$(today).md"

      if [[ ! -e "$file" ]]; then
        tpl="$dir/TEMPLATE.md"
        if [[ -r "$tpl" ]]; then
          cp "$tpl" "$file"
          replace_tokens "$file" JOURNAL_DATE "$(today)" PROJECT_NAME "$(basename "$root")"
        else
          cat >"$file" <<EOF
# $(today) — $(basename "$root")

## Today

-

## What I learned

## Questions

## Ideas

## Mistakes

## Tomorrow
EOF
        fi
        ok "created $file"
      fi
      edit_file "$file"
      ;;
    *) die 'usage: devflow journal today' ;;
  esac
}

# devflow adr new "Title"
cmd_adr() {
  local sub="${1:-}"
  [[ $# -gt 0 ]] && shift || true
  case "$sub" in
    new)
      local title="${1:-}"
      [[ -n "$title" ]] || die 'usage: devflow adr new "Title of the decision"'

      local root dir file template
      root="$(_project_root)"
      dir="$root/decisions"
      mkdir -p "$dir"
      file="$dir/ADR-$(today_compact)-$(slug "$title").md"

      if [[ -e "$file" ]]; then
        warn "already exists: $file"
        edit_file "$file"
        return
      fi

      if   [[ -r "$dir/ADR-000-template.md" ]]; then template="$dir/ADR-000-template.md"
      elif [[ -r "$DEVFLOW_ROOT/templates/project/decisions/ADR-000-template.md" ]]; then
        template="$DEVFLOW_ROOT/templates/project/decisions/ADR-000-template.md"
      else
        template=""
      fi

      if [[ -n "$template" ]]; then
        cp "$template" "$file"
        replace_tokens "$file" ADR_TITLE "$title" ADR_DATE "$(today)"
      else
        cat >"$file" <<EOF
# ADR: $title

- Date: $(today)
- Status: proposed

## Problem

## Context

## Options

### Option A —

Pros:

Cons:

### Option B —

Pros:

Cons:

## Decision

## Consequences

## Future
EOF
      fi
      ok "created $file"
      edit_file "$file"
      ;;
    *) die 'usage: devflow adr new "Title"' ;;
  esac
}

# devflow notes today — global daily inbox, independent of any project.
# Lives in ~/devflow-notes (override with DEVFLOW_NOTES_DIR).
cmd_notes() {
  case "${1:-}" in
    today)
      local dir file
      dir="${DEVFLOW_NOTES_DIR:-$HOME/devflow-notes}"
      mkdir -p "$dir"
      file="$dir/$(today).md"
      if [[ ! -e "$file" ]]; then
        cat >"$file" <<EOF
# Notes — $(today)

## Inbox

-

## Ideas

## Follow-ups
EOF
        ok "created $file"
      fi
      edit_file "$file"
      ;;
    *) die 'usage: devflow notes today' ;;
  esac
}
