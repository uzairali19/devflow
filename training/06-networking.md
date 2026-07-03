# 06 — Networking

## Concept

Nearly every "is the network broken?" question decomposes into four layers,
checked in order:

1. **Do I have an address/route?** → `ip addr`, `ip route`
2. **Can I reach the host?** → `ping`, `traceroute`/`mtr`
3. **Is the port open and owned?** → `ss -tuln`, `lsof -i :PORT`, `nc -vz`
4. **Does the application answer correctly?** → `curl -v`, `dig`

```sh
ip addr                        # my interfaces and IPs
ss -tuln                       # listening sockets (t=tcp u=udp l=listen n=numeric)
ss -tlnp                       # ...with owning process (needs sudo for others')
nc -vz host 5432               # "can I open a TCP connection" — yes or no
dig api.example.com            # what DNS actually returns (+short for terse)
curl -v https://api/health     # full handshake: DNS, TLS, headers, body
curl -o /dev/null -sw '%{http_code} %{time_total}s\n' URL   # code + latency

ssh -L 8080:localhost:80 host  # tunnel: my :8080 -> host's :80 (DB GUIs!)
rsync -avz --dry-run src/ host:dst/   # sync files; ALWAYS dry-run first
```

## Real-world example

"The API is down" — but is it? From your laptop:

```sh
dig api.example.com +short     # DNS resolves? to the IP you expect?
nc -vz api.example.com 443     # TCP reachable?
curl -v https://api.example.com/health   # TLS ok? what status code?
```

Then the same `curl` from the server itself (`ssh` in first). Laptop fails +
server succeeds = network/DNS/firewall between you. Both fail = the app.
That one comparison halves the search space.

## Exercises

1. Run `ss -tuln` locally and account for every listening port. Anything
   you can't explain is homework.
2. `curl -v` a site and read the output top to bottom: DNS, connect, TLS,
   request, response.
3. Tunnel a remote service to your laptop with `ssh -L` and hit it in a browser.
4. `dig` a domain, then `dig @1.1.1.1` the same — explain any difference.

## Common mistakes

- Testing with `ping` when the service is TCP: ICMP can be blocked while
  the port works fine (and vice versa). Test the actual port with `nc`.
- Trusting DNS from memory — it changed. `dig` it every time.
- Forgetting "where am I testing from": firewall rules differ per source.
- `rsync` without `--dry-run` for the first invocation of a new pair.

## Further reading

- `man ss` — the filter language is worth 10 minutes
- devflow: `docs/ssh-workflow.md`
