# WSL aliases
alias epl='pwshw explorer.exe'
alias cscw='win32yank.exe -i --crlf'
alias vscw='win32yank.exe -o --lf'
alias ollama='ollama.exe'
alias ollamaw='\ollama'
alias llmw='ollamaw'

openw() {
  cmd.exe /C start "$*"
}

cmdw() {
  cmd.exe /C "$*"
}

pwshw() {
  pwsh.exe -C "$*"
}
alias pw='pwshw'

# Program aliases
alias qdrant='pwshw qdrant'
alias bw='pwshw bw'

# Lock the Windows host from WSL.
alias lock='pwshw "rundll32 user32.dll,LockWorkStation"'
