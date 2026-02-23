# WSL aliases
alias epl='pwshw explorer.exe'
alias cscw='win32yank.exe -i --crlf'
alias vscw='win32yank.exe -o --lf'
alias ollama='ollama.exe'
alias ollamaw='\ollama'
alias llmw='ollamaw'
alias ts='tailscale.exe'

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

# ZSH: jeffreytse/zsh-vi-mode
ZVM_CLIPBOARD_COPY_CMD='win32yank.exe -i --crlf'
ZVM_CLIPBOARD_PASTE_CMD='win32yank.exe -o --lf'
ZVM_OPEN_CMD='open_command'
ZVM_OPEN_FILE_CMD='code'

# Program aliases
alias qdrant='pwshw qdrant'
alias bw='pwshw bw'
