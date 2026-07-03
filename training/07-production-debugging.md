# 07 — Production Debugging

## Concept

Production debugging is a discipline, not a toolbox. The method:

1. **Stabilize your head.** Write down the symptom, exactly, with a time.
   "Checkout 500s since ~14:20" beats "site is broken".
2. **What changed?** Deploys, config, traffic, certs, cron. Most incidents
   are self-inflicted and recent.
3. **Follow one request** through the layers (lesson 06) instead of jumping
   randomly between dashboards.
4. **Resources, then logs, then code.** `devflow health <host>` does the
   first sweep in one shot: load, memory, disk, docker, ports, journal errors.
5. **Change one thing at a time**, and write down what you changed.

The classic culprits, in rough base-rate order: disk full, memory/OOM,
expired cert, DNS, a bad deploy, a stuck queue.

```sh
devflow health prod-1              # the first five minutes, automated
df -h                              # disk full breaks *everything weirdly*
free -h; dmesg -T | rg -i 'oom'    # did the kernel kill something?
journalctl -u app --since "30 min ago"
docker logs --since 30m api
ss -tuln                           # is it even listening?
```

## Real-world example

Symptom: app returns 502 since last night.

```sh
devflow health prod-1     # disk 100% on /  ← stop, that's probably it
du -xh / 2>/dev/null | sort -h | tail -15   # what grew? log file, 40GB
docker logs api | head   # confirms: "No space left on device" everywhere
```

Fix the space, then the real work: why did a log grow unbounded? That
answer goes in the project's MISTAKES.md, and the guard rail (logrotate,
disk alert) goes in an ADR.

## Exercises

1. On any server: run through the health sweep by hand once (df, free,
   dmesg, journalctl, docker ps, ss) so the automated report means something.
2. Take an old incident you remember and write the MISTAKES.md entry for it
   now: root cause, cost, lesson, guard rail.
3. Fill a scratch VM's disk on purpose (`fallocate -l 5G`) and watch what
   breaks and how it lies about it.

## Common mistakes

- Restarting the service before capturing logs — you just destroyed the
  evidence and taught yourself nothing.
- Debugging in your head at 2am instead of on paper. Write the timeline.
- Fixing the symptom and skipping the postmortem — same incident next month.
- SSHing into prod and *changing* things to see what happens. Observe
  first; mutate deliberately.

## Further reading

- Google SRE book, "Effective Troubleshooting" chapter (free online)
- Brendan Gregg's USE method — a systematic resource checklist
