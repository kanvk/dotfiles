#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
  Install this repo's dot_config/windows/** to each tool's actual Windows
  location (komorebi root, $env:USERPROFILE\.config, $PROFILE, etc.).

.DESCRIPTION
  Designed to run from Windows pwsh — that's where $env:USERPROFILE,
  $PROFILE, and $env:KOMOREBI_CONFIG_HOME all resolve. Can run from WSL pwsh
  as a best-effort: paths are reconstructed under /mnt/c/Users/<user>/, and
  OneDrive-redirected Documents is NOT detected from WSL (run from Windows
  pwsh if your Documents lives under OneDrive).

  Path map (relative to dot_config/windows/):
    executable_komorebi.json     -> $KomorebiHome\komorebi.json
    executable_komorebi.bar.json -> $KomorebiHome\komorebi.bar.json
    powershell\profile.ps1       -> $PROFILE.CurrentUserAllHosts
    config\<rest>                -> $env:USERPROFILE\.config\<rest>  (chezmoi prefixes stripped)
    terminal\**                  -> ignored (see terminal\README.md)

  $KomorebiHome = $env:KOMOREBI_CONFIG_HOME if set, else $env:USERPROFILE.
  Files in the source tree without a mapping rule are warned and skipped.

.PARAMETER User
  Used only to substitute "kanvk" -> <User> inside text-file contents (the
  yasb config has hardcoded C:\Users\kanvk\... paths). Defaults to the
  current user. Does NOT change destination paths — those always target the
  CURRENT user's profile / pwsh state.

.PARAMETER DryRun
  Print every action without writing.

.PARAMETER Yes
  Skip the overwrite prompt for files that already exist.

.EXAMPLE
  pwsh ./install.ps1 -DryRun

.EXAMPLE
  pwsh ./install.ps1 -Yes
#>

[CmdletBinding()]
param(
    [string]$User,
    [switch]$DryRun,
    [switch]$Yes
)

# Paths/files to skip, matched against any path segment under dot_config/windows/.
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

function Resolve-Destination {
    param([Parameter(Mandatory)][string]$RelForward)
    # Single-file mappings.
    switch -CaseSensitive ($RelForward) {
        'executable_komorebi.json'     { return (Join-Path $KomorebiHome 'komorebi.json') }
        'executable_komorebi.bar.json' { return (Join-Path $KomorebiHome 'komorebi.bar.json') }
        'powershell/profile.ps1'       { return $PwshProfile }
    }
    # Subtree mapping: config/<rest> -> $XdgConfig/<rest>, chezmoi-stripped.
    if ($RelForward.StartsWith('config/')) {
        $rest = $RelForward.Substring('config/'.Length)
        $stripped = ($rest -split '/') | ForEach-Object { Convert-ChezmoiSegment $_ }
        return (Join-Path $XdgConfig ($stripped -join [System.IO.Path]::DirectorySeparatorChar))
    }
    return $null
}

$SourceRoot = $PSScriptRoot

$platform = if ($IsWindows) { 'Windows' } else { "WSL (paths under /mnt/c/Users/$User/)" }
$subNote  = if ($Substitute) { " (will substitute kanvk -> $User in text files)" } else { '' }
Write-Host "Source:         $SourceRoot"
Write-Host "Platform:       $platform"
Write-Host "User:           $User$subNote"
Write-Host "Komorebi home:  $KomorebiHome"
Write-Host "XDG .config:    $XdgConfig"
Write-Host "PWSH profile:   $PwshProfile"
Write-Host "DryRun:         $($DryRun.IsPresent)"
Write-Host "Yes:            $($Yes.IsPresent)"
Write-Host "Ignored:        $($IgnoredPaths -join ', ')"
Write-Host ''

$counts = @{ written = 0; identical = 0; ignored = 0; skipped = 0; unmapped = 0 }
$assumeYes = [bool]$Yes

foreach ($file in Get-ChildItem -Path $SourceRoot -Recurse -File -Force) {
    $rel = [System.IO.Path]::GetRelativePath($SourceRoot, $file.FullName)
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

    $dest = Resolve-Destination -RelForward $relForward
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
        if (-not $assumeYes -and -not $DryRun) {
            $resp = Read-Host "  exists   $dest — overwrite? [y/N/a]"
            # `continue` inside `switch` advances to the next switch case, not
            # the outer foreach — use a flag and bail after the switch.
            $skip = $false
            switch -Regex ($resp) {
                '^[aA]' { $assumeYes = $true }
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

    if ($DryRun) {
        Write-Host "$verb$dest  (dry-run)"
        $counts.written++
        continue
    }

    $parent = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllBytes($dest, $srcBytes)
    Write-Host "$verb$dest"
    $counts.written++
}

Write-Host ''
Write-Host ("Done. written={0} identical={1} ignored={2} skipped={3} unmapped={4}" -f `
    $counts.written, $counts.identical, $counts.ignored, $counts.skipped, $counts.unmapped)
