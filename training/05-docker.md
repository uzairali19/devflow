# 05 — Docker

## Concept

An image is a frozen filesystem + metadata; a container is one process tree
started from it. Containers are disposable — state that matters lives in
volumes. Compose is just "several containers + a network + volumes" declared
in one file. Debugging docker is 90% these:

```sh
docker ps                     # running (add -a: including dead ones)
docker logs -f NAME           # the app's stdout/stderr — read this FIRST
docker logs --since 10m NAME
docker exec -it NAME sh       # shell inside (bash if the image has it)
docker inspect NAME | less    # env, mounts, network — the full truth
docker stats                  # live cpu/mem per container

docker compose up -d          # start the stack
docker compose ps             # stack status
docker compose logs -f api    # follow one service
docker compose restart api    # bounce one service, keep the rest
```

Cleanup — the only genuinely destructive part, look before each step:

```sh
docker system df              # what's eating disk
docker image prune            # dangling images only — safe
docker system prune           # asks confirmation; read what it lists
```

## Real-world example

A container is "up" but the app is dead:

```sh
docker ps                     # status says Up 2 hours — lies of omission
docker logs --since 30m api   # stack trace: can't reach postgres
docker exec -it api sh
  ping db && env | grep DB    # inside: wrong DB_HOST env var
docker inspect api | rg -A3 Env   # confirm what it was started with
```

The bug was in compose environment config — no restarting-until-it-works.

## Exercises

1. Run `docker run -d --name web nginx`, then: read its logs, exec in, find
   the config file, stop and remove it.
2. Write a 2-service compose file (app + redis); confirm the app can reach
   redis by service name; bounce only redis.
3. Fill in: which of your containers would lose data on `rm`? Check
   `docker inspect` Mounts to answer, not memory.
4. Run `docker system df` on your machine and explain every line.

## Common mistakes

- Restarting a crashing container in a loop instead of reading
  `docker logs` — the answer is nearly always printed there.
- Storing state in the container filesystem, then losing it on recreate.
- `docker system prune -a --volumes` from muscle memory — that deletes data.
- Debugging networking from the host when the question is "can container A
  reach container B" — exec inside and ask from there.

## Further reading

- `docker compose --help` — the ps/logs/restart trio
- devflow: lesson 07 for docker in production incidents
