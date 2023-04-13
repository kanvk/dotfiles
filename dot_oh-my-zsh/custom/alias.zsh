# web-search
alias gle='google'
alias wa='wolframalpha'

# Updates
alias uup='sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y'
alias zup='antigen update && omz update'
alias rup='rustup update && cargo install-update -a'
alias gup='go-global-update'
alias nup='sudo npm -g update'
alias vup='lvim +LvimUpdate +q'
alias aup='uup && rup && gup && nup && vup && zup'
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

# xclip
alias c='xclip'
alias v='xclip -o'
alias csc='xclip -sel c'
alias vsc='xclip -o -sel c'
