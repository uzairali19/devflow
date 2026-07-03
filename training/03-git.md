# 03 — Git

## Concept

Git is a graph of immutable snapshots (commits) with movable labels
(branches, HEAD). Almost nothing is ever lost — most "disasters" are a
label pointing somewhere surprising, and `reflog` is the undo history for
labels. Internalize that and fear disappears.

Daily loop (devflow aliases in parentheses):

```sh
git status -sb        (gs)    # where am I
git diff              (gd)    # what changed
git add -p                    # stage hunk by hunk — review your own work
git commit
git log --oneline --graph -20 (gl)
git pull --rebase --autostash (gp)
```

Recovery kit:

```sh
git stash / git stash pop     # shelve work mid-task
git restore FILE              # discard unstaged changes (destructive!)
git reset --soft HEAD~1       # un-commit, keep everything staged
git reflog                    # every place HEAD has been
git reset --hard HEAD@{1}     # ...and how to get back there
git bisect start/good/bad     # binary-search which commit broke it
```

## Real-world example

You rebased, it went wrong, the branch "lost" a day of work:

```sh
git reflog                    # find the hash from before the rebase
git reset --hard HEAD@{4}     # branch restored, nothing was ever lost
```

## Exercises

1. Make three scrappy commits, then `git rebase -i HEAD~3` and squash them
   into one with a good message — in a throwaway repo.
2. Break something on purpose, then `git bisect` it back to the guilty
   commit using an obvious test.
3. Use `git add -p` for a full day. Notice how many accidental changes you
   catch before they ship.
4. `git reset --hard` a branch, then rescue it via `reflog`.

## Common mistakes

- Commit messages that say *what* ("update code") instead of *why*. The
  diff already shows what.
- `git add .` without looking — that's how `.env` files and debug prints ship.
- Fearing rebase because of one bad experience, instead of learning reflog.
- Long-lived branches: merging weekly costs less than merging monthly.

## Further reading

- `git help revisions` — what `HEAD~2`, `@{u}`, `HEAD@{1}` actually mean
- Pro Git (free online), chapters 1–3 and 7.11 (reset demystified)
