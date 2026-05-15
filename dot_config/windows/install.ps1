#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
  Install this repo's dot_config/windows/** and dot_config/nvim/** to each
  tool's actual Windows location (komorebi root, $env:USERPROFILE\.config,
  $PROFILE, etc.).

.DESCRIPTION
  Designed to run from Windows pwsh — that's where $env:USERPROFILE,
  $PROFILE, and $env:KOMOREBI_CONFIG_HOME all resolve. Can run from WSL pwsh
  as a best-effort: paths are reconstructed under /mnt/c/Users/<user>/, and
  OneDrive-redirected Documents is NOT detected from WSL (run from Windows
  pwsh if your Documents lives under OneDrive).

  Path map (relative to dot_config/):
    windows/executable_komorebi.json     -> $KomorebiHome\komorebi.json
    windows/executable_komorebi.bar.json -> $KomorebiHome\komorebi.bar.json
    windows/powershell/profile.ps1       -> $PROFILE.CurrentUserAllHosts
    windows/dot_vimrc                    -> $env:USERPROFILE\.vimrc
    windows/config/<rest>                -> $env:USERPROFILE\.config\<rest>  (chezmoi prefixes stripped)
    windows/terminal/**                  -> ignored (see terminal\README.md)
    nvim/<rest>                          -> $NvimConfig\<rest>  (chezmoi prefixes stripped)

  $KomorebiHome = $env:KOMOREBI_CONFIG_HOME if set, else $env:USERPROFILE.
  $NvimConfig   = $env:XDG_CONFIG_HOME\nvim if set, else $env:LOCALAPPDATA\nvim
                  (matches Neovim's stdpath('config') resolution on Windows).
  Files in the source tree without a mapping rule are warned and skipped.

.PARAMETER User
  Used only to substitute "kanvk" -> <User> inside text-file contents (the
  yasb config has hardcoded C:\Users\kanvk\... paths). Defaults to the
  current user. Does NOT change destination paths — those always target the
  CURRENT user's profile / pwsh state.

.PARAMETER DryRun
  Print every action without writing.

.PARAMETER Diff
  For each file that exists at the destination and differs from the source,
  print a unified diff (via `git diff --no-index` when git is on PATH, else
  PowerShell's Compare-Object). Implies dry-run; nothing is written.

.PARAMETER Yes
  Skip the overwrite prompt for files that already exist.

.EXAMPLE
  pwsh ./install.ps1 -DryRun

.EXAMPLE
  pwsh ./install.ps1 -Diff

.EXAMPLE
  pwsh ./install.ps1 -Yes
#>

[CmdletBinding()]
param(
    [string]$User,
    [switch]$DryRun,
    [switch]$Diff,
    [switch]$Yes
)

# Paths/files to skip, matched against any path segment of the source-relative path.
$IgnoredPaths = @(
    'terminal'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- helpers -----------------------------------------------------------------

# Strip chezmoi source-name prefixes from one path segment.
# `dot_` becomes a literal "."; all other attribute prefixes are stripped.
# Prefixes can stack (e.g. `private_dot_ssh`, `executable_dot_zshrc`).
function Convert-ChezmoiSegment {
    param([Parameter(Mandatory)][string]$Segment)
    $attrs = @(
        'after_', 'before_', 'create_', 'empty_', 'encrypted_', 'exact_',
        'executable_', 'literal_', 'modify_', 'once_', 'onchange_',
        'private_', 'readonly_', 'remove_', 'run_', 'symlink_'
    )
    $changed = $true
    while ($changed) {
        $changed = $false
        if ($Segment.StartsWith('dot_')) {
            $Segment = '.' + $Segment.Substring(4)
            $changed = $true
            continue
        }
        foreach ($p in $attrs) {
            if ($Segment.StartsWith($p)) {
                $Segment = $Segment.Substring($p.Length)
                $changed = $true
                break
            }
        }
    }
    return $Segment
}

# NUL-byte sniff on the first 8 KB. Keeps icon/PNG content out of the
# text-substitution path.
function Test-IsBinary {
    param([Parameter(Mandatory)][string]$Path)
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $buf = [byte[]]::new(8192)
        $n = $fs.Read($buf, 0, $buf.Length)
        for ($i = 0; $i -lt $n; $i++) {
            if ($buf[$i] -eq 0) { return $true }
        }
        return $false
    } finally {
        $fs.Dispose()
    }
}

# Print a unified diff between Source and Dest. Uses `git diff --no-index`
# when git is on PATH (full unified format, handles binary), otherwise falls
# back to PowerShell's Compare-Object.
function Write-FileDiff {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Dest,
        [Parameter(Mandatory)][bool]$IsBinary
    )
    if ($IsBinary) {
        Write-Host '    (binary files differ)'
        return
    }
    if (Get-Command git -ErrorAction SilentlyContinue) {
        & git diff --no-index --no-color -- $Dest $Source
        # `git diff --no-index` exits 1 when files differ — expected here.
        $global:LASTEXITCODE = 0
    } else {
        $ref  = Get-Content -LiteralPath $Dest
        $cand = Get-Content -LiteralPath $Source
        Compare-Object -ReferenceObject $ref -DifferenceObject $cand -CaseSensitive |
            ForEach-Object { Write-Host "    $($_.SideIndicator) $($_.InputObject)" }
    }
}

# --- main --------------------------------------------------------------------

if (-not $User) {
    if ($IsWindows -and $env:USERNAME) { $User = $env:USERNAME }
    elseif ($env:USER) { $User = $env:USER }
    else { $User = 'kanvk' }
}
$Substitute = ($User -ne 'kanvk')

# Anchor paths: on Windows they come from real env vars / pwsh state; on WSL
# they're reconstructed under /mnt/c/Users/<user>/.
if ($IsWindows) {
    $WinUserHome = $env:USERPROFILE
    $PwshProfile = $PROFILE.CurrentUserAllHosts
} else {
    $WinUserHome = "/mnt/c/Users/$User"
    $PwshProfile = Join-Path $WinUserHome 'Documents/PowerShell/profile.ps1'
}
$KomorebiHome = if ($env:KOMOREBI_CONFIG_HOME) { $env:KOMOREBI_CONFIG_HOME } else { $WinUserHome }
$XdgConfig    = Join-Path $WinUserHome '.config'
# nvim on Windows resolves stdpath('config') to $XDG_CONFIG_HOME/nvim if the
# var is set, else $LOCALAPPDATA\nvim — NOT $USERPROFILE\.config\nvim. Match
# that resolution here so files land where nvim actually looks.
$NvimConfig = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME 'nvim'
} elseif ($IsWindows) {
    Join-Path $env:LOCALAPPDATA 'nvim'
} else {
    # WSL fallback: %LOCALAPPDATA% sits under the Windows user's AppData/Local.
    Join-Path $WinUserHome 'AppData/Local/nvim'
}

# Source roots. The script lives at dot_config/windows/, so dot_config/nvim/
# is its sibling — resolve via `..` and tolerate the case where someone
# carved out just dot_config/windows/ (no nvim sibling present).
$WindowsSource = $PSScriptRoot
$nvimCandidate = Join-Path $PSScriptRoot '..' 'nvim'
$NvimSource    = if (Test-Path -LiteralPath $nvimCandidate) {
    (Resolve-Path -LiteralPath $nvimCandidate).Path
} else { $null }

function Resolve-WindowsDest {
    param([Parameter(Mandatory)][string]$RelForward)
    switch -CaseSensitive ($RelForward) {
        'executable_komorebi.json'     { return (Join-Path $KomorebiHome 'komorebi.json') }
        'executable_komorebi.bar.json' { return (Join-Path $KomorebiHome 'komorebi.bar.json') }
        'powershell/profile.ps1'       { return $PwshProfile }
        'dot_vimrc'                    { return (Join-Path $WinUserHome '.vimrc') }
    }
    if ($RelForward.StartsWith('config/')) {
        $rest = $RelForward.Substring('config/'.Length)
        $stripped = ($rest -split '/') | ForEach-Object { Convert-ChezmoiSegment $_ }
        return (Join-Path $XdgConfig ($stripped -join [System.IO.Path]::DirectorySeparatorChar))
    }
    return $null
}

function Resolve-NvimDest {
    param([Parameter(Mandatory)][string]$RelForward)
    $stripped = ($RelForward -split '/') | ForEach-Object { Convert-ChezmoiSegment $_ }
    return (Join-Path $NvimConfig ($stripped -join [System.IO.Path]::DirectorySeparatorChar))
}

$counts = @{ written = 0; identical = 0; ignored = 0; skipped = 0; unmapped = 0 }
$script:AssumeYes = [bool]$Yes
# -Diff prints a content diff and writes nothing — same write-suppression as
# -DryRun, but with line-level output for files that differ.
$EffectiveDryRun = $DryRun.IsPresent -or $Diff.IsPresent

$platform = if ($IsWindows) { 'Windows' } else { "WSL (paths under /mnt/c/Users/$User/)" }
$subNote  = if ($Substitute) { " (will substitute kanvk -> $User in text files)" } else { '' }
Write-Host "Source (windows): $WindowsSource"
Write-Host "Source (nvim):    $(if ($NvimSource) { $NvimSource } else { '(not found, skipping)' })"
Write-Host "Platform:         $platform"
Write-Host "User:             $User$subNote"
Write-Host "Komorebi home:    $KomorebiHome"
Write-Host "XDG .config:      $XdgConfig"
Write-Host "Nvim config:      $NvimConfig"
Write-Host "PWSH profile:     $PwshProfile"
Write-Host "DryRun:           $($DryRun.IsPresent)"
Write-Host "Diff:             $($Diff.IsPresent)"
Write-Host "Yes:              $($Yes.IsPresent)"
Write-Host "Ignored:          $($IgnoredPaths -join ', ')"
Write-Host ''

function Sync-Tree {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][scriptblock]$Mapper
    )
    foreach ($file in Get-ChildItem -Path $Root -Recurse -File -Force) {
        $rel = [System.IO.Path]::GetRelativePath($Root, $file.FullName)
        $relForward = $rel -replace '\\', '/'

        if ($file.FullName -eq $PSCommandPath) { continue }

        $segments = $relForward -split '/'
        $ignored = $false
        foreach ($seg in $segments) {
            if ($IgnoredPaths -contains $seg) { $ignored = $true; break }
        }
        if ($ignored) {
            Write-Host "  ignore   $relForward"
            $counts.ignored++
            continue
        }

        $dest = & $Mapper $relForward
        if (-not $dest) {
            Write-Host "  unmapped $relForward  (no destination rule — skipping)"
            $counts.unmapped++
            continue
        }

        $isBinary = Test-IsBinary -Path $file.FullName
        $srcBytes = [System.IO.File]::ReadAllBytes($file.FullName)

        if ($Substitute -and -not $isBinary) {
            $text = [System.Text.Encoding]::UTF8.GetString($srcBytes)
            $text = $text.Replace('kanvk', $User)
            $srcBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
        }

        if (Test-Path -LiteralPath $dest) {
            $destBytes = [System.IO.File]::ReadAllBytes($dest)
            $same = ($destBytes.Length -eq $srcBytes.Length) -and
                    ([System.Linq.Enumerable]::SequenceEqual([byte[]]$destBytes, [byte[]]$srcBytes))
            if ($same) {
                Write-Host "  same     $dest"
                $counts.identical++
                continue
            }
            if ($Diff) {
                Write-Host "  diff     $dest"
                # Diff what would actually land. If a kanvk -> $User
                # substitution applied to this file, route the diff through
                # a temp file holding the substituted bytes; otherwise point
                # straight at the source for a readable header path.
                $diffSource = $file.FullName
                $tmp = $null
                if ($Substitute -and -not $isBinary) {
                    $tmp = [System.IO.Path]::GetTempFileName()
                    [System.IO.File]::WriteAllBytes($tmp, $srcBytes)
                    $diffSource = $tmp
                }
                try {
                    Write-FileDiff -Source $diffSource -Dest $dest -IsBinary $isBinary
                } finally {
                    if ($tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
                }
                $counts.written++
                continue
            }
            if (-not $script:AssumeYes -and -not $EffectiveDryRun) {
                $resp = Read-Host "  exists   $dest — overwrite? [y/N/a]"
                # `continue` inside `switch` advances to the next switch case,
                # not the outer foreach — use a flag and bail after the switch.
                $skip = $false
                switch -Regex ($resp) {
                    '^[aA]' { $script:AssumeYes = $true }
                    '^[yY]' { }
                    default { $skip = $true }
                }
                if ($skip) {
                    Write-Host "  skip     $dest"
                    $counts.skipped++
                    continue
                }
            }
            $verb = '  overwr   '
        } else {
            $verb = '  write    '
        }

        if ($EffectiveDryRun) {
            $note = if ($Diff) { '  (new — would create)' } else { '  (dry-run)' }
            Write-Host "$verb$dest$note"
            $counts.written++
            continue
        }

        # Use the .NET API for parent-dir creation: it's idempotent, creates
        # all intermediate dirs (mkdir -p semantics), and behaves consistently
        # on the WSL -> /mnt/c boundary where New-Item -Force has been flaky.
        [System.IO.Directory]::CreateDirectory((Split-Path -Parent $dest)) | Out-Null
        [System.IO.File]::WriteAllBytes($dest, $srcBytes)
        Write-Host "$verb$dest"
        $counts.written++
    }
}

Sync-Tree -Root $WindowsSource -Mapper ${function:Resolve-WindowsDest}
if ($NvimSource) {
    Sync-Tree -Root $NvimSource -Mapper ${function:Resolve-NvimDest}
}

Write-Host ''
Write-Host ("Done. written={0} identical={1} ignored={2} skipped={3} unmapped={4}" -f `
    $counts.written, $counts.identical, $counts.ignored, $counts.skipped, $counts.unmapped)
