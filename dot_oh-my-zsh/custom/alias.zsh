# web-search
alias gle='google'
alias wa='wolframalpha'

# Updates
alias uup='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias nalaup='sudo nala upgrade --purge -y'
alias zup='antigen update && omz update'
alias rup='rustup update && cargo install-update -a'
alias gup='go-global-update'
alias nup='sudo npm -g update'
alias vup='lvim +LvimUpdate +q'
alias bup='brew update && brew upgrade && brew cleanup'
alias pup='poetry self update'
alias aup='uup && bup && rup && gup && nup && pup && vup && zup'
alias uu='uup && zup'

# vim
alias nvim='lvim'
alias vim='nvim'
alias vimdiff='nvim -d'
alias view='nvim -R'

# Use rust uutils if possible
if  [ -x "$(command -v coreutils)" ]; then
    alias b2sum="command coreutils b2sum"
    alias b3sum="command coreutils b3sum"
    alias base32="command coreutils base32"
    alias base64="command coreutils base64"
    alias basename="command coreutils basename"
    alias basenc="command coreutils basenc"
    alias cat="command coreutils cat"
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
    alias echo="command coreutils echo"
    alias env="command coreutils env"
    alias expand="command coreutils expand"
    alias expr="command coreutils expr"
    alias factor="command coreutils factor"
    alias false="command coreutils false"
    alias fmt="command coreutils fmt"
    alias fold="command coreutils fold"
    alias hashsum="command coreutils hashsum"
    alias head="command coreutils head"
    alias join="command coreutils join"
    alias link="command coreutils link"
    alias ln="command coreutils ln"
    # alias ls="command coreutils ls"
    alias md5sum="command coreutils md5sum"
    alias mkdir="command coreutils mkdir"
    alias mktemp="command coreutils mktemp"
    alias more="command coreutils more"
    alias mv="command coreutils mv -g"
    alias nl="command coreutils nl"
    alias numfmt="command coreutils numfmt"
    alias od="command coreutils od"
    alias paste="command coreutils paste"
    alias pr="command coreutils pr"
    alias printenv="command coreutils printenv"
    alias printf="command coreutils printf"
    alias ptx="command coreutils ptx"
    alias pwd="command coreutils pwd"
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
    alias sum="command coreutils sum"
    alias tac="command coreutils tac"
    alias tail="command coreutils tail"
    alias tee="command coreutils tee"
    alias test="command coreutils test"
    alias touch="command coreutils touch"
    alias tr="command coreutils tr"
    alias true="command coreutils true"
    alias truncate="command coreutils truncate"
    alias tsort="command coreutils tsort"
    alias unexpand="command coreutils unexpand"
    alias uniq="command coreutils uniq"
    alias unlink="command coreutils unlink"
    alias vdir="command coreutils vdir"
    alias wc="command coreutils wc"
    alias yes="command coreutils yes"
fi

# Enable color support for coreutils
  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
  alias diff='diff --color=auto'
  alias ip='ip --color=auto'

# Other Programs
alias py='python3'
alias bat='batcat'
alias lg='lazygit'
alias lzd='lazydocker'
alias clr='clear'
alias tree='lsd --tree'
alias h='history'

# xclip
alias c='xclip'
alias v='xclip -o'
alias csc='xclip -sel c'
alias vsc='xclip -o -sel c'
