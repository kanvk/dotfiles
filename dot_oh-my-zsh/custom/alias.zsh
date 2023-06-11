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
alias aup='uup && bup && rup && gup && nup && vup && zup'
alias uu='uup && zup'

# vim
alias nvim='lvim'
alias vim='nvim'
alias vimdiff='nvim -d'
alias view='nvim -R'

# Programs
alias py='python3'
alias bat='batcat'
alias lg='lazygit'
alias ldoc='lazydocker'
alias clr='clear'
alias tree='lsd --tree'

# xclip
alias c='xclip'
alias v='xclip -o'
alias csc='xclip -sel c'
alias vsc='xclip -o -sel c'
