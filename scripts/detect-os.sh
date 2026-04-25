#!/usr/bin/env bash
# Sourced by install.sh. Exports OS, DISTRO, ARCH.

case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)
    printf "detect-os: unsupported kernel: %s\n" "$(uname -s)" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

DISTRO=""
if [[ "$OS" == "linux" && -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO="${ID:-}"
fi

ARCH="$(uname -m)"

export OS DISTRO ARCH
