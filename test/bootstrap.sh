#!/usr/bin/env bash
#
# Runs INSIDE a test container (test/Dockerfile.{kali,ubuntu}) to bootstrap
# this chezmoi config from a bind-mounted source dir. Validates that the
# dotfiles apply cleanly on a stock Kali / Ubuntu image.
#
# Usage (run by test/run.sh, not directly):
#   bootstrap.sh <smoke|full> [source-dir]
#
# smoke: applies dotfiles only (--exclude scripts); ~30s. Validates templates
#        render and structure is sane. Does NOT install Homebrew/apt/pipx etc.
# full:  full bootstrap including the install-packages script chain. Slow
#        (~60-120 minutes) but proves the whole pipeline works end-to-end.

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
[data]
    name              = "Test User"
    email             = "test@example.com"
    github_user       = "testuser"
    gpg_signing_key   = ""
    ssh_age_identity  = ""
    ssh_age_recipient = ""
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
echo "==> Validating apply"
fail=0
check() { test "$@" || { echo "  FAIL: test $*"; fail=1; }; }

check -f "$HOME/.zshrc"
check -f "$HOME/.gitconfig"
check -f "$HOME/.zshenv"
check -f "$HOME/.zprofile"
check -f "$HOME/.tmux.conf"
check -d "$HOME/.config/zsh/omz-custom"
check -f "$HOME/.config/zsh/omz-custom/alias.zsh"
check -f "$HOME/.config/zsh/omz-custom/export.zsh"
check -f "$HOME/.config/zsh/omz-custom/nv_hpc.zsh"
check -f "$HOME/.config/sheldon/plugins.toml"
check -f "$HOME/.config/btop/btop.conf"
check -f "$HOME/.config/lazygit/config.yml"
check -f "$HOME/.config/nvim/init.lua"
check -f "$HOME/.ssh/config"
check -d "$HOME/.gnupg"

# Templated values (gitconfig values are unquoted by the user-side convention)
grep -qE '^	name = Test User$'         "$HOME/.gitconfig" || { echo "  FAIL: gitconfig name not templated"; fail=1; }
grep -qE '^	email = test@example.com$' "$HOME/.gitconfig" || { echo "  FAIL: gitconfig email not templated"; fail=1; }
grep -q 'ZSH_CUSTOM='                       "$HOME/.zshrc"     || { echo "  FAIL: ZSH_CUSTOM not set in zshrc"; fail=1; }

# OS-gated files: WSL-only file should NOT exist (is_wsl=false)
if [ -f "$HOME/.config/zsh/omz-custom/wsl.zsh" ]; then
    echo "  FAIL: wsl.zsh applied even though is_wsl=false"
    fail=1
fi

# Identity values from prompts should NOT include 'kanvk' (the source author)
if grep -q '/home/kanvk' "$HOME/.zshrc" "$HOME/.config/zsh/omz-custom/export.zsh" 2>/dev/null; then
    echo "  FAIL: hardcoded /home/kanvk leaked into rendered files"
    fail=1
fi

# Ensure SSH config preserves the github.com-ghe alias for gitconfig
grep -q 'Host github.com-ghe' "$HOME/.ssh/config" || {
    echo "  FAIL: github.com-ghe missing from rendered ~/.ssh/config"
    fail=1
}

# --- idempotence (smoke only — full re-runs install scripts) ---
if [ "$MODE" = "smoke" ]; then
    echo "==> Testing idempotence (re-apply should be a no-op)"
    # shellcheck disable=SC2086
    chezmoi apply --source="$SOURCE" $EXCLUDE_FLAG -v > /tmp/reapply.log 2>&1
    # `-v` shows diff lines starting with `+`/`-`. If any survive, target changed.
    if grep -qE '^[+-][^+-]' /tmp/reapply.log; then
        echo "  FAIL: re-apply attempted to write changes:"
        grep -E '^[+-][^+-]' /tmp/reapply.log | head -20
        fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then
    echo
    echo "✓ Bootstrap test PASSED (mode: $MODE, source: $SOURCE)"
else
    echo
    echo "✗ Bootstrap test FAILED"
    exit 1
fi
