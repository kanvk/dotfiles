# WSL aliases
alias exp='explorer.exe'
alias cscw='win32yank.exe -i --crlf'
alias vscw='win32yank.exe -o --lf'
alias hx='hx.exe'

func openw() {
    cmd.exe /C start "$*"
}

func cmdw() {
    cmd.exe /C "$*"
}

func pwshw() {
    pwsh.exe -C "$*"
}
