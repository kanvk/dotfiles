# Tests

Validates the chezmoi bootstrap on fresh Kali rolling + Ubuntu latest containers, without pushing or touching the host system.

## Hierarchy

`lint` is a static, no-Docker pass; runs in seconds. `test-smoke` applies dotfiles inside fresh containers but skips the install-script chain. `test-full` is a **strict superset of `test-smoke`** — it also runs the install scripts and verifies the resulting toolchains. So:

- During dev iteration: `just lint` (fast feedback on template / shellcheck issues).
- Before commit: `just test-smoke`.
- Before merge: `just test-full` (no need to also run smoke — full covers it).

## Via `just`

```sh
just lint
just test                # alias for test-smoke (both distros)
just test-smoke kali     # one distro
just test-full           # both distros, full pipeline
```

`just -l` for the menu.

## Direct usage

```sh
./tests/lint.sh                 # static, no Docker
./tests/run.sh ubuntu smoke
./tests/run.sh kali smoke
./tests/run.sh all smoke
./tests/run.sh all full
```

## What each mode tests

**`lint`** (static, no Docker)
- Renders every `*.tmpl` and reports template errors.
- Sweeps for hardcoded `/home/kanvk`, `kanvk`, `kkhare`, `linuxbrew`, `pyenv/shims` outside the known-intentional set.
- Validates `.chezmoidata.yaml` parses as YAML.
- Runs shellcheck on every script under `.chezmoiscripts/` (if shellcheck is installed).

**`smoke`**
- `chezmoi apply --exclude=scripts,externals` — no Homebrew install, no apt install, no plugin clones.
- Validates: every expected file exists at the right target path; modes are correct (`~/.ssh/` is 0700, `~/.ssh/config` is 0600, `private_dot_*` files are 0600); shell init has valid zsh syntax (`zsh -n`); identity templating is correct (`name = Test User` / `email = test@example.com` end up in `.gitconfig`); `gpgsign = false` when no GPG key was provided; `ZSH_CUSTOM` is set; gpg-agent.conf has a `pinentry-program`; SSH config preserves `Host github.com-ghe` + `Include ~/.ssh/config.local`.
- OS gates: `wsl.zsh` is NOT applied (`is_wsl=false`); `dot_config/windows/**` is NOT applied (Linux); `tests/`, `README.md`, `CLAUDE.md`, `justfile`, `.ssh/config.local.example` are NOT applied (chezmoiignore).
- No `/home/kanvk` leak in any rendered shell file.
- Idempotence: re-apply produces zero file changes.

**`full`** — strict superset of `smoke`, plus:
- Runs the entire pipeline: `apt install`, Homebrew bootstrap, `brew bundle install`, pipx, npm, cargo (after rustup-init), go, sheldon lock, nvim Lazy sync, broot install, TPM plugin install, completion regen, summary script.
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
