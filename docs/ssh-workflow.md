# SSH workflow

## Bootstrap a remote

```sh
ssh box
git clone https://github.com/uzairali19/devflow.git ~/.devflow
cd ~/.devflow
./install.sh --remote
exec zsh -l
```

If the box has no outbound git, rsync from your laptop:

```sh
rsync -az --delete --exclude .git ~/.devflow/ box:.devflow/
ssh box "cd ~/.devflow && ./install.sh --remote"
```

## Persistent sessions

```sh
ssh box
devflow session work
# do work, connection drops
ssh box
devflow session work       # same panes, same state
```

`devflow session <name>` is `tmux new-session -A -s <name>`. One session
per project so the names mean something.

## SSH config

`~/.ssh/config` on your laptop:

```ssh-config
Host *
    ServerAliveInterval 30
    ServerAliveCountMax 6
    ControlMaster auto
    ControlPath  ~/.ssh/sockets/%r@%h:%p
    ControlPersist 10m
    AddKeysToAgent yes
    UseKeychain yes        # macOS only

Host box
    HostName box.example.com
    User you
    ForwardAgent yes
```

Run `mkdir -p ~/.ssh/sockets` once.

`ServerAlive*` keeps flaky links from dying silently. `ControlMaster`
makes second-and-later `ssh box` calls instant.

## Clipboard

`y` in tmux copy mode runs `pbcopy` on macOS, `wl-copy` or `xclip` on
Linux. Otherwise the selection lands in tmux's buffer — paste with
`prefix ]`.

If your local terminal supports OSC52 (Ghostty does), the clipboard
works through SSH without forwarding anything.

## Editing remote files

In place: `nvim` on the remote, ideally inside `devflow session`.

`rsync` is almost always better than `scp`:

```sh
rsync -az --info=progress2 ~/code/foo/ box:code/foo/
```

## Update

```sh
ssh box
devflow update
```

`git pull --ff-only` then re-link configs.
