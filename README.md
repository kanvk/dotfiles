# dotfiles

Kanv's dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

Targets **Linux** (including **WSL2** on Windows). macOS is not supported; Windows-native configs (komorebi, yasb, whkd) are kept in the source tree as a reference but are not applied automatically.

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

Answers are saved to `~/.config/chezmoi/chezmoi.toml` and reused on subsequent applies. To re-prompt, delete that file and run `chezmoi init` again.

Prerequisites on a bare system: `curl`, `git`, `sudo` (for the apt install pass on Debian-like distros). Everything else is installed by the apply pipeline.

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

- **Kali-on-WSL2 is the primary dev machine.** The `apt` branch of the install script gates on `is_debian_like` (Debian / Ubuntu / Kali); it's best-effort on non-Kali Debian-likes because Kali package names drift at the toolchain edges (nodejs, golang, python3-*). Homebrew is the source of truth for anything version-sensitive.
- **Research/HPC tools (Spack, Miniforge/conda/mamba, NVIDIA HPC SDK, pyenv)** are soft-detected: the config stays in-tree but the shell startup ignores them unless the tool is actually installed. Just `brew install pyenv` (or install miniforge into `~/miniforge3`, or Spack into `~/.spack`) and open a new shell — no config changes needed.
- **Don't commit to the vendored sheldon cache** at `~/.local/share/sheldon/repos/`. Sheldon manages it; `.chezmoiignore` has a defensive rule.
- **tmux plugin install on first apply** — TPM is cloned but the plugins aren't installed automatically. Open tmux and hit `prefix + I` once.
- **Auto-generated shell completions** (`~/.zfunc/_*`) come from `run_onchange_after_50-regen-completions.sh`. After a major `brew upgrade`, run `chezmoi apply --force` to refresh.
