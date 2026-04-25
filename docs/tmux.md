# tmux

Prefix is `Ctrl-a`. Optimized for both local and SSH workflow.

## Sessions

```text
devflow session <name>      new or attach
tmux ls                     list
prefix d                    detach
prefix s                    switch (interactive)
prefix $                    rename current
tmux kill-session           kill current
```

## Windows

```text
prefix c            new window
prefix n / p        next / prev
prefix ,            rename
prefix w            choose (interactive)
```

## Panes

```text
prefix |            split horizontal (inherits cwd)
prefix -            split vertical   (inherits cwd)
prefix h/j/k/l      move focus
prefix HJKL         resize (repeatable, hold prefix)
Alt-h/j/k/l         resize (no prefix)
prefix z            zoom toggle
prefix S            toggle synchronize-panes
```

## Copy mode

```text
prefix [            enter copy mode
v                   begin selection
y                   yank to clipboard
Esc                 cancel
/ ?                 search forward / back
```

Yank uses `pbcopy` on macOS and `wl-copy`/`xclip` on Linux. If neither
is present, the selection still goes into tmux's buffer; paste with
`prefix ]`.

## Other

Mouse is on. Splits and new windows inherit the current pane's
directory. `prefix r` reloads `~/.tmux.conf`. `escape-time` is 10ms so
nvim feels snappy. `renumber-windows` keeps window numbers contiguous
when one is closed.

## Per-project session

```sh
cd ~/code/api
devflow session            # session name = "api"
```

## Persistent over SSH

```sh
ssh box
devflow session work
# connection drops
ssh box
devflow session work       # right back where you were
```

## SSH-to-N-hosts pattern

Open one SSH pane per host, then `prefix S`. Anything you type goes to
every pane. `prefix S` again to stop.
