# Tests

Validates the chezmoi bootstrap on fresh Kali rolling + Ubuntu latest containers (Docker), without pushing or touching the host system.

## Quick start (via `just`)

```sh
just lint              # local-only — renders templates, sweeps for leaks (no Docker)
just test              # smoke on both distros (~5 min total — only one image pull)
just test-smoke kali   # smoke on Kali only
just test-full         # full bootstrap on both distros (SLOW, 60–120 min each)
```

See the top-level `justfile` for the full menu (`just -l`).

## Direct usage

```sh
./tests/run.sh ubuntu smoke    # ~30s
./tests/run.sh kali smoke      # ~30s + image pull on first run
./tests/run.sh all smoke
./tests/run.sh all full        # ~1-2hr per distro
./tests/lint.sh                # render-only, no docker
```

## What each mode tests

**`lint`** (no Docker)
- Renders every `*.tmpl` and reports template errors.
- Sweeps for hardcoded `/home/kanvk`, `kanvk`, `kkhare`, `linuxbrew`, `pyenv/shims` outside the known-intentional set.
- Validates `.chezmoidata.yaml` parses as YAML.
- Runs shellcheck on every script under `.chezmoiscripts/` (if shellcheck is installed).

**`smoke`** (default — recommended for iteration)
- `chezmoi apply --exclude=scripts,externals` — no Homebrew install, no apt install, no plugin clones. ~30s.
- Validates: every expected file exists at the right target path; modes are correct (`~/.ssh/` is 0700, `~/.ssh/config` is 0600, `private_dot_*` files are 0600); shell init has valid zsh syntax (`zsh -n`); identity templating is correct (`name = Test User` / `email = test@example.com` end up in `.gitconfig`); `gpgsign = false` when no GPG key was provided; `ZSH_CUSTOM` is set; gpg-agent.conf has a `pinentry-program`; SSH config preserves `Host github.com-ghe` + `Include ~/.ssh/config.local`.
- OS gates: `wsl.zsh` is NOT applied (`is_wsl=false`); `dot_config/windows/**` is NOT applied (Linux); `tests/`, `README.md`, `CLAUDE.md`, `justfile`, `.ssh/config.local.example` are NOT applied (chezmoiignore).
- No `/home/kanvk` leak in any rendered shell file.
- Idempotence: re-apply produces zero changes.

**`full`**
- Runs the entire pipeline: `apt install`, Homebrew bootstrap, `brew bundle install`, pipx, npm, cargo (after rustup-init), go, sheldon lock, nvim Lazy sync, broot install, TPM plugin install, completion regen, summary script.
- All smoke checks PLUS:
  - brew, sheldon, nvim, atuin, cargo, go, npm, bun all on PATH.
  - rust uutils `coreutils` binary on PATH (the `command coreutils <cmd>` aliases in alias.zsh require it).
  - TPM cloned at `~/.tmux/plugins/tpm`.
  - Sheldon plugin tree exists.
  - `~/.zfunc/_chezmoi`, `~/.zfunc/_just`, `~/.zfunc/_poetry` regenerated.

## Container details

- `testuser` with passwordless `sudo`.
- Repo bind-mounted read-only at `/dotfiles`. `bootstrap.sh` reads from there.
- `~/.config/chezmoi/chezmoi.toml` is pre-populated (no TTY for `promptStringOnce`).
- No state persists across runs.

## Troubleshooting

- **`docker: permission denied`** — `sudo usermod -aG docker $USER && newgrp docker`.
- **Image pulls hang** — `kalilinux/kali-rolling` is ~1.5 GB. Run `docker pull kalilinux/kali-rolling` separately to see progress.
- **`full` test fails on Homebrew install** — check egress (`docker run --rm chezmoi-test:kali curl -I https://github.com`). Some VPNs block container traffic.

## Adding a new validation check

Edit `bootstrap.sh` — append to the relevant `# ---` section. Helpers available:

- `check <test-args>` — generic file/dir presence check (e.g. `check -f path` or `check -d path`)
- `mode_eq <path> <octal>` — assert mode (e.g. `mode_eq ~/.ssh 700`)
- `contains <path> <regex>` — grep -qE in file
- `absent <path>` — file/dir must not exist (for OS gates and chezmoiignore checks)
