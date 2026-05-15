#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
  Mirror this repo's dot_config/windows/** tree to ~\.config\windows\ on a
  Windows host (or via /mnt/c from WSL). Strips chezmoi name prefixes and,
  when -User is set to something other than "kanvk", substitutes "kanvk"
  → target username inside text file contents.

.PARAMETER User
  Target Windows username. Defaults to $env:USERNAME on Windows and to $env:USER
  on Linux (final fallback: "kanvk").

.PARAMETER DryRun
  Print every action without writing.

.PARAMETER Yes
  Skip the overwrite prompt for files that already exist.

.EXAMPLE
  pwsh ./install.ps1 -DryRun

.EXAMPLE
  pwsh ./install.ps1 -User alice -Yes
#>

[CmdletBinding()]
param(
    [string]$User,
    [switch]$DryRun,
    [switch]$Yes
)

# Relative paths under dot_config/windows/ to skip entirely. Match is against
# any path segment, so "terminal" skips dot_config/windows/terminal/**.
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

# NUL-byte sniff on the first 8 KB. Good enough to keep .ico / .png out of the
# text-substitution path; the only "binary" file in this tree today is a stub.
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

function Resolve-DestRoot {
    param([Parameter(Mandatory)][string]$WinUser)
    if ($IsWindows) {
        return Join-Path $env:SystemDrive ("\Users\$WinUser\.config\windows")
    } else {
        # WSL / Linux invocation: target the Windows mount.
        return "/mnt/c/Users/$WinUser/.config/windows"
    }
}

# --- main --------------------------------------------------------------------

if (-not $User) {
    if ($IsWindows -and $env:USERNAME) { $User = $env:USERNAME }
    elseif ($env:USER) { $User = $env:USER }
    else { $User = 'kanvk' }
}

$SourceRoot = $PSScriptRoot
$DestRoot   = Resolve-DestRoot -WinUser $User
$Substitute = ($User -ne 'kanvk')

Write-Host "Source:    $SourceRoot"
Write-Host "Dest:      $DestRoot"
Write-Host "User:      $User$(if ($Substitute) { ' (will substitute kanvk -> ' + $User + ' in text files)' })"
Write-Host "DryRun:    $($DryRun.IsPresent)"
Write-Host "Yes:       $($Yes.IsPresent)"
Write-Host "Ignored:   $($IgnoredPaths -join ', ')"
Write-Host ''

$counts = @{ written = 0; identical = 0; ignored = 0; skipped = 0 }

# `assumeYes` starts as -Yes and can be flipped on mid-run by answering "a".
$assumeYes = [bool]$Yes

foreach ($file in Get-ChildItem -Path $SourceRoot -Recurse -File -Force) {
    $rel = [System.IO.Path]::GetRelativePath($SourceRoot, $file.FullName)
    $relForward = $rel -replace '\\', '/'

    # Don't act on this script itself.
    if ($file.FullName -eq $PSCommandPath) { continue }

    # Ignore-list check (segment-wise match on the un-stripped path).
    $segments = $relForward -split '/'
    $ignored = $false
    foreach ($seg in $segments) {
        if ($IgnoredPaths -contains $seg) { $ignored = $true; break }
    }
    if ($ignored) {
        Write-Host "  ignore  $relForward"
        $counts.ignored++
        continue
    }

    # Strip chezmoi prefixes from each segment, then rebuild the dest path.
    $destSegments = $segments | ForEach-Object { Convert-ChezmoiSegment $_ }
    $destRel = $destSegments -join [System.IO.Path]::DirectorySeparatorChar
    $dest = Join-Path $DestRoot $destRel

    $isBinary = Test-IsBinary -Path $file.FullName
    $srcBytes = [System.IO.File]::ReadAllBytes($file.FullName)

    if ($Substitute -and -not $isBinary) {
        # UTF-8 round-trip; preserves whatever line endings the source has.
        $text = [System.Text.Encoding]::UTF8.GetString($srcBytes)
        $text = $text.Replace('kanvk', $User)
        $srcBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    }

    if (Test-Path -LiteralPath $dest) {
        $destBytes = [System.IO.File]::ReadAllBytes($dest)
        $same = ($destBytes.Length -eq $srcBytes.Length) -and
                ([System.Linq.Enumerable]::SequenceEqual([byte[]]$destBytes, [byte[]]$srcBytes))
        if ($same) {
            Write-Host "  same    $destRel"
            $counts.identical++
            continue
        }
        if (-not $assumeYes -and -not $DryRun) {
            $resp = Read-Host "  exists  $destRel — overwrite? [y/N/a]"
            # `continue` inside `switch` advances to the next switch case, not
            # the outer foreach — use a flag and bail after the switch.
            $skip = $false
            switch -Regex ($resp) {
                '^[aA]' { $assumeYes = $true }
                '^[yY]' { }
                default { $skip = $true }
            }
            if ($skip) {
                Write-Host "  skip    $destRel"
                $counts.skipped++
                continue
            }
        }
        $verb = '  overwr '
    } else {
        $verb = '  write  '
    }

    if ($DryRun) {
        Write-Host "$verb$destRel  (dry-run)"
        $counts.written++
        continue
    }

    $parent = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [System.IO.File]::WriteAllBytes($dest, $srcBytes)
    Write-Host "$verb$destRel"
    $counts.written++
}

Write-Host ''
Write-Host ("Done. written={0} identical={1} ignored={2} skipped={3}" -f `
    $counts.written, $counts.identical, $counts.ignored, $counts.skipped)
