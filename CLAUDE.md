# CLAUDE.md — chezmoi dotfiles

Living notes for Claude (and future humans) working on this repo.

## What this repo is

`chezmoi` source for the author's dotfiles. Bootstrap on a new machine with:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kanvk
```

See `README.md` for the user-facing version of the same story.

## Hard invariants

- **Repo is public.** Never commit plaintext secrets, OAuth tokens, API keys, signed JWTs, or private SSH keys. Machine-local secrets belong at `~/.config/zsh/omz-custom/hidden.zsh`, which is gitignored and sourced by OMZ at shell start. This file must never move into the chezmoi source tree, even excluded — the whole point of the layout is that the source tree is safe to publish.
- **OS scope:** Officially supports Kali (WSL2) and Ubuntu (native or WSL2). macOS is not targeted; don't add macOS-specific branches unless they're free. Windows-native configs (`dot_config/windows/**`) and `dot_config/zsh/omz-custom/wsl.zsh` apply on every host — OS gates in `.chezmoiignore.tmpl` were dropped so `chezmoi add` works from a WSL box. They just sit unused on the wrong OS (WSL `.exe` aliases resolve to nothing; Windows configs sit at `~/.config/windows/` until copied manually on a Windows host — see `dot_config/windows/terminal/README.md`).
- **The install pipeline is additive only.** `chezmoi apply` installs listed packages but never uninstalls anything missing: brew bundle runs without `--cleanup`; nala/apt-get use `install`, never `purge`/`autoremove`; uv-tool/cargo/go/npm/bun/gh-extension steps only install or upgrade. To prune, run the manager's cleanup directly (`brew bundle cleanup --file=<bundle>`, `nala autoremove`, …). When adding a tool wanted on every machine, add it to `.chezmoidata.yaml` — don't expect re-snapshotting from the system.

## Commands

The `justfile` is the canonical entry point — `just -l` for the menu.

- **`just test`** / **`just test-smoke [distro]`** — apply dotfiles in a fresh container, no install scripts. Default: `ubuntu`.
- **`just test-full [distro]`** — full bootstrap (apt + brew bundle + uv tool + cargo + …). Strict superset of `test-smoke`. Slow.
- **`just lint`** — render every `.tmpl`, sweep for hardcoded refs, validate YAML, shellcheck. No Docker.
- **`just diff`** / **`just apply`** / **`just apply-force`** — chezmoi day-to-day.
- **`just show-tier <name>`** — print the resolved package set for a tier.
- **`just checklist`** — replay the post-apply manual-steps summary.

**Routine testing uses Ubuntu only.** Kali and Ubuntu are functionally equivalent here (both `is_debian_like`, same nala+brew pipeline). `just test-full ubuntu` passing implies kali passes — only run `just test-full kali` (or `all`) when you've changed something distro-specific (e.g. apt names that drift on kali, kali-specific gates).

## Conventions

- **Path templating:** prefer `$HOME` in shell contexts (the shell expands at runtime, template stays portable), use `{{ .chezmoi.homeDir }}` in non-shell contexts (Nix, JSON, Lua, symlink targets).
- **Identity templating:** `{{ .name }}`, `{{ .email }}` — seeded by `promptStringOnce` in `.chezmoi.toml.tmpl`.
- **OS gates:**
  - `{{ if .is_wsl }}` for WSL-only blocks (derived from `.chezmoi.kernel.osrelease` containing `microsoft` OR `$WSL_DISTRO_NAME` set).
  - `{{ if .is_debian_like }}` for apt logic — covers Debian (`ID=debian`), Ubuntu (`ID=ubuntu`), and Kali (`ID=kali` + `ID_LIKE=debian`). Branch on this, not on a single distro id.
- **Soft-detect optional tools:** for Spack, Miniforge/conda, mamba, NVIDIA HPC SDK, pyenv — wrap in `[[ -d … ]]` or `[[ -x $(command -v …) ]]` checks so the config is inert when the tool isn't installed. The user keeps the config in-tree so it "just works" the moment the tool arrives.
- **Plugin installs are delegated to their native managers:** sheldon owns `~/.local/share/sheldon/repos/**` (don't vendor it); tpm owns `~/.tmux/plugins/**`; lazy.nvim owns `~/.local/share/nvim/lazy/**`; Mason owns LSP servers. Our `.chezmoiscripts/` just kick these off.
- **apt is via nala when available.** Install script bootstraps nala via apt-get on first run, then uses nala (parallel downloads, nicer UI) thereafter; falls back to apt-get if missing.
- **Tier-based package selection.** `.chezmoidata.yaml` shape: `tiers: { <name>: { inherits: [...], include: { <mgr>: [...] }, exclude: { <mgr>: [...] } } }`. The `.tier` data var (prompted at init, default `full`) selects which tier resolves. Resolution = walk inherits, union per-manager `include`s, subtract per-manager `exclude`s. **Excludes are eager**: a child of a tier that excludes X starts without X — enables `full-without-foo`-style siblings. Resolver: `.chezmoitemplates/resolve-tier`; inspect with `just show-tier <name>`. Per the additivity invariant above, downgrading `full → minimal` on an existing machine leaves extras in place — `exclude` only means "don't install henceforth."
- **Tool completions are regenerated, not vendored.** Do not commit `dot_zfunc/_poetry`, `_rustup`, `_atuin`, etc. The `run_onchange_after_50-regen-completions.sh.tmpl` script handles those. Brew-installed tools that ship `_<tool>` via their formula don't need regen entries either — `$(brew --prefix)/share/zsh/site-functions` is on fpath via `dot_zshrc`. Sheldon plugins that ship completions (forgit's `completions/`, zsh-completions' `src/`) are wired onto fpath via `apply = ["fpath"]` / `apply = ["fpath-completions"]` in `dot_config/sheldon/plugins.toml`, and must be ordered BEFORE `oh-my-zsh` (which runs compinit). Hand-written completions for shell-defined commands (e.g. `dot_zfunc/_ts` for the `ts` function) DO live in `dot_zfunc/` — the no-vendor rule is about not duplicating tools' own generator output.
- **OMZ custom dir lives at `dot_config/zsh/omz-custom/`** (not inside sheldon's cache). The user's `dot_zshrc` sets `ZSH_CUSTOM` to that path. Preserve the `plugins/` and `themes/` subtree structure.
- **`run_onchange_after_*` scripts must include `{{ template "brew-path-bootstrap" . }}`** at the top (right after `set -euo pipefail`). chezmoi runs each script in a fresh subshell — PATH from earlier scripts (e.g. `brew shellenv`) does *not* propagate. Without it, `command -v sheldon`/`just`/`broot` silently no-op on first apply. Template at `.chezmoitemplates/brew-path-bootstrap`; also adds `~/.cargo/bin`, `~/.local/bin`, `~/go/bin`.
- **Cargo install runs per-package, tolerantly.** `run_onchange_before_00-install-packages.sh.tmpl` loops one `cargo install` per crate with `|| echo warning…`. A single bad crate (missing system lib, transient compile error) emits a warning but does NOT abort the install pipeline.
- **`~/.cargo/env` and `~/.cargo/bin` are PATH-extended in two places, intentionally.** `dot_zshenv` sources `~/.cargo/env` for non-interactive zsh (one-off `zsh -c`, ssh `command=…`). `.chezmoitemplates/brew-path-bootstrap` separately prepends `~/.cargo/bin` for chezmoi-apply-time scripts (fresh subshells, no zshenv). Both are needed.
- **Analytics opt-outs at install time, not just shell time.** `HOMEBREW_NO_ANALYTICS`, `HOMEBREW_NO_ENV_HINTS`, `DO_NOT_TRACK` are set at the top of the install script — `export.zsh` only fires in interactive zsh, too late for chezmoi-apply-time installs.
- **Login shell switch is `run_once`, not `run_onchange`.** `run_once_after_70-default-shell.sh.tmpl` flips the login shell to a `/etc/shells`-listed zsh (system `/usr/bin/zsh`, never brew's) once per machine. If the user later chshes back to bash, the script stays out of the way — re-run by editing the script body or `chezmoi state delete-bucket --bucket=scriptState`. Uses `usermod -s` over `chsh` for containers/PAM-restricted setups.
- **The install script holds a sudo keepalive** for the apply pipeline. `sudo -v` up front + a backgrounded `( while kill -0 $$; do sudo -n true; sleep 60; done ) &` collapses 2–3 prompts (apt + brew installer + post-install `usermod`) into one. The `kill -0 $$` guard self-terminates the loop if the script is killed without firing its EXIT trap.

## Layout

```
.chezmoi.toml.tmpl         # init-time prompts + computed vars (.is_wsl, .is_debian_like, .tier)
.chezmoidata.yaml          # tiered package lists (apt/brew/pipx [via uv tool]/npm/cargo/go/bun/gh-ext)
.chezmoiignore.tmpl        # repo-docs/test exclusions + encrypted-locals gate
.chezmoiexternal.toml.tmpl # TPM + other externals
.chezmoiscripts/           # run_once_* and run_onchange_* automation
.chezmoitemplates/         # shared template fragments (brew-path-bootstrap, resolve-tier)
CLAUDE.md                  # this file (ignored from apply)
README.md                  # user-facing docs (ignored from apply)
justfile                   # canonical entry points (test, lint, apply, show-tier, …)
tests/                     # bootstrap + smoke harness driven by `just test*`
dot_*                      # standard chezmoi source
dot_zfunc/                 # hand-written zsh completions for shell-defined commands
private_dot_claude/        # Claude Code user config (SAFE files only — no credentials)
private_dot_gnupg/         # gnupg config (no keys)
private_dot_ssh/           # ssh client config (no private keys)
encrypted_private_dot_gitconfig.local.age  # age-encrypted git includeIf (work email, etc.)
```

## Gotchas and decisions

- **`kanvk/zsh-ssh` in `plugins.toml`** is intentional. It's the user's own fork, public, and is the canonical reference. Don't templatize the github org.
- **`dot_p10k.zsh` (96K)** is kept verbatim. Auto-generated by p10k's config wizard; trying to template it is a losing battle. Users who want their own prompt rerun `p10k configure`.
- **Kali package names drift from Debian/Ubuntu** at the toolchain edges (nodejs, golang, python3-*). The install script is best-effort; Homebrew is the source of truth for anything version-sensitive.
- **broot's symlink target** `~/.local/share/broot/launcher/bash/1` only exists after `broot --install` runs. The `run_once_after_40-broot-install.sh` script must run before any shell reloads `br`.
- **`lazy-lock.json` drifts after `chezmoi apply`.** `nvim --headless +Lazy! restore +qa` can rewrite the lock in place. On the next apply, chezmoi prompts on the destination diff — which hangs in non-TTY runs (containers, CI). `tests/bootstrap.sh` does a `chezmoi apply --force` pre-sync before the no-prompt idempotence check.
- **`+Lazy! restore +qa` and `+AstroUpdate +qa` can deadlock** in lazy.nvim — `+qa` queues immediately while async tasks are mid-flight, occasionally hanging nvim. Both are wrapped in `timeout --kill-after=30s 3m` (apply script for Lazy restore; `vimup` alias for AstroUpdate). A real first-time restore lands around 1–2 min, so 3 min is enough headroom while bailing fast on a true deadlock.
