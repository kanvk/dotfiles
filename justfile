# Top-level recipes for working on this chezmoi repo.
# Run `just -l` for the menu.

# Default recipe: print the list.
default:
    @just --list

# === Tests ===
#
# Hierarchy: `lint` is a no-Docker static pass. `test-smoke` applies dotfiles
# inside fresh containers but skips install scripts. `test-full` is a strict
# superset of test-smoke — it also runs the install scripts and verifies the
# toolchain + plugin tree. Run `lint` during dev for fast feedback; run
# `test-smoke` before commit; run `test-full` before merge.

# Smoke test (alias for `test-smoke`).
test: test-smoke

# Apply dotfiles in a fresh container; verify modes, gates, idempotence. Default: ubuntu.
test-smoke distro="ubuntu":
    ./tests/run.sh {{distro}} smoke

# Full bootstrap (apt + brew bundle + uv tool + cargo + ...). Strict superset of test-smoke. Slow.
# Default: ubuntu, since CLAUDE.md's policy is that ubuntu-only is the routine green-light
# bar (kali shares the same install pipeline). Pass `all` for both distros when distro-specific.
test-full distro="ubuntu":
    ./tests/run.sh {{distro}} full

# Render every .tmpl, sweep for hardcoded refs, validate YAML, shellcheck. No Docker.
lint:
    ./tests/lint.sh

# === chezmoi day-to-day ===

# Preview what `chezmoi apply` would change.
diff:
    chezmoi diff

# Apply dotfiles + run the install scripts.
apply:
    chezmoi apply -v

# Apply dotfiles only (skip the install scripts that need sudo / are slow).
apply-dotfiles:
    chezmoi apply --exclude=scripts -v

# Force re-run of all run_onchange scripts (after a `brew upgrade`, package list edit, etc.).
apply-force:
    chezmoi apply --force -v

# Pull and re-apply (canonical "update everything" command on a configured machine).
update:
    chezmoi update -v

# Verify target state matches source (warns if anything has drifted).
verify:
    chezmoi verify

# Re-import the live state of a dotfile back into the source (after editing in place).
re-add target:
    chezmoi re-add {{target}}

# Print the resolved package set for a tier (walks inherits, applies include/exclude).
# Usage: just show-tier minimal | just show-tier full
show-tier name="full":
    @./tests/show-tier.sh {{name}}

# Re-display the post-apply manual-steps checklist (the same one printed by
# run_once_after_98-summary on first apply per machine). Useful for returning
# users who want to revisit what's still to do.
checklist:
    @chezmoi execute-template < .chezmoiscripts/run_once_after_98-summary.sh.tmpl | bash

# Open a shell in the source directory.
cd:
    chezmoi cd

# === Cleanup ===

# Remove built test Docker images (frees ~2 GB).
clean-docker:
    -docker rmi chezmoi-test:kali chezmoi-test:ubuntu 2>/dev/null
    docker image prune -f

# Drop chezmoi's cached state (forces all run_once scripts to re-run on next apply).
clean-state:
    chezmoi state delete-bucket --bucket=scriptState
