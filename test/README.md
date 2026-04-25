# Bootstrap tests

Runs the chezmoi bootstrap inside fresh Docker containers (Kali rolling + Ubuntu latest) against the local working tree, so changes can be validated without pushing or touching the host system.

## Quick start

```sh
./test/run.sh ubuntu smoke    # fastest — ~30s
./test/run.sh kali smoke
./test/run.sh all smoke
./test/run.sh all full        # SLOW — ~60–120 min per distro
```

## What each mode tests

**`smoke`** (default — recommended for iteration)
- Skips `--exclude=scripts,externals` so no Homebrew install, no apt install, no plugin clones.
- Validates: templates render, dotfiles end up at the right paths with correct templated identity, OS gates work (e.g. `wsl.zsh` is not applied when `is_wsl=false`), no `/home/kanvk` leaks, the github.com-ghe SSH alias is preserved.
- Tests idempotence: re-runs `chezmoi apply` and asserts no further changes are made.

**`full`**
- Runs the entire pipeline: `apt install …`, Homebrew install, `brew bundle install`, pipx, npm, cargo, go, sheldon lock, nvim Lazy sync, broot install, TPM plugin install, completion regen.
- Slow because Homebrew bootstrapping a couple-hundred packages is slow.
- Use when you change `.chezmoidata.yaml` or anything in `.chezmoiscripts/`.

## Container details

- Each container has a `testuser` with passwordless `sudo`.
- The repo is bind-mounted read-only at `/dotfiles`. `bootstrap.sh` reads from there.
- Container's `~/.config/chezmoi/chezmoi.toml` is pre-populated with test identity values (no TTY available for the `promptStringOnce` flow).
- No state persists across runs — every invocation starts from a clean container.

## Troubleshooting

- **`docker: permission denied`** — add yourself to the `docker` group: `sudo usermod -aG docker $USER && newgrp docker`.
- **Image pulls hang** — `kalilinux/kali-rolling` is ~1.5 GB. Run `docker pull kalilinux/kali-rolling` separately if you want to see the progress bar.
- **`full` test fails on Homebrew install** — check the container has internet egress (`docker run --rm chezmoi-test:kali curl -I https://github.com`). Some VPNs block Docker container traffic.

## Adding a new validation check

Edit `bootstrap.sh` — append to the `# --- validate ---` block. Use the `check` helper for file/dir presence; `grep -q` plus a manual fail-line for content checks.
