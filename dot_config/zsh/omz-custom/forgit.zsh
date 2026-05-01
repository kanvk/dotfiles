export FORGIT_FZF_DEFAULT_OPTS="
  --multi
  --bind 'tab:toggle+down'
  --bind 'shift-tab:toggle+up'
"

# Override forgit's `gsw` so `gsw <branch>` delegates to real `git switch`
# (preserving DWIM tracking when only `origin/<branch>` exists). Forgit's
# wrapper falls back to `git switch -c "$@"` whenever `git show-branch <name>`
# fails, which skips DWIM and creates a no-tracking branch from HEAD. The
# no-arg fzf picker is preserved.
# Queued via zsh-defer so we run after forgit's deferred source defines the
# `gsw` alias we're replacing.
zsh-defer -c '
unalias gsw 2>/dev/null
gsw() {
    if (( $# == 0 )); then
        forgit::switch::branch
    else
        command git switch "$@"
    fi
}
compdef _git gsw=git-switch
'
