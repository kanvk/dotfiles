# Top-level recipes for working on this chezmoi repo.
# Run `just -l` for the menu.

# Default recipe: print the list.
default:
    @just --list

# === Tests ===

# Run smoke tests on both distros (~5 min total).
test: test-smoke

# Smoke test on Ubuntu, Kali, or both — fast (~30s each).
test-smoke distro="all":
    ./tests/run.sh {{distro}} smoke

# Full bootstrap test (apt + brew bundle + pipx + cargo + …). SLOW: ~60–120 min per distro.
test-full distro="all":
    ./tests/run.sh {{distro}} full

# Render every .tmpl, sweep for hardcoded refs, validate YAML — no Docker, <5s.
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
