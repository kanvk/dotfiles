# CLAUDE.md — chezmoi dotfiles

Living notes for Claude (and future humans) working on this repo.

## What this repo is

`chezmoi` source for the author's dotfiles. Bootstrap on a new machine with:

```
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kanvk
```

See `README.md` for the user-facing version of the same story.

## Hard invariants

- **Repo is public** (temporarily private during the 2026-04 refactor). Never commit plaintext secrets, OAuth tokens, API keys, signed JWTs, or private SSH keys. Machine-local secrets belong at `~/.config/zsh/omz-custom/hidden.zsh`, which is gitignored and sourced by OMZ at shell start. This file must never move into the chezmoi source tree.
- **OS scope:** Officially supports Kali (WSL2) and Ubuntu (native or WSL2). macOS is not targeted; don't add macOS-specific branches unless they're free (no added complexity). Windows-native configs (`dot_config/windows/**`, including Windows Terminal `settings.json`) are kept in the source tree but excluded from apply on non-Windows machines — the user moves them manually on a Windows box (see `dot_config/windows/terminal/README.md`).
- **Routine testing uses Ubuntu only.** Kali and Ubuntu are functionally equivalent for this repo's purposes (both are `is_debian_like`, both go through the same nala+brew install pipeline). If `just test-full ubuntu` passes, kali is assumed to also pass — don't burn the cycles on both unless you've changed something distro-specific (e.g. apt package names that drift on kali, kali-specific gates). `just test-full kali` and `just test-full all` remain available for the rare distro-specific fix.
- **`is_debian_like` covers all three:** Debian's `ID=debian`, Ubuntu's `ID=ubuntu`, Kali's `ID=kali` + `ID_LIKE=debian`. Branch on this, not on a single distro id.
- **`hidden.zsh` invariant:** never put secrets inside the chezmoi source tree, even if excluded. The whole idea of this refactor is that the source tree is safe to publish.

## Conventions

- **Path templating:** prefer `$HOME` in shell contexts (the shell expands at runtime, template stays portable), use `{{ .chezmoi.homeDir }}` in non-shell contexts (Nix, JSON, Lua, symlink targets).
- **Identity templating:** `{{ .name }}`, `{{ .email }}` — seeded by `promptStringOnce` in `.chezmoi.toml.tmpl`.
- **OS gates:**
  - `{{ if .is_wsl }}` for WSL-only blocks (derived from `.chezmoi.kernel.osrelease` containing `microsoft` OR `$WSL_DISTRO_NAME` set).
  - `{{ if .is_debian_like }}` for apt logic.
  - `{{ ne .chezmoi.os "windows" }}` for excluding `dot_config/windows/**` on apply (in `.chezmoiignore.tmpl`).
- **Soft-detect optional tools:** for Spack, Miniforge/conda, mamba, NVIDIA HPC SDK, pyenv — wrap in `[[ -d … ]]` or `[[ -x $(command -v …) ]]` checks so the config is inert when the tool isn't installed. The user keeps the config in-tree so it "just works" the moment the tool arrives.
- **Plugin installs are delegated to their native managers:** sheldon owns `~/.local/share/sheldon/repos/**` (don't vendor it); tpm owns `~/.tmux/plugins/**`; lazy.nvim owns `~/.local/share/nvim/lazy/**`; Mason owns LSP servers. Our `.chezmoiscripts/` just kick these off.
- **apt is via nala when available.** The install script bootstraps nala via apt-get on first run, then uses nala (parallel downloads, nicer UI) for everything subsequent. Falls back to apt-get if nala is unavailable.
- **Package lists in `.chezmoidata.yaml` are user intent, not exclusivity.** The install pipeline is **additive only** — `chezmoi apply` ensures listed packages are installed but never uninstalls anything missing from the list. If the user `brew install`s something ad-hoc, a later apply leaves it alone. Concretely: brew bundle runs without `--cleanup`; nala/apt-get use `install`, never `purge`/`autoremove`; pipx/cargo/go/npm/bun/gh-extension steps only install or upgrade. To prune, the user runs the manager's cleanup directly (`brew bundle cleanup --file=<bundle>`, `nala autoremove`, …) — chezmoi never does it. When installing a new tool the user wants on every machine, add it to the list — don't expect the install script to re-snapshot from the system.
- **Tier-based package selection.** `.chezmoidata.yaml` is structured as `tiers: { <name>: { inherits: [...], include: { <mgr>: [...] }, exclude: { <mgr>: [...] } } }`. The user's `.tier` data var (set in `~/.config/chezmoi/chezmoi.toml`, prompted at init, default `full`) selects which tier to resolve. Resolution = walk inherits, union per-manager `include`s, subtract per-manager `exclude`s. **Excludes are eager**: a child of a tier that excludes X starts without X; this is what makes a `full-without-foo`-style sibling tier expressible. Resolver lives in `.chezmoitemplates/resolve-tier`; `just show-tier <name>` prints the resolved set for any tier. **`exclude` does not uninstall** — per the additivity bullet above, it just means "don't install henceforth." Switching `full → minimal` on an existing machine leaves the previously-installed extras in place; manual `brew bundle cleanup` etc. is the only way to actually shrink the system.
- **Completion files are regenerated, not vendored.** Do not commit `dot_zfunc/_poetry`, `_rustup`, `_atuin`, etc. The `run_onchange_after_50-regen-completions.sh.tmpl` script handles these.
- **OMZ custom dir lives at `dot_config/zsh/omz-custom/`** (not inside sheldon's cache). The user's `dot_zshrc` sets `ZSH_CUSTOM` to that path. Preserve the `plugins/` and `themes/` subtree structure.
- **`run_onchange_after_*` scripts must include `{{ template "brew-path-bootstrap" . }}`** at the top (right after `set -euo pipefail`). chezmoi runs each script in a fresh subshell — PATH changes from `run_onchange_before_00-install-packages.sh.tmpl` (e.g. `eval "$(brew shellenv)"`) do *not* propagate. Without the template, `command -v sheldon`/`just`/`broot`/etc. silently no-op on first apply. The template lives at `.chezmoitemplates/brew-path-bootstrap` and also adds `~/.cargo/bin`, `~/.local/bin`, `~/go/bin` to PATH.
- **Cargo install runs per-package, tolerantly.** `run_onchange_before_00-install-packages.sh.tmpl` loops one `cargo install` per crate with `|| echo warning…`. A single bad crate (missing system lib, transient compile error) emits a warning but does NOT abort the install pipeline.
- **`~/.cargo/env` and `~/.cargo/bin` are PATH-extended in two places, intentionally.** `dot_zshenv` sources `~/.cargo/env` so non-interactive zsh shells (one-off `zsh -c`, scripted invocations, ssh `command=…`) can find cargo. `.chezmoitemplates/brew-path-bootstrap` separately prepends `~/.cargo/bin` so chezmoi-apply-time `run_onchange_after_*` scripts (which start as fresh subshells, no zshenv sourced) can also find it. Both paths are needed; neither is redundant.
- **Analytics opt-outs at install time, not just shell time.** `HOMEBREW_NO_ANALYTICS`, `HOMEBREW_NO_ENV_HINTS`, `DO_NOT_TRACK` are set at the top of the install script — the user's `export.zsh` only takes effect inside an interactive zsh, which is too late for chezmoi-apply-time installs.

## Layout after refactor

```
.chezmoi.toml.tmpl         # init-time prompts + computed vars
.chezmoidata.yaml          # tiered package lists (apt/brew/pipx/npm/cargo/go/bun/gh-ext)
.chezmoiignore.tmpl        # OS-gated ignores
.chezmoiexternal.toml.tmpl # TPM + other externals
.chezmoiscripts/           # run_once_* and run_onchange_* automation
.chezmoitemplates/         # shared template fragments (brew-path-bootstrap, resolve-tier)
CLAUDE.md                  # this file (ignored from apply)
README.md                  # user-facing docs (ignored from apply)
dot_*                      # standard chezmoi source
private_dot_claude/        # Claude Code user config (SAFE files only — no credentials)
```

## Gotchas and decisions

- **`kanvk/zsh-ssh` in `plugins.toml`** is intentional. It's the user's own fork, public, and is the canonical reference. Don't templatize the github org.
- **`dot_p10k.zsh` (96K)** is kept verbatim. Auto-generated by p10k's config wizard; trying to template it is a losing battle. Users who want their own prompt rerun `p10k configure`.
- **Kali package names drift from Debian/Ubuntu** at the toolchain edges (nodejs, golang, python3-*). The install script is best-effort; Homebrew is the source of truth for anything version-sensitive.
- **broot's symlink target** `~/.local/share/broot/launcher/bash/1` only exists after `broot --install` runs. The `run_once_after_40-broot-install.sh` script must run before any shell reloads `br`.
- **`lazy-lock.json` drifts after `chezmoi apply`.** The Lazy sync script runs `nvim --headless +Lazy! restore +qa`, which can rewrite `~/.config/nvim/lazy-lock.json` in place. On the next apply, chezmoi sees "destination changed since I last wrote it" and prompts — which hangs in non-TTY runs (containers, CI). `tests/bootstrap.sh` works around this by doing a `chezmoi apply --force` pre-sync before the real (no-prompt) idempotence check.
- **`+Lazy! restore +qa` and `+AstroUpdate +qa` can deadlock** in lazy.nvim — `+qa` queues immediately while async tasks are mid-flight, occasionally hanging nvim indefinitely. Both invocations are wrapped in `timeout --kill-after=30s 10m` (the apply script for Lazy restore; the `vimup` alias for AstroUpdate).
