#!/usr/bin/env bash
#
# Top-level Docker test runner. Builds + runs bootstrap.sh inside Kali / Ubuntu
# containers against the local working tree (mounted read-only at /dotfiles).
#
# Usage:
#   ./test/run.sh <kali|ubuntu|all> [smoke|full]
#
# smoke (default): chezmoi apply with --exclude=scripts,externals (~30s).
#                   Verifies templates render and dotfiles + identity templating
#                   work. Tests idempotence on re-apply.
# full:            full bootstrap including the install-packages chain (~60-120m).
#                   Real validation of the install script — installs Homebrew,
#                   brew bundle, pipx, etc. inside the container.

set -euo pipefail

cd "$(dirname "$0")"
TEST_DIR="$(pwd)"
REPO_ROOT="$(cd .. && pwd)"

usage() {
    sed -n '/^# Usage/,/^$/p' "$0" | sed 's/^# \?//' >&2
}

build() {
    local distro="$1"
    echo "==> Building chezmoi-test:$distro"
    docker build --quiet -t "chezmoi-test:$distro" -f "$TEST_DIR/Dockerfile.$distro" "$TEST_DIR"
}

run() {
    local distro="$1" mode="$2"
    echo
    echo "================================================================"
    echo "  Running bootstrap test: $distro / $mode"
    echo "================================================================"
    docker run --rm \
        -v "$REPO_ROOT":/dotfiles:ro \
        "chezmoi-test:$distro" \
        bash -c "/dotfiles/test/bootstrap.sh '$mode' /dotfiles"
}

DISTRO="${1:-}"
MODE="${2:-smoke}"

case "$DISTRO" in
  kali|ubuntu)
    build "$DISTRO"
    run "$DISTRO" "$MODE"
    ;;
  all)
    for d in kali ubuntu; do
      build "$d"
      run "$d" "$MODE"
    done
    echo
    echo "✓ All bootstrap tests passed"
    ;;
  *)
    usage
    exit 1
    ;;
esac
