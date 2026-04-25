# Bootstrap

The one-line installer for fresh remote machines.

```sh
curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

## What it does

1. Detects the OS.
2. Installs base packages needed before anything else can run:
   `build-essential`, `curl`, `git`, `ca-certificates` (Debian/Ubuntu);
   `gcc`, `make`, `curl`, `git`, `ca-certificates` (RHEL/Fedora).
3. Clones (or updates) the devflow repo into `$HOME/devflow`.
4. Hands off to `./install.sh --remote --languages` which links configs
   and installs mise-managed runtimes (node, python, go, rust).

## Supported OSes

- Debian, Ubuntu, Pop!_OS, Linux Mint, Raspbian, Kali (apt)
- RHEL, CentOS, Rocky, AlmaLinux, Fedora, Amazon Linux (dnf or yum)
- macOS (skips package install; requires Xcode Command Line Tools for git)

Anything else fails with a clear message asking you to install
`git`/`curl`/build tools manually and run `./install.sh --remote --languages`.

## Why these packages

- **build-essential** / **gcc**+**make** — mise compiles some language
  installs from source (notably Python). Without a C toolchain, Python
  build fails partway through with cryptic errors.
- **curl** — needed to download mise itself.
- **git** — needed to clone this repo.
- **ca-certificates** — needed for HTTPS to GitHub, mise.run, and
  starship.rs.

## What it does NOT install

By design:

- no databases (MongoDB, PostgreSQL, Redis, etc.)
- no message queues, no app servers
- no Docker

These belong to a project, not the dotfiles. See
[`languages.md`](languages.md) for the rationale and a MongoDB/AVX
note worth knowing if you do install one yourself.

## Environment overrides

| Variable           | Default                                              |
| ------------------ | ---------------------------------------------------- |
| `DEVFLOW_REPO_URL` | `https://github.com/uzairali19/devflow.git`          |
| `DEVFLOW_DIR`      | `$HOME/devflow`                                      |
| `DEVFLOW_BRANCH`   | `main`                                               |

```sh
DEVFLOW_DIR="$HOME/.devflow" \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash

DEVFLOW_BRANCH=dev \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash

DEVFLOW_REPO_URL=git@github.com:you/devflow.git \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

## Sudo handling

- Running as root: `sudo` is not used.
- Running as a normal user: `sudo` is used for package install.
- Normal user without `sudo` installed: bootstrap fails fast with a
  clear message. Either re-run as root or install `sudo` first.

## Idempotency

Re-running the one-liner is safe:

- Already-installed packages are no-ops.
- An existing devflow git checkout is `git fetch && checkout && pull
  --ff-only`'d to the requested branch.
- A non-git directory at `$DEVFLOW_DIR` is treated as user data and
  bootstrap refuses to touch it.

## Troubleshooting

### sudo is missing

```text
this step needs root and sudo is not installed.
```

You're running as a non-root user on a system without sudo. Either:

```sh
# 1. become root
su -
curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash

# 2. or install sudo first (as root) and re-run as your normal user
apt-get install -y sudo
usermod -aG sudo <your-user>
```

### apt / dnf unavailable

If your distro doesn't ship apt or dnf, install these manually then run
the installer directly:

```sh
# install yourself: git curl ca-certificates and a C toolchain (gcc, make)
git clone https://github.com/uzairali19/devflow.git ~/devflow
cd ~/devflow
./install.sh --remote --languages
```

### git pull conflicts

If `bootstrap.sh` errors on `git pull --ff-only`, you have local
changes in your devflow checkout. Resolve them yourself:

```sh
cd ~/devflow
git status
git stash             # or commit, or reset
```

Then re-run the bootstrap.

### `$HOME/devflow` exists but isn't a git repo

```text
$HOME/devflow exists and is not a git repo.
Move/delete it, or set DEVFLOW_DIR=<other path> and re-run.
```

Bootstrap won't overwrite a non-git directory because that might be
your data. Pick one:

```sh
mv ~/devflow ~/devflow.old
# or
DEVFLOW_DIR="$HOME/.devflow" \
  curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh | bash
```

### Shell doesn't pick up the new config

Bootstrap (and `install.sh`) cannot reload the shell that's running
them. After bootstrap finishes, run:

```sh
exec zsh -l
devflow doctor
```

### Verifying without piping

If you don't want to run a remote script blind:

```sh
curl -fsSL https://raw.githubusercontent.com/uzairali19/devflow/main/scripts/bootstrap.sh -o /tmp/bootstrap.sh
less /tmp/bootstrap.sh         # read it
bash /tmp/bootstrap.sh         # run it
```
