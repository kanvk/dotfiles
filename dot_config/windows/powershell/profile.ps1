# Bail out when stdin is a pipe (e.g. whkd's persistent shell) rather than a real
# console: loading starship/conda/mamba/fnm under redirected input hangs the shell
# and silently breaks every hotkey command whkd sends through it.
if ([Console]::IsInputRedirected) { return }

Import-Module 'C:\Program Files\gsudo\Current\gsudoModule.psd1'

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function MSYS2-Update {
    pacman -Syu --noconfirm
}

function Rust-Update {
    rustup update && cargo install-update -a
}

function Texlive-Update {
    sudo tlmgr update --self --all
}

function Pip-Upgrade {
    uv tool upgrade --all
}

function UV-Update {
    uv self update
}

function Go-Upgrade {
    go-global-update
}

function TLDR-Update {
    tldr -u
}

function Pyenv-Update {
    &"${env:PYENV_HOME}\install-pyenv-win.ps1"
}

function Komorebi-Restart {
    komorebic stop --whkd
    komorebic start --whkd
}

function uu {
    Texlive-Update && UV-Update && Pip-Upgrade && Rust-Update && Go-Upgrade && TLDR-Update && MSYS2-Update
}

Set-Alias vim nvim
Set-Alias lg lazygit
Set-Alias lzd lazydocker
Set-Alias mup MSYS2-Update
Set-Alias rup Rust-Update
Set-Alias tup Texlive-Update
Set-Alias pup Pip-Upgrade
Set-Alias goup Go-Upgrade
Set-Alias tldrup TLDR-Update
Set-Alias op start
Set-Alias epl explorer
Set-Alias clr clear
Set-Alias llm ollama
Set-Alias ouiup Open-WebUI-Update
Set-Alias ts tailscale
Set-Alias kr Komorebi-Restart

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

#region conda initialize
# !! Contents within this block are managed by 'conda init' !!
If (Test-Path "C:\ProgramData\miniforge3\Scripts\conda.exe") {
    (& "C:\ProgramData\miniforge3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

#region mamba initialize
# !! Contents within this block are managed by 'mamba shell init' !!
$Env:MAMBA_ROOT_PREFIX = "C:\ProgramData\miniforge3"
$Env:MAMBA_EXE = "C:\ProgramData\miniforge3\Library\bin\mamba.exe"
(& $Env:MAMBA_EXE 'shell' 'hook' -s 'powershell' -r $Env:MAMBA_ROOT_PREFIX) | Out-String | Invoke-Expression
#endregion

# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_rainbow.omp.json" | Invoke-Expression
Invoke-Expression (&starship init powershell)