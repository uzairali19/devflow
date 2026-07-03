# 01 — Shell Navigation

## Concept

The filesystem is a tree; your shell holds one position in it (`$PWD`) plus
a history of positions. Fast navigation isn't typing paths faster — it's
never typing a full path twice. devflow's zsh already has `AUTO_CD` (type a
directory name, no `cd`) and `AUTO_PUSHD` (every `cd` pushes onto a stack).

Core moves:

```sh
cd -            # jump back to the previous directory (toggle between two)
dirs -v         # show the pushd stack; cd -2 jumps to entry 2
ls  ll  lt      # eza aliases: plain, long+git, tree (2 levels)
Ctrl-T          # fzf: fuzzy-pick a file under $PWD, insert its path
Ctrl-R          # fzf: fuzzy-search shell history — your past self's paths
devflow session # tmux session named after this directory
```

## Real-world example

You're editing nginx config on a server while comparing with a local copy:

```sh
cd /etc/nginx/sites-available     # remote pane
cd -                              # back to where you were, instantly
```

Two directories, one toggle — no retyping either path all afternoon.

## Exercises

1. `cd` through five directories, then use `dirs -v` and `cd -3` to jump
   without typing a path.
2. Open a deep file with `nvim` + `Ctrl-T` instead of tab-completing the path.
3. Re-run yesterday's long docker command via `Ctrl-R` typing only 4 letters.
4. Start `devflow session` in a project; detach (`Ctrl-a d`); reattach.

## Common mistakes

- Typing `cd ../../..` chains — use `cd -` / the pushd stack instead.
- Using `ls` to *find* things. Listing is for orienting; finding is lesson 02.
- One giant terminal instead of tmux panes per concern (lesson 09).

## Further reading

- `man zshoptions` — search AUTO_PUSHD
- devflow: `docs/zsh.md`
