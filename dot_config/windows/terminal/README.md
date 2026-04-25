# Windows Terminal — settings.json

This is a reference copy of the user's Windows Terminal config. chezmoi does **not** apply this file automatically because the canonical destination on Windows is the Microsoft Store package directory, which has a publisher hash in the path:

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbcc\LocalState\settings.json
```

(For unpackaged / preview builds, the path is `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json`.)

## How to install on a Windows box

After running `chezmoi apply` on the Windows side (which extracts this file under `%USERPROFILE%\.config\windows\terminal\settings.json`), copy or junction it into the Store path. From PowerShell:

```powershell
Copy-Item `
  "$env:USERPROFILE\.config\windows\terminal\settings.json" `
  "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbcc\LocalState\settings.json" -Force
```

Or, to keep the file in sync going forward, junction-link it:

```powershell
New-Item -ItemType SymbolicLink `
  -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbcc\LocalState\settings.json" `
  -Target "$env:USERPROFILE\.config\windows\terminal\settings.json" -Force
```

Symlink requires Developer Mode enabled or an elevated PowerShell.

## What's in here

- **Default profile**: `kali-linux` (WSL distro). Falls back to whatever Terminal auto-discovers if Kali isn't installed yet.
- **Profiles**: kali-linux, Ubuntu, PowerShell (Core), Command Prompt, Windows PowerShell, Azure Cloud Shell. The previous machine's VS 2022/18 dev prompts, Git Bash, archlinux/podman/julia profiles were stripped — Terminal auto-discovers any of those that are installed and re-adds them on next launch.
- **Schemes**: Catppuccin (Frappé / Latte / Macchiato / Mocha), Dracula, Dracula Improved, One Half Dark Improved.
- **Themes**: Catppuccin variants (Macchiato is the default).
- **Font**: CaskaydiaCove Nerd Font Mono — install separately on Windows (e.g. via [Nerd Fonts](https://www.nerdfonts.com/font-downloads) or `winget install --id=Microsoft.CascadiaCode -e`, then add the Nerd Font version).
- **Keybindings**: `Ctrl+Shift+X` global summon, `Ctrl+Shift+F` find, `Alt+Shift+D` split pane, plus the usual copy/paste.
