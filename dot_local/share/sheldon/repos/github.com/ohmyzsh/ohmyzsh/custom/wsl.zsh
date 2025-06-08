# WSL aliases
alias epl='pwshw explorer.exe'
alias cscw='win32yank.exe -i --crlf'
alias vscw='win32yank.exe -o --lf'
alias ollama='ollama.exe'
alias ollamaw='\ollama'
alias llmw='ollamaw'
alias ts='tailscale.exe'

func openw() {
    cmd.exe /C start "$*"
}

func cmdw() {
    cmd.exe /C "$*"
}

func pwshw() {
    pwsh.exe -C "$*"
}
alias pw='pwshw'

# Program aliases
alias qdrant='pwshw qdrant'
