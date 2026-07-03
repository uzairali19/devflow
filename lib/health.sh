# lib/health.sh — remote server health report.
# Sourced by bin/devflow.
#
# devflow health <host>
#
# <host> is whatever `ssh <host>` already accepts — an alias from
# ~/.ssh/config or a full user@hostname. devflow keeps NO parallel server
# inventory: your ssh config is the single source of truth, so there is
# nothing to sync and nothing secret to accidentally commit.
#
# The remote script is strictly read-only and degrades gracefully: every
# section that needs a missing tool (or sudo) says so instead of failing.

_ssh_config_hosts() {
  # Host aliases from ~/.ssh/config, minus wildcard patterns.
  # (Doesn't follow Include directives — good enough for a hint list.)
  awk 'tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i !~ /[*?]/) print $i }' \
    "$HOME/.ssh/config" 2>/dev/null | sort -u
}

cmd_health() {
  local host="${1:-}"
  if [[ -z "$host" ]]; then
    echo "usage: devflow health <host>   (anything 'ssh <host>' accepts)"
    local hosts
    hosts="$(_ssh_config_hosts)"
    if [[ -n "$hosts" ]]; then
      echo
      echo "hosts in ~/.ssh/config:"
      printf '  %s\n' $hosts
    fi
    return 1
  fi

  log "health report: $host"
  # Single-quoted heredoc: nothing expands locally; the whole script runs
  # remotely. One ssh round trip for the entire report.
  ssh -o ConnectTimeout=8 "$host" bash -s <<'REMOTE'
sec() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

sec "host"
printf '%s  |  kernel %s  |  %s\n' "$(hostname)" "$(uname -r)" "$(uname -m)"

sec "uptime / load"
uptime

sec "cpu"
printf '%s core(s)\n' "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null)"

sec "memory"
free -h 2>/dev/null || vm_stat 2>/dev/null || echo "free unavailable"

sec "disk"
df -h -x tmpfs -x devtmpfs -x overlay 2>/dev/null || df -h

sec "docker"
if command -v docker >/dev/null 2>&1; then
  if docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null; then
    stopped=$(docker ps -aq --filter status=exited 2>/dev/null | wc -l | tr -d ' ')
    [ "${stopped:-0}" -gt 0 ] && echo "($stopped stopped container(s) — docker ps -a)"
  else
    echo "docker installed but daemon unreachable (not running? permissions?)"
  fi
else
  echo "not installed"
fi

sec "listening ports"
ss -tuln 2>/dev/null | head -25 || netstat -tuln 2>/dev/null | head -25 \
  || echo "ss/netstat unavailable"

sec "recent journal errors (24h)"
journalctl --no-pager -p 3 -n 10 --since "24 hours ago" 2>/dev/null \
  || echo "journalctl unavailable (or needs sudo for the full system journal)"

sec "tailscale"
if command -v tailscale >/dev/null 2>&1; then
  tailscale status --peers=false 2>/dev/null | head -3 || tailscale status 2>/dev/null | head -3
else
  echo "not installed"
fi

sec "firewall"
sudo -n ufw status 2>/dev/null || ufw status 2>/dev/null \
  || echo "ufw status needs sudo (run manually: sudo ufw status)"

sec "updates available"
if command -v apt-get >/dev/null 2>&1; then
  n=$(apt-get -s upgrade 2>/dev/null | grep -c '^Inst') || n=0
  echo "$n package(s) upgradable (apt-get -s upgrade — simulation only)"
else
  echo "apt not present, skipping"
fi
REMOTE
}
