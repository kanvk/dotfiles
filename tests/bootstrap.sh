#!/usr/bin/env bash
#
# Runs INSIDE a test container (tests/Dockerfile.{kali,ubuntu}) to bootstrap
# this chezmoi config from a bind-mounted source dir. Validates that the
# dotfiles apply cleanly on a stock Kali / Ubuntu image.
#
# Usage (run by tests/run.sh, not directly — or via the top-level justfile):
#   bootstrap.sh <smoke|full> [source-dir]
#
# smoke: applies dotfiles only (--exclude=scripts,externals). Validates that
#        templates render, files end up at the right paths with the right
#        modes, identity templating works, OS gates fire, idempotence holds.
# full:  everything smoke does, PLUS runs the install-packages script chain
#        (apt, Homebrew, brew bundle, pipx, npm, cargo via rustup-init, go,
#        bun) and verifies the resulting toolchains + plugin clones.
#
# `just test-full` is a strict superset of `just test-smoke`. There is NO
# need to run smoke before full — but `just lint` (static, no Docker) is
# orthogonal and worth running during local iteration for fast feedback.

set -euo pipefail

MODE="${1:-smoke}"
SOURCE="${2:-/dotfiles}"

if [ ! -d "$SOURCE" ]; then
    echo "FAIL: source dir $SOURCE does not exist (bind mount missing?)" >&2
    exit 1
fi

# --- install chezmoi ---
if ! command -v chezmoi >/dev/null 2>&1; then
    echo "==> Installing chezmoi"
    sudo sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin
fi
chezmoi --version

# --- pre-populate config so init does NOT prompt (no TTY in CI/container) ---
mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
# `encryption = "age"` declares the suffix so chezmoi can resolve destination
# paths for encrypted_*.age source files; no [age] block is needed because
# .chezmoiignore filters those files out before any decryption is attempted
# (encrypt_locals = false). This mirrors what .chezmoi.toml.tmpl emits on a
# fresh real machine where the user did not supply an SSH age identity.
encryption = "age"

[data]
    name              = "Test User"
    email             = "test@example.com"
    gpg_signing_key   = ""
    ssh_age_identity  = ""
    ssh_age_recipient = ""
    encrypt_locals    = false
    is_wsl            = false
    is_debian_like    = true
EOF

# --- apply ---
EXCLUDE_FLAG=""
if [ "$MODE" = "smoke" ]; then
    EXCLUDE_FLAG="--exclude=scripts,externals"
fi
echo "==> chezmoi apply --source=$SOURCE $EXCLUDE_FLAG"
# shellcheck disable=SC2086
chezmoi apply --source="$SOURCE" $EXCLUDE_FLAG -v

# --- validate ---
echo
echo "==> Validating apply"
fail=0
check()      { test "$@" || { echo "  FAIL: test $*"; fail=1; }; }
mode_eq()    { local f="$1" want="$2"; local got; got=$(stat -c '%a' "$f" 2>/dev/null || echo "?"); [ "$got" = "$want" ] || { echo "  FAIL: $f mode is $got, expected $want"; fail=1; }; }
contains()   { grep -qE "$2" "$1" || { echo "  FAIL: $1 missing pattern: $2"; fail=1; }; }
absent()     { ! [ -e "$1" ] || { echo "  FAIL: $1 should not exist (OS gate failed?)"; fail=1; }; }

# --- core dotfiles present ---
check -f "$HOME/.zshrc"
check -f "$HOME/.zshenv"
check -f "$HOME/.zprofile"
check -f "$HOME/.profile"
check -f "$HOME/.gitconfig"
check -f "$HOME/.tmux.conf"
check -f "$HOME/.p10k.zsh"

# --- ~/.config tree ---
check -d "$HOME/.config/zsh/omz-custom"
check -f "$HOME/.config/zsh/omz-custom/alias.zsh"
check -f "$HOME/.config/zsh/omz-custom/export.zsh"
check -f "$HOME/.config/zsh/omz-custom/forgit.zsh"
check -f "$HOME/.config/zsh/omz-custom/nv_hpc.zsh"
check -f "$HOME/.config/zsh/omz-custom/plugin.zsh"
check -f "$HOME/.config/zsh/omz-custom/sesh.zsh"
check -f "$HOME/.config/sheldon/plugins.toml"
check -f "$HOME/.config/btop/btop.conf"
check -f "$HOME/.config/lazygit/config.yml"
check -f "$HOME/.config/gh-dash/config.yml"
check -f "$HOME/.config/bottom/bottom.toml"
check -f "$HOME/.config/cheat/conf.yml"
check -f "$HOME/.config/hatch/config.toml"
check -f "$HOME/.config/pgcli/config"
check -f "$HOME/.config/git/attributes"
check -f "$HOME/.config/nvim/init.lua"
check -f "$HOME/.config/nvim/lazy-lock.json"
check -f "$HOME/.config/zellij/config.kdl"
check -f "$HOME/.config/act/actrc"
check -f "$HOME/.config/broot/conf.hjson"

# --- private/secure files ---
check -f "$HOME/.ssh/config"
check -d "$HOME/.gnupg"
check -f "$HOME/.gnupg/gpg-agent.conf"
check -f "$HOME/.claude/settings.json"
check -f "$HOME/.claude/statusline.sh"

# --- file modes (private_ prefix in source → 0700 dirs / 0600 files) ---
mode_eq "$HOME/.ssh"                      700
mode_eq "$HOME/.ssh/config"               600
mode_eq "$HOME/.gnupg"                    700
mode_eq "$HOME/.claude"                   700
mode_eq "$HOME/.config/hatch/config.toml" 600
# (.claude/settings.json itself is 0644 — settings, not a secret. Parent dir is 0700.)

# --- shell init scripts have valid zsh syntax ---
zsh -n "$HOME/.zshrc"    || { echo "  FAIL: .zshrc has zsh syntax errors";    fail=1; }
zsh -n "$HOME/.zshenv"   || { echo "  FAIL: .zshenv has zsh syntax errors";   fail=1; }
zsh -n "$HOME/.zprofile" || { echo "  FAIL: .zprofile has zsh syntax errors"; fail=1; }

# --- gitconfig has correct templated identity ---
contains "$HOME/.gitconfig" '^	name = Test User$'
contains "$HOME/.gitconfig" '^	email = test@example.com$'
# gpg_signing_key was empty in init → commit.gpgsign should be false
contains "$HOME/.gitconfig" '^	gpgsign = false$'

# --- ZSH_CUSTOM points to new omz-custom location ---
contains "$HOME/.zshrc" 'ZSH_CUSTOM=.*\.config/zsh/omz-custom'

# --- gpg-agent.conf has pinentry-program directive ---
contains "$HOME/.gnupg/gpg-agent.conf" '^pinentry-program /'

# --- SSH config preserves key entries ---
contains "$HOME/.ssh/config" '^Host github\.com$'
contains "$HOME/.ssh/config" '^Include ~/.ssh/config\.local'
contains "$HOME/.ssh/config" '^Include ~/.ssh/config\.machine'
# encrypt_locals=false in the test container, so the encrypted GHE alias is
# ignored and ~/.ssh/config.local should NOT exist.
absent "$HOME/.ssh/config.local"
absent "$HOME/.gitconfig.local"

# --- Claude statusline command is templated to actual home dir, not /home/kanvk ---
contains "$HOME/.claude/settings.json" "bash $HOME/\.claude/statusline\.sh"

# --- OS-gated files: WSL-only file should NOT exist (is_wsl=false) ---
absent "$HOME/.config/zsh/omz-custom/wsl.zsh"

# --- OS-gated dirs: dot_config/windows/** should NOT be applied on Linux ---
absent "$HOME/.config/windows"

# --- chezmoi-source-only files should NOT have been applied ---
absent "$HOME/README.md"
absent "$HOME/CLAUDE.md"
absent "$HOME/justfile"
absent "$HOME/tests"

# --- no /home/kanvk leakage anywhere in the rendered files ---
if grep -rl '/home/kanvk' "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.profile" \
    "$HOME/.config/zsh" "$HOME/.gitconfig" "$HOME/.claude" 2>/dev/null \
    | grep -v 'CLAUDE.md' | head -1 | grep .; then
    echo "  FAIL: hardcoded /home/kanvk leaked into rendered files"
    fail=1
fi

# --- the example file (kept in source as docs) should NOT be applied ---
absent "$HOME/.ssh/config.machine.example"

# --- full mode: validate the install pipeline outputs ---
if [ "$MODE" = "full" ]; then
    echo
    echo "==> Validating full-mode install outcomes"

    # Source the brew shellenv so the rest of this script sees brew + cargo + go + npm
    if   [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x /opt/homebrew/bin/brew ]; then              eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    [ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

    command -v brew     >/dev/null 2>&1 || { echo "  FAIL: brew not on PATH"; fail=1; }
    command -v sheldon  >/dev/null 2>&1 || { echo "  FAIL: sheldon not installed"; fail=1; }
    command -v nvim     >/dev/null 2>&1 || { echo "  FAIL: nvim not installed"; fail=1; }
    command -v atuin    >/dev/null 2>&1 || { echo "  FAIL: atuin not installed"; fail=1; }
    command -v cargo    >/dev/null 2>&1 || { echo "  FAIL: cargo not on PATH (rustup-init didn't run?)"; fail=1; }
    command -v go       >/dev/null 2>&1 || { echo "  FAIL: go not installed"; fail=1; }
    command -v npm      >/dev/null 2>&1 || { echo "  FAIL: npm not installed (node missing)"; fail=1; }
    command -v bun      >/dev/null 2>&1 || { echo "  FAIL: bun not installed"; fail=1; }

    # cargo packages should now be installed (rust uutils for the alias.zsh aliases)
    command -v coreutils >/dev/null 2>&1 || { echo "  FAIL: rust uutils 'coreutils' not on PATH (alias.zsh fallbacks broken)"; fail=1; }

    # Plugin managers ran their post-install steps
    [ -d "$HOME/.tmux/plugins/tpm" ] || { echo "  FAIL: TPM not cloned"; fail=1; }
    [ -d "$HOME/.local/share/sheldon/repos" ] || { echo "  FAIL: sheldon never ran (no plugin clones)"; fail=1; }

    # Completion regen produced files
    [ -f "$HOME/.zfunc/_chezmoi" ] || { echo "  FAIL: ~/.zfunc/_chezmoi not regenerated"; fail=1; }
    [ -f "$HOME/.zfunc/_just"    ] || { echo "  FAIL: ~/.zfunc/_just not regenerated"; fail=1; }
    [ -f "$HOME/.zfunc/_poetry"  ] || { echo "  FAIL: ~/.zfunc/_poetry not regenerated"; fail=1; }
fi

# --- idempotence ---
echo
echo "==> Testing idempotence (re-apply files should be a no-op)"
# Always exclude scripts/externals on the re-apply check — full-mode scripts
# emit their content in -v output, which would otherwise look like file diffs.
# We're testing that *file* state is idempotent; script-rerun behaviour is
# tested separately by their respective onchange-hash invariants.
#
# Full mode runs `nvim --headless +Lazy! restore +qa` which can rewrite
# `~/.config/nvim/lazy-lock.json` in place — chezmoi then sees a "destination
# changed since I last wrote it" prompt that hangs in non-TTY runs. Do a
# preliminary `--force` apply that quietly resets lazy-lock.json (and any
# similar Lazy-modified state) back to source. THEN run the real idempotence
# check: a non-force apply that should be a true no-op.
chezmoi apply --force --source="$SOURCE" --exclude=scripts,externals > /dev/null 2>&1 || true

# `if !` keeps `set -e` from silently aborting on a non-zero apply exit;
# we want the underlying error visible.
if ! chezmoi apply --source="$SOURCE" --exclude=scripts,externals -v > /tmp/reapply.log 2>&1; then
    echo "  FAIL: idempotence re-apply errored:"
    tail -40 /tmp/reapply.log | sed 's/^/    /'
    fail=1
elif grep -qE '^[+-][^+-]' /tmp/reapply.log; then
    echo "  FAIL: re-apply attempted to write changes:"
    grep -E '^[+-][^+-]' /tmp/reapply.log | head -20
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo
    echo "✓ Bootstrap test PASSED (mode: $MODE, source: $SOURCE)"
else
    echo
    echo "✗ Bootstrap test FAILED"
    exit 1
fi
