#!/usr/bin/env bash
#
# Static lint pass — no Docker required, runs locally.
# Renders every *.tmpl, sweeps for hardcoded paths/identity, validates
# .chezmoidata.yaml is valid YAML and runs shellcheck on .chezmoiscripts/.
# Orthogonal to the bootstrap tests — run during dev iteration.
#
# Run via `just lint`.

set -uo pipefail   # -e off intentionally — each step handles its own errors

cd "$(dirname "$0")/.."
fail=0

echo "==> 1. Rendering every *.tmpl"
while IFS= read -r f; do
    if out=$(chezmoi execute-template < "$f" 2>&1); then
        continue
    fi
    # .chezmoi.toml.tmpl uses promptStringOnce which only resolves during
    # `chezmoi init`; plain execute-template can't render it. Treat as ok.
    if [[ "$(basename "$f")" = ".chezmoi.toml.tmpl" ]] && echo "$out" | grep -q 'promptStringOnce'; then
        continue
    fi
    echo "  FAIL: $f"
    echo "$out" | head -3 | sed 's/^/    /'
    fail=1
done < <(find . -name '*.tmpl' -not -path './.git/*' -not -path './tests/*')

echo "==> 2. Hardcoded-ref sweep"
hits=$(rg -n 'kanvk|/home/kanvk|kkhare|linuxbrew|pyenv/shims' --no-heading \
    --glob '!CLAUDE.md' --glob '!README.md' --glob '!tests/**' --glob '!.git/**' \
    --glob '!dot_p10k.zsh' --glob '!justfile' \
    --glob '!dot_config/windows/**' \
    2>/dev/null)
# Filter out the known-intentional hits
unexpected=$(echo "${hits:-}" | grep -vE \
    -e '^$' \
    -e 'dot_zprofile:.*linuxbrew' \
    -e 'dot_config/zsh/omz-custom/export\.zsh:.*linuxbrew' \
    -e 'dot_config/sheldon/plugins\.toml:.*kanvk/zsh-ssh' \
    -e 'private_dot_ssh/private_config\.machine\.example:')
if [ -n "$unexpected" ]; then
    echo "  FAIL: unexpected hardcoded references:"
    echo "$unexpected" | head -15 | sed 's/^/    /'
    fail=1
fi

echo "==> 3. .chezmoidata.yaml YAML validity"
if command -v python3 >/dev/null 2>&1; then
    if ! python3 -c 'import yaml,sys; yaml.safe_load(open(".chezmoidata.yaml"))' 2>/dev/null; then
        echo "  FAIL: .chezmoidata.yaml is invalid YAML"
        fail=1
    fi
fi

echo "==> 4. cask: prefix syntax in .chezmoidata.yaml"
# Casks live inline in `brew:` lists with a `cask:` prefix (e.g. `cask:copilot-cli`).
# Catch typos (`Cask:foo`, `cask: foo`, `cask:` with empty name) at lint time
# rather than mid-`brew bundle install`.
if command -v python3 >/dev/null 2>&1; then
    py_out=$(python3 - <<'PYEOF' 2>&1
import re, sys, yaml
strict = re.compile(r"^cask:[A-Za-z0-9._@/-]+$")
suspicious = re.compile(r"^cask\b", re.IGNORECASE)
data = yaml.safe_load(open(".chezmoidata.yaml"))
bad = []
for tier, body in (data.get("tiers") or {}).items():
    for section in ("include", "exclude"):
        for entry in ((body.get(section) or {}).get("brew") or []):
            if suspicious.match(entry) and not strict.match(entry):
                bad.append(f"tiers.{tier}.{section}.brew: {entry!r}")
print("\n".join(bad), end="")
sys.exit(1 if bad else 0)
PYEOF
)
    if [ -n "${py_out:-}" ]; then
        echo "  FAIL: malformed cask entries (expected 'cask:NAME', e.g. 'cask:copilot-cli'):"
        echo "$py_out" | sed 's/^/    /'
        fail=1
    fi
fi

echo "==> 5. .chezmoiscripts/ shellcheck (if installed)"
if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r f; do
        out=$(chezmoi execute-template < "$f" 2>/dev/null)
        if ! echo "$out" | shellcheck --shell=bash --severity=error - >/tmp/shellcheck.out 2>&1; then
            echo "  FAIL (shellcheck): $f"
            head -10 /tmp/shellcheck.out | sed 's/^/    /'
            fail=1
        fi
    done < <(find .chezmoiscripts -name '*.sh.tmpl' -o -name '*.sh' 2>/dev/null)
else
    echo "  (shellcheck not installed — skipping)"
fi

if [ "$fail" -eq 0 ]; then
    echo
    echo "✓ Lint PASSED"
    exit 0
fi
echo
echo "✗ Lint FAILED"
exit 1
