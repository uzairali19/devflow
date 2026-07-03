# 09 — tmux

## Concept

tmux separates *programs* from *terminals*. A session keeps running when
you disconnect; a terminal is just a window onto it. That's the killer
feature: SSH drops, laptop sleeps, you reattach and nothing died.

Hierarchy: **session** (a project) → **window** (a task) → **pane** (a view).

devflow bindings (prefix = `Ctrl-a`):

```text
devflow session      # session named after the current dir — the entry point
prefix d             # detach (everything keeps running)
prefix | / -         # split right / down (inherits cwd)
Ctrl-h/j/k/l         # move between panes — and nvim splits, same keys
prefix c / n / p     # new / next / previous window
prefix [             # copy mode: v select, y yank → system clipboard
prefix S             # synchronize-panes: type into N servers at once
prefix r             # reload config
```

## Real-world example

Deploying while watching for trouble, one screen:

```text
pane 1: ssh prod-1, journalctl -fu app     # live logs
pane 2: ssh prod-1                          # the deploy itself
pane 3: local, curl health endpoint in a loop
```

SSH connection drops mid-deploy? The remote side was in *its* tmux too —
reattach, nothing was interrupted. This is why lesson one on any new
server is `devflow session`.

## Exercises

1. Start `devflow session`, split into 3 panes, detach, close the terminal
   entirely, reopen, `devflow session` again — everything is still there.
2. Run a fake "deploy" (`sleep 120`) over SSH inside remote tmux; kill your
   wifi mid-way; reattach and confirm it survived.
3. Use `prefix S` to run `uptime` on two servers simultaneously.
4. Copy a log line from copy-mode into your browser — no mouse.

## Common mistakes

- Running long jobs over bare SSH: connection dies, job dies. tmux first,
  *then* the job.
- One giant session for everything — one session per project keeps
  `devflow sessions` meaningful.
- Nesting tmux-in-tmux by accident over SSH; prefix stops working. The
  remote one is the one you want; keep local plain or learn `prefix a`.
- Never learning copy-mode and reaching for the mouse (breaks over SSH).

## Further reading

- `man tmux` — skim "DEFAULT KEY BINDINGS" once
- devflow: `docs/tmux.md`, and the OSC52 clipboard notes in `docs/ssh-workflow.md`
