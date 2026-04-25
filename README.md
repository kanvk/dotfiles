# dotfiles

Kanv's dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

Officially supports **Kali on WSL2** and **Ubuntu** (native or WSL2). macOS is not targeted. Windows-native configs (komorebi, yasb, whkd, Windows Terminal) live in `dot_config/windows/` as a reference but are not applied to Linux home directories.

## Bootstrap a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kanvk
```

On first run, chezmoi prompts for:

| Prompt | Used in |
| --- | --- |
| Full name | `~/.gitconfig` user.name |
| Email | `~/.gitconfig` user.email |
| GitHub username | `~/.gitconfig` insteadOf rules (currently NCSU-only) |
| GPG signing key fingerprint | `~/.gitconfig` user.signingKey; leave blank to disable commit signing |
| SSH key path for age encryption | `~/.config/chezmoi/chezmoi.toml` `[age]` block — leave blank to disable encryption |
| SSH public key string (.pub contents) | recipient for age encryption — only prompted when identity is set |

Answers are saved to `~/.config/chezmoi/chezmoi.toml` and reused on subsequent applies. To re-prompt, delete that file and run `chezmoi init` again.

**Requirements:**
- chezmoi `>= 2.50` (uses `.chezmoiexternal`, `lookPath`, `promptStringOnce`, `[age].identity` with SSH keys). The `get.chezmoi.io` install bootstrap pulls the latest stable.
- On a bare system: `curl`, `git`, `sudo` (only for the apt install pass on Debian-likes — install script bootstraps `nala` and `build-essential` from there).
- Everything else (Homebrew, brew packages, pipx packages, etc.) is installed by the apply pipeline.

## What chezmoi does on first apply

1. Renders `.chezmoi.toml.tmpl` with your answers to derive identity + OS flags (`is_wsl`, `is_debian_like`).
2. Applies dotfiles (`~/.zshrc`, `~/.tmux.conf`, `~/.config/**`, etc.) — skipping the `dot_config/windows/**` tree on non-Windows and `dot_config/zsh/omz-custom/wsl.zsh` off WSL.
3. Pulls [TPM](https://github.com/tmux-plugins/tpm) via `.chezmoiexternal.toml.tmpl`.
4. Runs `.chezmoiscripts/` in order:
   - `run_onchange_before_00-install-packages.sh.tmpl` — `apt-get install` (Debian-like only), install Homebrew, `brew install` the curated list from `.chezmoidata.yaml`, plus pipx/npm/cargo/go/bun packages.
   - `run_onchange_after_10-sheldon-lock.sh.tmpl` — `sheldon lock --update` (fires on `plugins.toml` edits).
   - `run_onchange_after_30-nvim-lazy-sync.sh.tmpl` — `nvim --headless "+Lazy! restore" +qa` (fires on `lazy-lock.json` edits).
   - `run_onchange_after_40-broot-install.sh.tmpl` — `broot --install` to create the shell launcher (fires when broot goes from absent to present).
   - `run_onchange_after_50-regen-completions.sh.tmpl` — regenerates `~/.zfunc/_*` from each tool's native completion generator.

Subsequent applies are fast: `run_onchange_*` scripts only re-run when their source content (or an embedded trigger hash) changes.

The apt-pass uses `nala` once it's installed (better progress UI + parallel downloads); the script bootstraps nala via `apt-get` on the first run.

## After-apply checklist

Things `chezmoi apply` cannot do automatically — do these once on a new machine. The `run_once_after_99-summary.sh` script also prints this list to your terminal on the first apply so you don't need to re-read this file.

1. **Drop in machine-local secrets**, if needed:
   ```sh
   cat > ~/.config/zsh/omz-custom/hidden.zsh <<'EOF'
   # export LOCALSTACK_AUTH_TOKEN=...
   # export ANTHROPIC_AUTH_TOKEN=...
   EOF
   chmod 600 ~/.config/zsh/omz-custom/hidden.zsh
   ```
   This file is sourced by OMZ at shell start. It lives **outside** the chezmoi source tree by design — the source is public.

2. **Personal SSH hosts** — the tracked `~/.ssh/config` only has universal entries (Host *, github.com, github.com-ghe) and an `Include ~/.ssh/config.local` directive. Per-machine hosts (lab boxes, home network, internal `*.priv` hosts) go in `~/.ssh/config.local` so they don't leak into the public repo.

   **If you're migrating from an existing setup with personal hosts in `~/.ssh/config` already, do this BEFORE you `chezmoi apply` — apply will overwrite `~/.ssh/config`:**
   ```sh
   # Extract everything except the universal Hosts into config.local
   awk '
     BEGIN { keep=0; buf="" }
     /^Host / {
       if (keep && buf) print buf; buf=""
       keep = !($0 ~ /^Host \*$/ || $0 ~ /^Host github\.com$/ || $0 ~ /^Host github\.com-ghe$/)
     }
     { if (keep) buf = buf $0 ORS }
     END { if (keep && buf) print buf }
   ' ~/.ssh/config > ~/.ssh/config.local
   chmod 600 ~/.ssh/config.local
   ```
   See `~/.ssh/config.local.example` (chezmoi-applied) for a starter template.

3. **Authenticate the GitHub CLI**: `gh auth login`. The gitconfig credential helper (`!gh auth git-credential`) routes git pushes through gh's token store.

4. **Set up apprise notifications** (optional), if you use them: drop URLs into `~/.config/apprise` (one per line; tags via `tag=url://...`). This file is **not** chezmoi-managed because the URLs are bearer secrets.

5. **Install a Nerd Font** if your terminal uses CaskaydiaCove (the default in Windows Terminal and in `dot_p10k.zsh`). On Windows: `winget install Microsoft.CascadiaCode` + manually download CaskaydiaCove from [Nerd Fonts](https://www.nerdfonts.com/font-downloads). On Linux, the font is rendered by the host terminal — install via your platform's font manager.

6. **(Windows host only) Apply Windows-side configs**: chezmoi extracts `dot_config/windows/**` to `%USERPROFILE%\.config\windows\` but does not move things into their canonical Windows locations. See `dot_config/windows/terminal/README.md` for the Windows Terminal copy/symlink procedure; do similar for komorebi (`%USERPROFILE%\.config\komorebi`), yasb (`%USERPROFILE%\.config\yasb`), and whkdrc.

7. **(Optional research/HPC tools)** — Spack, Miniforge/conda/mamba, and the NVIDIA HPC SDK are soft-detected by the shell init. To activate them, just install them at their canonical locations (`~/.spack`, `~/miniforge3`, `/opt/nvidia/hpc_sdk`) and open a new shell. No config changes needed.

8. **(Optional) Encrypt a file with age** — if you provided an SSH identity at init, chezmoi is wired for age encryption:
   ```sh
   chezmoi add --encrypt ~/.netrc       # or any file you want versioned + encrypted
   chezmoi edit ~/.netrc                # round-trips through age + $EDITOR
   ssh-add ~/.ssh/personal              # so apply doesn't ask for the SSH passphrase each time
   ```
   No secrets are committed by default; encryption is per-file and opt-in.

Tmux plugins are installed automatically by `run_onchange_after_60-tmux-plugins.sh` — no need to press `prefix + I` unless you add new plugins.

## Editing packages

Edit `.chezmoidata.yaml`, keyed by manager (`apt`, `brew`, `pipx`, `npm`, `cargo`, `go`, `bun`). The next `chezmoi apply` detects the hash change and re-runs the install script.

```sh
chezmoi edit .chezmoidata.yaml      # edits in the source
chezmoi apply                       # or chezmoi apply --force to re-run everything
```

## Machine-local secrets

This repo is public. Any file containing a secret (API key, OAuth token, webhook URL, GPG identity material, etc.) must live **outside** the chezmoi source tree.

Convention for shell-sourced secrets: `~/.config/zsh/omz-custom/hidden.zsh` — OMZ auto-sources it (via `ZSH_CUSTOM=$HOME/.config/zsh/omz-custom` in `.zshrc`). Create it directly on each machine; never add it to chezmoi.

```sh
cat > ~/.config/zsh/omz-custom/hidden.zsh <<'EOF'
export LOCALSTACK_AUTH_TOKEN=...
export SOME_API_KEY=...
EOF
chmod 600 ~/.config/zsh/omz-custom/hidden.zsh
```

Other per-machine credentials that are managed by their tools (not chezmoi):

- `~/.config/apprise` — notification webhook URLs
- `~/.config/gh/hosts.yml` — GitHub CLI auth tokens (managed by `gh auth login`)
- `~/.ssh/` — SSH keys (managed by you)

## Common tasks

```sh
chezmoi cd                        # open a shell in the source dir (/home/$USER/.local/share/chezmoi)
chezmoi diff                      # preview changes before applying
chezmoi apply                     # apply
chezmoi apply --force             # re-run run_onchange scripts unconditionally
chezmoi re-add ~/.zshrc           # after editing a dotfile in-place, bring the change into the source
chezmoi edit ~/.gitconfig         # edit the template in the source dir
chezmoi update                    # git pull + apply
chezmoi verify                    # assert target state matches source
```

## Layout

```
.chezmoi.toml.tmpl            # init-time prompts + computed is_wsl/is_debian_like
.chezmoidata.yaml             # package lists consumed by install script
.chezmoiignore.tmpl           # OS-gated ignores (Windows configs off Linux, wsl.zsh off WSL, etc.)
.chezmoiexternal.toml.tmpl    # TPM (tmux plugin manager)
.chezmoiscripts/              # run_* automation (install packages, sheldon lock, Lazy sync, broot, completions)
CLAUDE.md                     # notes for Claude/future humans (ignored from apply)
README.md                     # this file (ignored from apply)
dot_zshrc, dot_tmux.conf, …   # standard chezmoi source entries
dot_config/…                  # user app configs (git, nvim, btop, lazygit, …)
dot_config/zsh/omz-custom/    # OMZ custom dir (referenced by ZSH_CUSTOM in .zshrc)
dot_config/windows/           # Windows-native configs — NOT applied on Linux
private_dot_claude/           # Claude Code user config (mode 0600 on apply)
```

## Notes

- **Kali on WSL2 and Ubuntu are the supported targets.** The `apt` branch gates on `is_debian_like` (also catches Debian itself). Homebrew is the source of truth for anything version-sensitive — apt only handles dev-essentials, build deps for pyenv, and a handful of system tools.
- **Research/HPC tools (Spack, Miniforge/conda/mamba, NVIDIA HPC SDK, pyenv)** are soft-detected: the config stays in-tree but the shell startup ignores them unless the tool is actually installed. Just `brew install pyenv` (or install miniforge into `~/miniforge3`, or Spack into `~/.spack`) and open a new shell — no config changes needed.
- **Don't commit to the vendored sheldon cache** at `~/.local/share/sheldon/repos/`. Sheldon manages it; `.chezmoiignore` has a defensive rule.
- **tmux plugin install on first apply** — TPM is cloned but the plugins aren't installed automatically. Open tmux and hit `prefix + I` once.
- **Auto-generated shell completions** (`~/.zfunc/_*`) come from `run_onchange_after_50-regen-completions.sh`. After a major `brew upgrade`, run `chezmoi apply --force` to refresh.
