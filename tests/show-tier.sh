#!/usr/bin/env bash
#
# Print the resolved package set for a named tier.
#   ./tests/show-tier.sh minimal
#   ./tests/show-tier.sh full
#
# Walks inherits, unions include, subtracts exclude — same logic the install
# script uses. Reads the tier from $1 (passed via the TIER env var into the
# rendered template, since `chezmoi execute-template` doesn't take data flags
# the way a script's stdin does).

set -euo pipefail

TIER="${1:-full}"

cd "$(dirname "$0")/.."

TIER="$TIER" chezmoi execute-template <<'TMPL'
{{- $tier := env "TIER" -}}
{{- $resolved := includeTemplate "resolve-tier" (dict "tier" $tier "tiers" .tiers "acc" dict) | fromJson -}}
=== tier: {{ $tier }} ===
{{ range $mgr, $pkgs := $resolved -}}
{{ $mgr }} ({{ len $pkgs }}): {{ $pkgs | join " " }}
{{ end -}}
TMPL
