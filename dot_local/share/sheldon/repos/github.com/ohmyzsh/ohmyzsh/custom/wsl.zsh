# WSL aliases
alias epl='pwshw explorer.exe'
alias cscw='win32yank.exe -i --crlf'
alias vscw='win32yank.exe -o --lf'
alias ollama='ollama.exe'
alias ollamaw='\ollama'
alias llmw='ollamaw'

func openw() {
    cmd.exe /C start "$*"
}

func cmdw() {
    cmd.exe /C "$*"
}

func pwshw() {
    pwsh.exe -C "$*"
}
