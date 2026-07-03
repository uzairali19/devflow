# 08 — Neovim

## Concept

Vim is a language: **operator + motion**. `d` (delete), `c` (change),
`y` (yank) combine with `w` (word), `ap` (a paragraph), `i"` (inside
quotes), `t,` (till comma). You don't memorize `ci"` — you *say* "change
inside quotes". Learn ten motions and every operator multiplies them.

devflow's config (leader = Space) adds a thin, deliberate layer:

```text
<leader>ff / fg     find file / live grep          (Telescope)
<leader>/           fuzzy search in this buffer
-                   edit the filesystem like a buffer (Oil); g. toggles dotfiles
gd / gr / K         definition / references / docs  (LSP)
<leader>rn / ca     rename symbol / code action
[d ]d               previous / next diagnostic
<leader>fm          format buffer                   (conform)
Ctrl-h/j/k/l        move across nvim splits AND tmux panes
```

## Real-world example

Rename a function used in 30 places:

```text
gd          # jump to the definition
<leader>rn  # LSP rename — every call site, every file, one edit
<leader>fg  # grep the old name to confirm nothing textual remains
```

Thirty manual edits become three keystrokes and a verification.

## Exercises

1. Spend one session using only `ci"`, `ciw`, `dap`, `yi(` for edits —
   no visual mode, no arrow keys.
2. Navigate a whole coding session with only `<leader>ff` and `gd` —
   never `:e path/to/file`.
3. Use Oil (`-`) to rename two files and create a directory, saving with
   `:w` like a normal buffer.
4. `:Tutor` — yes, really. 30 minutes, once. It fixes foundations.

## Common mistakes

- Staying in insert mode and arrow-keying around — normal mode *is* the editor.
- `x x x x` instead of `daw`: if you press a key more than twice, there's
  a motion that does it once.
- Installing a plugin per problem. The devflow set (telescope, oil, LSP,
  treesitter, cmp, conform) covers 95% — learn it deeper instead.
- Ignoring LSP diagnostics until CI fails: `]d` is right there.

## Further reading

- `:help motion.txt` — the actual vocabulary list
- devflow: `docs/neovim.md` for the full keymap and plugin rationale
