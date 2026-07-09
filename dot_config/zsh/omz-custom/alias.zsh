# zsh/omz — open_command is OMZ's cross-platform opener (xdg-open on Linux,
# cmd.exe-start on WSL, `open` on macOS) and honors $BROWSER for http(s) URLs.
alias xo='open_command'

# web-search
alias gle='google'
alias wa='wolframalpha'
alias ddg='ddg'
alias ghb='github'
alias sof='stackoverflow'
alias sch='scholar'
alias yt='youtube'
alias gpt='chatgpt'

# Updates
alias aptup='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias asdfup='asdf plugin update --all'
alias brewup='brew update && brew upgrade && brew autoremove && brew cleanup; brew unlink python 2>/dev/null; brew unlink ruby 2>/dev/null'
alias goup='go-global-update'
alias haskellup='stack upgrade && stack update'
alias nalaup='sudo nala full-upgrade --purge -y'
alias nixup='nix upgrade-nix && nix-channel --update'
alias npmup='sudo npm -g update'
alias perlup='sudo sh -c "cpanm --self-upgrade && cpan-outdated | cpanm"'
alias pipup='uv tool upgrade --all'
alias poetryup='poetry self update'
alias rubyup='sudo gem update' # add gem update --system for non-apt installs
alias rustupg='rustup update && cargo install-update -a'
alias tldrup='tldr -u'
alias vimup='timeout --kill-after=30s 3m nvim --headless +AstroUpdate +qa 2>/dev/null'
alias zshup='sheldon lock --update'
alias uu='nalaup && brewup && rustupg && pipup && goup && npmup && tldrup && zshup' # pipup is uv tool upgrade --all (poetry et al.)
alias uuu='uu && asdfup && rubyup && haskellup && perlup'

# vim
alias vim='nvim'
alias vimdiff='vim -d'
alias view='vim -R'

# lvim
alias lvim='NVIM_APPNAME=lvim nvim'
alias lvimup='timeout --kill-after=30s 3m env NVIM_APPNAME=lvim nvim --headless +"Lazy! sync" +qa 2>/dev/null'

# Use rust uutils if possible
if [ -x "$(command -v coreutils)" ]; then
  alias arch="command coreutils arch"
  alias b2sum="command coreutils b2sum"
  alias b3sum="command coreutils b3sum"
  alias base32="command coreutils base32"
  alias base64="command coreutils base64"
  alias basename="command coreutils basename"
  alias basenc="command coreutils basenc"
  alias cat="command coreutils cat"
  alias chgrp="command coreutils chgrp"
  alias chmod="command coreutils chmod"
  alias chown="command coreutils chown"
  alias chroot="command coreutils chroot"
  alias cksum="command coreutils cksum"
  alias comm="command coreutils comm"
  alias cp="command coreutils cp -g"
  alias csplit="command coreutils csplit"
  alias cut="command coreutils cut"
  alias date="command coreutils date"
  alias dd="command coreutils dd"
  alias df="command coreutils df"
  alias dir="command coreutils dir"
  alias dircolors="command coreutils dircolors"
  alias dirname="command coreutils dirname"
  alias du="command coreutils du"
  alias env="command coreutils env"
  alias expand="command coreutils expand"
  alias expr="command coreutils expr"
  alias factor="command coreutils factor"
  alias fmt="command coreutils fmt"
  alias fold="command coreutils fold"
  alias groups="command coreutils groups"
  alias hashsum="command coreutils hashsum"
  alias head="command coreutils head"
  alias hostname="command coreutils hostname"
  alias id="command coreutils id"
  alias install="command coreutils install"
  alias join="command coreutils join"
  alias link="command coreutils link"
  alias ln="command coreutils ln"
  alias logname="command coreutils logname"
  # alias ls="command coreutils ls"
  alias md5sum="command coreutils md5sum"
  alias mkdir="command coreutils mkdir"
  alias mkfifo="command coreutils mkfifo"
  alias mknod="command coreutils mknod"
  alias mktemp="command coreutils mktemp"
  alias more="command coreutils more"
  alias mv="command coreutils mv -g"
  alias nice="command coreutils nice"
  alias nl="command coreutils nl"
  alias nohup="command coreutils nohup"
  alias nproc="command coreutils nproc"
  alias numfmt="command coreutils numfmt"
  alias od="command coreutils od"
  alias paste="command coreutils paste"
  alias pathchk="command coreutils pathchk"
  alias pinky="command coreutils pinky"
  alias pr="command coreutils pr"
  alias printenv="command coreutils printenv"
  # Skipped: printf, echo, kill, pwd, test, true, false. zsh has these as builtins; aliasing
  # routes microsecond builtins through fork+exec (~1000x slower). printf specifically also
  # breaks `printf -v`.
  alias ptx="command coreutils ptx"
  alias readlink="command coreutils readlink"
  alias realpath="command coreutils realpath"
  alias relpath="command coreutils relpath"
  alias rm="command coreutils rm"
  alias rmdir="command coreutils rmdir"
  alias seq="command coreutils seq"
  alias sha1sum="command coreutils sha1sum"
  alias sha224sum="command coreutils sha224sum"
  alias sha256sum="command coreutils sha256sum"
  alias sha3-224sum="command coreutils sha3-224sum"
  alias sha3-256sum="command coreutils sha3-256sum"
  alias sha3-384sum="command coreutils sha3-384sum"
  alias sha3-512sum="command coreutils sha3-512sum"
  alias sha384sum="command coreutils sha384sum"
  alias sha3sum="command coreutils sha3sum"
  alias sha512sum="command coreutils sha512sum"
  alias shake128sum="command coreutils shake128sum"
  alias shake256sum="command coreutils shake256sum"
  alias shred="command coreutils shred"
  alias shuf="command coreutils shuf"
  alias sleep="command coreutils sleep"
  alias sort="command coreutils sort"
  alias split="command coreutils split"
  alias stat="command coreutils stat"
  alias stdbuf="command coreutils stdbuf"
  alias stty="command coreutils stty"
  alias sum="command coreutils sum"
  alias sync="command coreutils sync"
  alias tac="command coreutils tac"
  alias tail="command coreutils tail"
  alias tee="command coreutils tee"
  alias timeout="command coreutils timeout"
  alias touch="command coreutils touch"
  alias tr="command coreutils tr"
  alias truncate="command coreutils truncate"
  alias tsort="command coreutils tsort"
  alias tty="command coreutils tty"
  alias uname="command coreutils uname"
  alias unexpand="command coreutils unexpand"
  alias uniq="command coreutils uniq"
  alias unlink="command coreutils unlink"
  alias uptime="command coreutils uptime"
  alias users="command coreutils users"
  alias vdir="command coreutils vdir"
  alias wc="command coreutils wc"
  alias who="command coreutils who"
  alias whoami="command coreutils whoami"
  alias yes="command coreutils yes"
fi

# Enable color support (ls/dir/vdir overridden by eza aliases in .zshrc)
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

# Other Programs
alias asg='ast-grep'
alias cat='bat'
alias ccat='bat -pp'
alias clr='clear'
alias db='distrobox'
alias du='dust -b'
alias gkr='gitkraken'
alias h='history'
alias less='moor'
alias lg='lazygit'
alias llm='ollama'
alias lzd='lazydocker'
alias nf='apprise'
alias ngr='ranger'
alias ps='procs'
alias py='python3'
alias tree='eza --tree'
alias x='ouch d'
alias yz='yazi'

# xclip — OSC 52 fallback when there's no X display (SSH, headless box).
# OSC 52 carries CLIPBOARD selection in copy direction only; terminals
# refuse PRIMARY copy and any paste-over-the-wire for security, so the
# v/vsc paste helpers stay xclip-only.
_osc52_copy() {
  local data
  if (( $# )); then
    data=$(base64 -w0 < "$1" 2>/dev/null || base64 < "$1" | tr -d '\n')
  else
    data=$(base64 -w0 2>/dev/null || base64 | tr -d '\n')
  fi
  # Build the escape, then write to /dev/tty so it reaches the terminal
  # even when stdout is redirected — ZVM wraps the eval'd copy cmd in
  # `>/dev/null 2>&1`, which would otherwise swallow it. DCS-wrap inside
  # tmux as belt-and-suspenders for forwarders without set-clipboard on.
  # Fall back to stdout when there's no controlling tty (scripts, hooks).
  local seq
  if [[ -n $TMUX ]]; then
    seq=$(printf '\ePtmux;\e\e]52;c;%s\a\e\\' "$data")
  else
    seq=$(printf '\e]52;c;%s\a' "$data")
  fi
  print -rn -- "$seq" 2>/dev/null >/dev/tty || print -rn -- "$seq"
}
c()   { if [[ -n $DISPLAY ]]; then xclip "$@";        else _osc52_copy "$@"; fi }
csc() { if [[ -n $DISPLAY ]]; then xclip -sel c "$@"; else _osc52_copy "$@"; fi }
alias v='xclip -o'
alias vsc='xclip -o -sel c'

# profiles
alias nfw='apprise --tag=wk'
alias awsl='aws --profile local'

# tmux
alias t='tmux'
alias tm='tmux new-session -A -s main'
alias tp='tmux new-session -A -s $(basename $PWD)'
alias tsf='sesh connect "$(sesh list | fzf)"'
# `tv sesh` (television's sesh action mode) can't hand the terminal off to
# `tmux attach` cleanly: stdin becomes /dev/tty, and tmux's display renders
# to nowhere on some stacks. Run `sesh connect` from the shell so it inherits
# a real pseudoterminal.
ts() {
  emulate -L zsh
  local target
  if (( $# > 0 )); then
    target="$*"
  else
    target=$(tv sesh) || return
    [[ -z $target ]] && return
  fi

  # `tmux attach` fails inside an existing client; `switch-client` is the
  # in-tmux equivalent. Inline rather than defining a nested function (zsh
  # inner functions leak into global scope).
  local attach
  if [[ -n $TMUX ]]; then attach=(tmux switch-client -t); else attach=(tmux attach -t); fi

  # Path input (`ts ~/p/foo` from the tv picker) hits sesh's dirStrategy,
  # which calls `tmux new-session -s <basename>` without checking whether a
  # session with that name already exists — `new-session` then fails with
  # "duplicate session." Short-circuit by attaching to the existing one.
  # Assumes sesh's default namer (basename); a custom dirStrategy in
  # ~/.config/sesh/sesh.toml would break this shortcut.
  local bname=${target:t}
  if tmux has-session -t "=$bname" 2>/dev/null; then
    "$attach[@]" "=$bname"
    return
  fi

  # Substring fallback: `ts foo` should attach to `foo_bar` when that's the
  # only live session matching. Sesh itself requires an exact match and would
  # otherwise just exit 1 (or fall into zoxide resolution). If multiple
  # sessions match, defer to sesh — it'll surface the ambiguity.
  local -a sessions matches
  sessions=(${(f)"$(tmux list-sessions -F '#S' 2>/dev/null)"})
  matches=(${(M)sessions:#*${target}*})
  if (( ${#matches} == 1 )); then
    "$attach[@]" "=${matches[1]}"
    return
  fi

  sesh connect -- "$target"
}

# misc
alias sudop='sudo env "PATH=$PATH"'
alias sa='source .venv/bin/activate'
alias pyinstall='TCLTK_PATH=$(brew --prefix tcl-tk) PYTHON_CONFIGURE_OPTS="--with-tcltk-includes=${TCLTK_PATH}/include --with-tcltk-libs=${TCLTK_PATH}/lib" pyenv install'
alias rcp='rsync -avzPh'

# chezmoi
alias cz='chezmoi'
alias cvim='chezmoi edit --apply'
# chezmoi's built-in pager is disabled globally — apply -v streams per-file
# diffs through an io.Pipe that deadlocks if the pager exits early (moor's
# small-input passthrough does this). Pipe explicitly to moor here for the
# one place a pager is actually wanted. --color=true forces ANSI through the
# pipe (auto-detect strips it when stdout isn't a TTY).
alias czdiff='chezmoi --color=true diff | moor'

# uv
alias uva='uv add'
alias uvexp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'
alias uvi='uv init'
alias uvinw='uv init --no-workspace'
alias uvl='uv lock'
alias uvlr='uv lock --refresh'
alias uvlu='uv lock --upgrade'
alias uvp='uv pip'
alias uvpi='uv python install'
alias uvpl='uv python list'
alias uvpu='uv python uninstall'
alias uvpy='uv python'
alias uvpp='uv python pin'
alias uvr='uv run'
alias uvrm='uv remove'
alias uvs='uv sync'
alias uvsr='uv sync --refresh'
alias uvsu='uv sync --upgrade'
alias uvtr='uv tree'
alias uvv='uv venv'
