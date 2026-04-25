export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.bun/bin:$PATH"
export VISUAL='nvim'
export EDITOR='nvim'
# SUDO_EDITOR needs an absolute path — prefer brew's nvim (so root shares your config),
# fall back to system nvim, else unset and let sudo pick.
if   [ -x /home/linuxbrew/.linuxbrew/bin/nvim ]; then export SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim
elif [ -x /opt/homebrew/bin/nvim ]; then             export SUDO_EDITOR=/opt/homebrew/bin/nvim
elif command -v nvim >/dev/null 2>&1; then            export SUDO_EDITOR="$(command -v nvim)"
fi
export GPG_TTY=$TTY
export COLORTERM=truecolor
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1

# --- analytics / telemetry opt-outs ---
# DO_NOT_TRACK is a community-standard env (see consoledonottrack.com); honored
# by gh, glab, gitleaks, charmbracelet tools, and a long tail of others.
export DO_NOT_TRACK=1
# HashiCorp's "checkpoint" telemetry — covers `vault` (and any future hc tools).
export CHECKPOINT_DISABLE=1
# LocalStack CLI events.
export LOCALSTACK_DISABLE_EVENTS=1

export FZF_DEFAULT_OPTS="--bind=tab:down,shift-tab:up"

# vivid generates LS_COLORS on demand; skip silently if vivid isn't installed.
if command -v vivid >/dev/null 2>&1; then
  VIVID_THEME=snazzy
  VIVID_CACHE="$HOME/.cache/vivid"
  VIVID_VERSION="$(vivid --version)"
  if [[ ! -f "$VIVID_CACHE/24bit" || "$VIVID_VERSION" != "$(<"$VIVID_CACHE/version")" || "$VIVID_THEME" != "$(<"$VIVID_CACHE/theme")" ]]; then
    mkdir -p "$VIVID_CACHE"
    vivid generate $VIVID_THEME >"$VIVID_CACHE/24bit"
    vivid -m 8-bit generate $VIVID_THEME >"$VIVID_CACHE/8bit"
    echo "$VIVID_VERSION" >"$VIVID_CACHE/version"
    echo "$VIVID_THEME" >"$VIVID_CACHE/theme"
  fi
  export LS_COLORS="$(<"$VIVID_CACHE/24bit")"
  export LS_COLORS_8BIT="$(<"$VIVID_CACHE/8bit")"
fi

# WSL: CUDA passthrough lib only exists when WSL2 is built with GPU support.
if [ -d /usr/lib/wsl/lib ]; then
  export LD_LIBRARY_PATH="/usr/lib/wsl/lib/:$LD_LIBRARY_PATH"
  [ -f /usr/lib/wsl/lib/libcuda.so.1 ] && export NUMBA_CUDA_DRIVER=/usr/lib/wsl/lib/libcuda.so.1
fi

# Less pager config — prefer moor, fall back to system less.
if   [ -x /usr/bin/moor ]; then export PAGER=/usr/bin/moor
elif command -v moor >/dev/null 2>&1; then export PAGER="$(command -v moor)"
else export PAGER=less
fi
export LESS="-R --mouse --wheel-lines=3"
export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

# pipx — only point PIPX_DEFAULT_PYTHON when pyenv has a python3 available.
if command -v pyenv >/dev/null 2>&1; then
  _pyenv_py3="$(pyenv which python3 2>/dev/null)"
  [ -n "$_pyenv_py3" ] && export PIPX_DEFAULT_PYTHON="$_pyenv_py3"
  unset _pyenv_py3
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# broot launcher is created by `broot --install` — skip sourcing if absent.
[ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"
