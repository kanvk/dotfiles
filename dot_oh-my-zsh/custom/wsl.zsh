# WSL aliases
alias exp='explorer.exe'
alias yank='win32yank.exe -i --crlf'
alias hx='hx.exe'

func strt() {
    cmd.exe /C start "$*"
}

func wcmd() {
    cmd.exe /C "$*"
}

func wpwsh() {
    pwsh.exe -C "$*"
}
