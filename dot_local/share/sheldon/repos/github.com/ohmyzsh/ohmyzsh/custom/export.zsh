export PATH=/home/kanvk/.local/bin:/home/kanvk/.cargo/bin:/home/kanvk/go/bin:$PATH
export VISUAL='nvim'
export EDITOR='nvim'
export SUDO_EDITOR='/home/linuxbrew/.linuxbrew/bin/nvim'
export GPG_TTY=$TTY
export COLORTERM=truecolor
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
export FZF_DEFAULT_OPTS="--bind=tab:down,shift-tab:up"
VIVID_THEME=snazzy
VIVID_CACHE="$HOME/.cache/vivid"
VIVID_VERSION="$(vivid --version)"
if [[ ! -f "$VIVID_CACHE/24bit" || "$VIVID_VERSION" != "$(< "$VIVID_CACHE/version")" || "$VIVID_THEME" != "$(< "$VIVID_CACHE/theme")" ]]; then
    mkdir -p "$VIVID_CACHE"
    vivid generate $VIVID_THEME > "$VIVID_CACHE/24bit"
    vivid -m 8-bit generate $VIVID_THEME > "$VIVID_CACHE/8bit"
    echo "$VIVID_VERSION" > "$VIVID_CACHE/version"
    echo "$VIVID_THEME" > "$VIVID_CACHE/theme"
fi
export LS_COLORS="$(< "$VIVID_CACHE/24bit")"
export LS_COLORS_8BIT="$(< "$VIVID_CACHE/8bit")"
export LD_LIBRARY_PATH="/usr/lib/wsl/lib/:$LD_LIBRARY_PATH"
export NUMBA_CUDA_DRIVER="/usr/lib/wsl/lib/libcuda.so.1"

# Less pager config
export PAGER=/usr/local/bin/moor
export LESS="-R --mouse --wheel-lines=3"
export LESS_TERMCAP_mb=$'\E[1;31m'  # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'  # begin bold
export LESS_TERMCAP_me=$'\E[0m'     # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'     # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'  # begin underline
export LESS_TERMCAP_ue=$'\E[0m'     # reset underline

# pipx
export PIPX_DEFAULT_PYTHON='/home/kanvk/.pyenv/shims/python3.12'

# mcfly (disabled, using atuin)
# export MCFLY_KEY_SCHEME=vim
# export MCFLY_PROMPT="❯"
# export MCFLY_FUZZY=2
# export MCFLY_RESULTS=30
# export MCFLY_HISTORY_LIMIT=10000

# nvm (disabled, using fnm)
# export NVM_DIR="$HOME/.nvm"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# broot
source /home/kanvk/.config/broot/launcher/bash/br
