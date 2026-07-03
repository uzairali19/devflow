# 02 — Searching

## Concept

Two different questions, two tools:

- **Where is the file?** → `fd` (find by name)
- **Where is the text?** → `rg` (ripgrep, find by content)

Both respect `.gitignore` by default, which is why they feel fast and
relevant. Everything else (fzf, Telescope in nvim) is a UI on top of them.

```sh
fd config                 # files/dirs named *config*
fd -e md -e txt           # by extension
fd --hidden --no-ignore   # include dotfiles and ignored files

rg 'connectTimeout'              # text, recursively, gitignore-aware
rg -i 'error' -g '*.log'         # case-insensitive, only *.log
rg -l 'TODO'                     # just filenames
rg -C3 'panic'                   # 3 lines of context
rg --hidden 'API_KEY'            # include dotfiles (.env leaks!)
rg -F 'a.b[0]'                   # fixed string — no regex surprises
```

## Real-world example

Production is throwing `ECONNREFUSED`. Where do we even set that host?

```sh
rg -i 'ECONNREFUSED|connect' -g '!node_modules' -C2
rg 'DATABASE_URL' --hidden        # catches .env and .env.example
fd -e yml | xargs rg -l 'db'      # compose files mentioning the db
```

Three commands, and you know every place the connection is configured.

## Exercises

1. In any repo: count TODO/FIXME markers (`rg -c 'TODO|FIXME'`).
2. Find every markdown file modified this week: `fd -e md --changed-within 7d`.
3. Search a string that only exists in a dotfile — confirm you need `--hidden`.
4. In nvim: `<leader>fg` (live grep) then `<leader>/` (fuzzy in buffer) —
   same engine, different scope.

## Common mistakes

- `grep -r` on a repo with `node_modules` — that's what `.gitignore`-aware
  tools are for.
- Forgetting `--hidden` and concluding "it's not configured anywhere".
- Regex when you meant a literal: `rg -F` for strings like `foo(bar)`.

## Further reading

- `rg --help` — the `-g` glob section repays reading once
- devflow: telescope config in `configs/nvim/lua/devflow/plugins.lua`
