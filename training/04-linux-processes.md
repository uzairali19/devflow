# 04 — Linux Processes

## Concept

Everything running is a process: a PID, an owner, file descriptors, and a
parent. Services are just processes supervised by systemd. Debugging a
server is mostly asking four questions — what's running, what's it doing,
what's it holding open, who started it.

```sh
ps aux                        # everything (a=all users, u=detail, x=no-tty)
ps aux --sort=-%cpu | head    # hungriest first (also --sort=-%mem)
htop                          # interactive; F5 = process tree
kill PID                      # polite: SIGTERM, lets it clean up
kill -9 PID                   # brutal: SIGKILL — last resort only
lsof -i :3000                 # who owns port 3000
lsof -p PID | head            # what files/sockets a process holds

systemctl status nginx        # is the service up, and why not
systemctl restart nginx
journalctl -u nginx --since "1 hour ago"
journalctl -p 3 -n 20         # last 20 error-level lines, any unit

cmd &                         # background a job; jobs / fg %1 to manage
Ctrl-Z, then bg               # "oops, should have backgrounded that"
```

## Real-world example

"The app won't start, port already in use":

```sh
lsof -i :3000                 # PID 4127, an old node process
ps -fp 4127                   # confirm what it is before touching it
kill 4127                     # TERM first
lsof -i :3000                 # gone? good. Only reach for -9 if not.
```

## Exercises

1. `sleep 300 &` — find it with `ps`, `htop`, and `lsof -p`; kill it politely.
2. On any systemd machine: pick a service, read `systemctl status` and its
   last hour of `journalctl` output.
3. Start a long command, `Ctrl-Z`, `bg`, `jobs`, `fg` — own the job cycle.
4. Find the top 3 memory consumers on your machine right now.

## Common mistakes

- `kill -9` as the first move — the process never flushes or cleans up.
  TERM, wait a few seconds, then escalate.
- Restarting a service without reading its log first: the evidence of *why*
  it was sick often disappears with the restart.
- Confusing "high CPU" with "broken" — a busy worker is supposed to be busy.
  Compare against its normal.

## Further reading

- `man 7 signal` — what TERM/INT/HUP/KILL actually mean
- devflow: lesson 07 builds on this for production incidents
