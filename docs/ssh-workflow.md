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

## Terminal: `xterm-ghostty` over SSH

Ghostty is a local terminal — its terminfo entry (`xterm-ghostty`) lives
on your laptop, not on the remote server. When you SSH from Ghostty, the
remote shell inherits `TERM=xterm-ghostty`, but the remote system has
never seen that entry, so tmux/less/vim throw:

```text
missing or unsuitable terminal: xterm-ghostty
```

devflow handles this automatically. Near the top of `configs/zsh/zshrc`:

```sh
if [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty >/dev/null 2>&1; then
  export TERM="xterm-256color"
fi
```

The fallback only fires when the remote really lacks the entry. Hosts
that *do* know `xterm-ghostty` (because you installed it there) keep
the original.

If you still see the error after a fresh shell, check what the shell
actually sees:

```sh
echo "$TERM"
infocmp "$TERM"
```

If `infocmp` says "Couldn't open terminfo file", either:

- Your `~/.zshrc` isn't the devflow one (`readlink ~/.zshrc` should
  point into the devflow repo). Re-run the installer.
- Your shell hasn't reloaded since install. Run `exec zsh -l`.
- You're in `bash`, not `zsh`. Switch shells or set `TERM=xterm-256color`
  in `~/.bashrc` for the same reason.

## Backspace and Delete over SSH

Some terminals send `^?` for Backspace and others send `^H`. Inside an
SSH → tmux → zsh stack the wrong combination eats characters or does
nothing. devflow's `zshrc` binds both:

```sh
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" delete-char
```

If Backspace still misbehaves, see what the terminal is actually
sending:

```sh
showkey -a
# press Backspace → expect ^? or ^H
# press Delete    → expect ^[[3~
# press Ctrl-C twice to exit
```

If `showkey` shows something else (a stray `^[[127;5u`, etc.), the
upstream emulator is sending a non-standard sequence. Set Ghostty's
keybind for `backspace` back to default in `~/.config/ghostty/config`,
or add a matching `bindkey` line to `~/.zshrc.local`.
