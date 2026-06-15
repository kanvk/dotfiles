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
# Re-point gpg-agent at the current tty for pinentry. Without this, opening a
# fresh terminal or attaching a tmux pane leaves the agent prompting on the
# tty it first saw — looks like a hang. The OMZ gpg-agent plugin would do
# this automatically; we run it manually since we use the ssh-agent plugin.
gpg-connect-agent updatestartuptty /bye &>/dev/null
export COLORTERM=truecolor
export TZ=America/New_York
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1
# Skip brew 6.0's default "Proceed? [Y/n]" prompt on install/upgrade.
export HOMEBREW_NO_ASK=1

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
export LESS="-R -i -S -N --mouse --wheel-lines=3 --incsearch --use-color"
# Disable less's history file (~/.lesshst) — it stores in-pager search patterns
# and `!cmd` invocations, which can occasionally surface tokens from logs we've
# searched through. Not file-viewing history; nothing useful is lost.
export LESSHISTFILE=-

# `man` → bat with the `man` syntax for real syntax-aware highlighting. col -bx
# strips groff's backspace-overstrike (less handles it natively, bat does not);
# MANROFFOPT=-c tells groff to also emit ANSI codes for color, covering edge cases.
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# bat's own pager — route to moor with moor's line numbers suppressed, since bat
# already adds them. Without -no-linenumbers we get nested line-number columns.
export BAT_PAGER="moor -no-linenumbers"

# Syntax-highlighting themes. Same conceptual theme across bat/delta/moor: bat
# and delta share a name string (delta links bat as a library), moor uses
# chroma's theme list with a lowercase-hyphenated spelling. Switching theme
# means editing both lines below AND `[delta] syntax-theme` in dot_gitconfig.tmpl.
export BAT_THEME="Catppuccin Macchiato"
export MOOR="-style=catppuccin-macchiato"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# broot launcher is created by `broot --install` — skip sourcing if absent.
[ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

# luarocks: surface ~/.luarocks/{share,lib,bin} via LUA_PATH/LUA_CPATH/PATH so
# rock-installed libs are `require`-able and CLIs (busted, luacheck, …) work.
command -v luarocks >/dev/null && eval "$(luarocks path --bin)"
