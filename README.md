# dotfiles

Kanv's dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

Officially supports **Kali on WSL2** and **Ubuntu** (native or WSL2). macOS is not targeted. Windows-native configs (komorebi, yasb, whkd, Windows Terminal) live in `dot_config/windows/` and apply to `~/.config/windows/` on every host — inert off Windows; on a Windows box the user copies them into their canonical locations manually.

## Bootstrap a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kanvk
```

On first run, chezmoi prompts for:

| Prompt | Used in |
| --- | --- |
| Name | `~/.gitconfig` user.name |
| Email | `~/.gitconfig` user.email |
| Package tier (minimal \| base \| full) | which package set to install (see [Package tiers](#package-tiers) below); default `full` |
| Sign git commits with GPG? | yes/no gate; only prompts for the fingerprint below if yes |
| GPG signing key fingerprint | `~/.gitconfig` user.signingKey; only prompted when GPG signing is enabled |
| SSH key path for age encryption | `~/.config/chezmoi/chezmoi.toml` `[age]` block — leave blank to disable encryption |
| SSH public key string (.pub contents) | recipient for age encryption — only prompted when identity is set |
| Apply encrypted personal locals? | gates the encrypted-tracked `~/.gitconfig.local` and `~/.ssh/config.local` files; only prompted when an age identity is set |

Answers are saved to `~/.config/chezmoi/chezmoi.toml` and reused on subsequent applies. To re-prompt, delete that file and run `chezmoi init` again.

### Package tiers

The bootstrap installs one of three nested tiers (full ⊇ base ⊇ minimal):

- **minimal** — shell, git, and a handful of CLI niceties (`bat`, `eza`, `fd`, `fzf`, `ripgrep`, `zoxide`, `gh`, `jq`, `lazygit`, `delta`). Suitable for disposable boxes, shared servers, or short-lived containers.
- **base** — minimal **plus** daily-driver dev tooling: build deps, language toolchains (rustup, go, node, python via pyenv/uv/pipx), starship, TUIs (broot, lsd, yazi, btop, lazydocker), secret-scanners (ggshield, gitleaks). Default for personal dev machines.
- **full** — base **plus** ML/specialty/heavy tools (`llama.cpp`, `ollama`, `vllm`, `wandb`, `caddy`, `duckdb`, `keydb`, `rclone`, `pixi`, `typst`, `uuu` prereqs). Default at the prompt; the user's main box runs this.

Inspect resolved sets with `just show-tier <name>`. Switch tiers by editing `tier = "..."` in `~/.config/chezmoi/chezmoi.toml` and re-applying. Downgrades don't uninstall — extras stay until you run the package manager's cleanup yourself.

**Requirements:** chezmoi `>= 2.50`, plus `curl`, `git`, `sudo` on a bare system. Homebrew and everything else is installed by the apply pipeline.

## What chezmoi does on first apply

1. Renders templates with your init answers and applies dotfiles to `$HOME`.
2. Installs system packages (apt on Debian-likes, then Homebrew + pipx/npm/cargo/go/bun) per your tier.
3. Syncs plugin managers (sheldon, lazy.nvim, tpm, broot) and regenerates shell completions.

Subsequent applies are fast — only the dotfiles or scripts whose source has changed get re-run.

## Before the first apply (encrypted-locals only)

If you opted into `encrypt_locals` at init, the matching age identity must be on disk at the path you gave (e.g. `~/.ssh/chezmoi`) **before** the first `chezmoi apply` — otherwise decryption fails. Order on a fresh machine: copy SSH key in → `chezmoi init --apply kanvk`.

If you don't need the encrypted locals (e.g. cloning as someone other than the owner), leave `encrypt_locals=false` and apply skips them.

## After-apply checklist

Things `chezmoi apply` cannot do automatically — do these once on a new machine. `run_once_after_98-summary.sh` also prints this list on first apply; re-display any time with `just checklist`.

1. **Drop in machine-local secrets**, if needed:
   ```sh
   cat > ~/.config/zsh/omz-custom/hidden.zsh <<'EOF'
   # export LOCALSTACK_AUTH_TOKEN=...
   # export ANTHROPIC_AUTH_TOKEN=...
   EOF
   chmod 600 ~/.config/zsh/omz-custom/hidden.zsh
   ```
   OMZ sources this at shell start. It lives **outside** the chezmoi source tree by design — the source is public.

2. **Personal SSH hosts** — the tracked `~/.ssh/config` has only `Host *` and `Host github.com` plus two `Include` directives:
   - `~/.ssh/config.local` — encrypted-tracked when `encrypt_locals=true`; portable entries (e.g. the `github.com-ghe` alias).
   - `~/.ssh/config.machine` — unmanaged, **per-machine**; non-portable entries (lab boxes, LAN IPs, `*.priv` hosts). See `~/.ssh/config.machine.example` for a starter.

   ssh silently no-ops on missing includes, so it's safe to leave both directives in.

   **Migrating from an existing `~/.ssh/config` with personal hosts? Do this BEFORE `chezmoi apply` (it overwrites `~/.ssh/config`):**
   ```sh
   # Extract per-machine, non-portable hosts into config.machine
   awk '
     BEGIN { keep=0; buf="" }
     /^Host / {
       if (keep && buf) print buf; buf=""
       keep = !($0 ~ /^Host \*$/ || $0 ~ /^Host github\.com$/)
     }
     { if (keep) buf = buf $0 ORS }
     END { if (keep && buf) print buf }
   ' ~/.ssh/config > ~/.ssh/config.machine
   chmod 600 ~/.ssh/config.machine
   ```

3. **Authenticate the GitHub CLI**: `gh auth login`. The gitconfig credential helper (`!gh auth git-credential`) routes git pushes through gh's token store.

4. **Set up apprise notifications** (optional), if you use them: drop URLs into `~/.config/apprise` (one per line; tags via `tag=url://...`). This file is **not** chezmoi-managed because the URLs are bearer secrets.

5. **Install a Nerd Font** if your terminal uses CaskaydiaCove (the Windows Terminal + `dot_p10k.zsh` default). Windows: `winget install Microsoft.CascadiaCode` + grab CaskaydiaCove from [Nerd Fonts](https://www.nerdfonts.com/font-downloads). Linux: install via your platform's font manager.

6. **(Windows host only) Apply Windows-side configs**: chezmoi extracts `dot_config/windows/**` to `%USERPROFILE%\.config\windows\` but doesn't move things to their canonical Windows locations. See `dot_config/windows/terminal/README.md` for Windows Terminal; do similar for komorebi (`%USERPROFILE%\.config\komorebi`), yasb (`%USERPROFILE%\.config\yasb`), and whkdrc.

7. **(WSL host only) Install `win32yank` on the Windows host** for the WSL clipboard bridge — Neovim's `plugins/wsl_clipboard.lua` and the `cscw`/`vscw` zsh aliases shell out to `win32yank.exe`. Install with `scoop install win32yank` or `winget install equalsraf.win32yank`. Without it, clipboard copy/paste between WSL and Windows silently no-ops.

8. **(Optional research/HPC tools)** — Spack, Miniforge/conda/mamba, NVIDIA HPC SDK are soft-detected. Install at canonical locations (`~/.spack`, `~/miniforge3`, `/opt/nvidia/hpc_sdk`) and open a new shell.

9. **(Optional) Encrypt a file with age** — if you set an SSH identity at init:
   ```sh
   chezmoi add --encrypt ~/.netrc       # versioned + encrypted
   chezmoi edit ~/.netrc                # round-trips through age + $EDITOR
   ```
   Note: if your SSH key is passphrase-protected, every apply that touches an `.age` file prompts for it (age reads the key directly, bypassing ssh-agent). Either drop the passphrase on the chezmoi-only key or switch to a native age identity (`age-keygen`).

## Editing packages

Edit `.chezmoidata.yaml`, keyed by manager (`apt`, `brew`, `pipx`, `npm`, `cargo`, `go`, `bun`). The next `chezmoi apply` detects the hash change and re-runs the install script.

```sh
chezmoi edit .chezmoidata.yaml      # edits in the source
chezmoi apply                       # or chezmoi apply --force to re-run everything
```

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

