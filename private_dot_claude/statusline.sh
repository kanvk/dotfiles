#!/bin/bash
# Claude Code statusline
#
# Line 1 (always):
#   Subscription:
#     Model (effort) | dir@branch (+N -M) | ctx/max (%) | api/session | +lines/-lines | 5h %@reset | 7d %@reset [| extra $used/$limit]
#   API key:
#     Model (effort) | dir@branch (+N -M) | ctx/max (%) | api/session | +lines/-lines | in:Nk out:Nk | $cost
#
# Line 2 (worktree sessions only):
#   name@wt-branch | dir@orig-branch | ~/orig/cwd
#
# Mode auto-detection: if the OAuth usage API returns data → subscription mode
# (show 5h/7d rate limits); otherwise → API key mode (show cumulative tokens + cost).
#
# Dependencies: jq, git, curl (subscription mode only)
# Cache: /tmp/claude/statusline-usage-cache.json (60s TTL, atomic writes)
#
# Performance:
# - All input JSON fields extracted in a single jq call (not 15+ separate invocations)
# - Helper functions set REPLY variable instead of stdout to avoid subshell forks
# - format_tokens uses pure bash arithmetic (no awk)
# - Float rounding uses bash printf -v builtin (no awk/subprocess)
# - Git commands use --no-optional-locks to prevent lock contention
# - Here-strings (<<<) used instead of echo|pipe where possible

set -f  # disable globbing

# ── ANSI colors (standard 16-color, terminal theme adaptive) ────────────────
blue='\033[94m'
orange='\033[33m'
green='\033[32m'
cyan='\033[36m'
red='\033[91m'
yellow='\033[93m'
white='\033[97m'
gray='\033[90m'
rst='\033[0m'
sep=" ${gray}|${rst} "

# ── Helper functions ─────────────────────────────────────────────────────────
# Hot-path functions set REPLY instead of printing to stdout.
# This avoids subshell forks: "func; x=$REPLY" vs "x=$(func)" (the latter forks).

# Compact token display: 1234→"1234", 15234→"15.2k", 1500000→"1.5m"
# Pure bash arithmetic — no awk needed.
format_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        REPLY="$(( n / 1000000 )).$(( (n % 1000000) / 100000 ))m"
    elif [ "$n" -ge 1000 ]; then
        REPLY="$(( n / 1000 )).$(( (n % 1000) / 100 ))k"
    else
        REPLY="$n"
    fi
}

format_tokens_round() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        REPLY="$(( n / 1000000 ))m"
    elif [ "$n" -ge 1000 ]; then
        REPLY="$(( n / 1000 ))k"
    else
        REPLY="$n"
    fi
}

# Color-code a percentage: green <50% < yellow <70% < orange <90% < red
usage_color() {
    if   [ "$1" -ge 90 ]; then REPLY=$red
    elif [ "$1" -ge 70 ]; then REPLY=$orange
    elif [ "$1" -ge 50 ]; then REPLY=$yellow
    else REPLY=$green
    fi
}

# Format milliseconds → compact duration: 345000→"5m45s", 8000→"8s"
fmt_dur() {
    local sec=$(( $1 / 1000 )) m s
    m=$(( sec / 60 )); s=$(( sec % 60 ))
    if [ "$m" -gt 0 ]; then REPLY="${m}m${s}s"
    else REPLY="${s}s"
    fi
}

# ── Read stdin ───────────────────────────────────────────────────────────────
input=$(cat)
if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ── Extract all fields from input JSON (single jq invocation) ────────────────
# jq's @sh produces shell-escaped assignments; eval sets them as variables.
# Using <<< (here-string) instead of echo|pipe avoids an extra subprocess.
eval "$(jq -r '
    @sh "model_name=\(.model.display_name // "Claude")",
    @sh "cwd=\(.workspace.current_dir // .cwd // "")",
    @sh "ctx_size=\(.context_window.context_window_size // 0)",
    @sh "pct_used=\(.context_window.used_percentage // 0)",
    @sh "input_tokens=\(.context_window.current_usage.input_tokens // 0)",
    @sh "cache_create=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
    @sh "cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)",
    @sh "total_in=\(.context_window.total_input_tokens // 0)",
    @sh "total_out=\(.context_window.total_output_tokens // 0)",
    @sh "total_dur_ms=\(.cost.total_duration_ms // 0)",
    @sh "api_dur_ms=\(.cost.total_api_duration_ms // 0)",
    @sh "lines_added=\(.cost.total_lines_added // 0)",
    @sh "lines_removed=\(.cost.total_lines_removed // 0)",
    @sh "total_cost=\(.cost.total_cost_usd // 0)",
    @sh "wt_name=\(.worktree.name // "")",
    @sh "wt_branch=\(.worktree.branch // "")",
    @sh "wt_orig_cwd=\(.worktree.original_cwd // "")",
    @sh "wt_orig_branch=\(.worktree.original_branch // "")"
' <<< "$input" 2>/dev/null)"

# Fallbacks if jq eval produced empty/missing values (e.g. malformed JSON)
: "${model_name:=Claude}" "${ctx_size:=}" "${pct_used:=}"
: "${input_tokens:=}" "${cache_create:=}" "${cache_read:=}"
: "${total_dur_ms:=}" "${api_dur_ms:=}"
: "${lines_added:=}" "${lines_removed:=}" "${total_cost:=}"
: "${total_in:=}" "${total_out:=}"

# Context window
if [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null && [ -n "$pct_used" ]; then
    current=$(( ${input_tokens:-0} + ${cache_create:-0} + ${cache_read:-0} ))
else
    current="" ctx_size="" pct_used=""
fi

# ── Effort level (env var takes precedence over settings.json) ───────────────
effort_level="high"
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
    effort_level="$CLAUDE_CODE_EFFORT_LEVEL"
elif [ -f "$HOME/.claude/settings.json" ]; then
    effort_val=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
    [ -n "$effort_val" ] && effort_level="$effort_val"
fi

# ── Pre-compute display values (zero subshells — all via REPLY) ──────────────
if [ -n "$current" ]; then format_tokens "$current"; ctx_used_fmt=$REPLY; else ctx_used_fmt="NA"; fi
if [ -n "$ctx_size" ]; then format_tokens_round "$ctx_size"; ctx_total_fmt=$REPLY; else ctx_total_fmt="NA"; fi
if [ -n "$pct_used" ]; then usage_color "$pct_used"; ctx_color=$REPLY; else ctx_color=$gray; fi
if [ -n "$api_dur_ms" ]; then fmt_dur "$api_dur_ms"; api_dur_fmt=$REPLY; else api_dur_fmt="NA"; fi
if [ -n "$total_dur_ms" ]; then fmt_dur "$total_dur_ms"; total_dur_fmt=$REPLY; else total_dur_fmt="NA"; fi

# ── Build output string ─────────────────────────────────────────────────────
out=""

# Segment 1: Model (effort) — green/orange/red for low/med/high
out+="${blue}${model_name}${rst} ${gray}(${rst}"
case "$effort_level" in
    low)    out+="${green}low${rst}" ;;
    medium) out+="${orange}med${rst}" ;;
    *)      out+="${red}high${rst}" ;;
esac
out+="${gray})${rst}"

# Segment 2: workspace dir@branch (+added -removed)
# --no-optional-locks prevents git from writing lock files that block other processes
if [ -n "$cwd" ]; then
    out+="${sep}${cyan}${cwd##*/}${rst}"
    git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$git_branch" ]; then
        out+="${gray}@${rst}${green}${git_branch}${rst}"
        git_stat=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null \
            | awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        if [ -n "$git_stat" ]; then
            out+=" ${gray}(${rst}${green}${git_stat%% *}${rst} ${red}${git_stat##* }${rst}${gray})${rst}"
        fi
    fi
fi

# Segment 3: Context window — tokens / max (color-coded %)
out+="${sep}${orange}${ctx_used_fmt}${gray}/${rst}${orange}${ctx_total_fmt}${rst}"
if [ -n "$pct_used" ]; then
    out+=" ${gray}(${rst}${ctx_color}${pct_used}%${rst}${gray})${rst}"
else
    out+=" ${gray}(${rst}${ctx_color}NA${rst}${gray})${rst}"
fi

# Segment 4: API response time / total session wall-clock time
out+="${sep}${cyan}${api_dur_fmt}${rst}${gray}/${rst}${cyan}${total_dur_fmt}${rst}"

# Segment 5: Lines added/removed
if [ -n "$lines_added" ]; then la_fmt="+${lines_added}"; else la_fmt="NA"; fi
if [ -n "$lines_removed" ]; then lr_fmt="-${lines_removed}"; else lr_fmt="NA"; fi
out+="${sep}${green}${la_fmt}${rst}${gray}/${rst}${red}${lr_fmt}${rst}"

# ── OAuth token resolution ───────────────────────────────────────────────────
# Tries credential sources in priority order.
get_oauth_token() {
    # 1. Explicit env var override
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN"; return 0
    fi
    local token blob
    # 2. macOS Keychain
    if command -v security >/dev/null 2>&1; then
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        token=$(jq -r '.claudeAiOauth.accessToken // empty' <<< "$blob" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then printf '%s' "$token"; return 0; fi
    fi
    # 3. Linux credentials file
    if [ -f "$HOME/.claude/.credentials.json" ]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then printf '%s' "$token"; return 0; fi
    fi
    # 4. GNOME Keyring (2s timeout to avoid hangs if keyring is locked)
    if command -v secret-tool >/dev/null 2>&1; then
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        token=$(jq -r '.claudeAiOauth.accessToken // empty' <<< "$blob" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then printf '%s' "$token"; return 0; fi
    fi
}

# ── Fetch usage data (60s cache with atomic writes) ──────────────────────────
cache_file="/tmp/claude/statusline-usage-cache.json"
cache_max_age=60
usage_data=""
has_usage_data=false

mkdir -p /tmp/claude 2>/dev/null

# Read cache if fresh enough
if [ -f "$cache_file" ]; then
    cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
    if [ $(( $(date +%s) - cache_mtime )) -lt "$cache_max_age" ]; then
        usage_data=$(<"$cache_file")
        has_usage_data=true
    fi
fi

# Refresh from API if cache is stale
if ! $has_usage_data; then
    token=$(get_oauth_token)
    if [ -n "$token" ]; then
        response=$(curl -s --max-time 5 \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            -H "User-Agent: claude-code/2.1.34" \
            "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        if [ -n "$response" ] && jq -e . <<< "$response" >/dev/null 2>&1; then
            usage_data="$response"
            has_usage_data=true
            # Atomic write: temp file + rename prevents concurrent partial reads
            tmp_cache=$(mktemp "${cache_file}.XXXXXX" 2>/dev/null) \
                && printf '%s' "$response" > "$tmp_cache" \
                && mv "$tmp_cache" "$cache_file"
        fi
    fi
    # Fall back to stale cache if API call failed
    if ! $has_usage_data && [ -f "$cache_file" ]; then
        usage_data=$(<"$cache_file")
        has_usage_data=true
    fi
fi

# ── ISO 8601 → epoch (cross-platform) ───────────────────────────────────────
iso_to_epoch() {
    local iso_str="$1" epoch
    # GNU date (Linux) — handles ISO 8601 natively
    epoch=$(date -d "$iso_str" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then echo "$epoch"; return 0; fi
    # BSD date (macOS) — strip fractional seconds and timezone suffix
    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"; stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"
    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi
    if [ -n "$epoch" ]; then echo "$epoch"; return 0; fi
    return 1
}

# Format ISO timestamp → compact local time string
# Styles: "time"→"7:00pm", "datetime"→"Mar 6, 10:00am", default→"Mar 6"
format_reset_time() {
    local iso_str="$1" style="$2" epoch result
    [ -z "$iso_str" ] || [ "$iso_str" = "null" ] && return
    epoch=$(iso_to_epoch "$iso_str") || return
    # Try BSD date (capture to check success), then GNU date fallback
    case "$style" in
        time)
            result=$(date -j -r "$epoch" +"%l:%M%p" 2>/dev/null)
            if [ -n "$result" ]; then echo "$result" | sed 's/^ //' | tr '[:upper:]' '[:lower:]'
            else date -d "@$epoch" +"%l:%M%P" 2>/dev/null | sed 's/^ //'
            fi ;;
        datetime)
            result=$(date -j -r "$epoch" +"%b %-d, %l:%M%p" 2>/dev/null)
            if [ -n "$result" ]; then echo "$result" | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]'
            else date -d "@$epoch" +"%b %-d, %l:%M%P" 2>/dev/null | sed 's/  / /g; s/^ //'
            fi ;;
        *)
            result=$(date -j -r "$epoch" +"%b %-d" 2>/dev/null)
            if [ -n "$result" ]; then echo "$result" | tr '[:upper:]' '[:lower:]'
            else date -d "@$epoch" +"%b %-d" 2>/dev/null
            fi ;;
    esac
}

# ── Segment 6: Rate limits (subscription) or tokens+cost (API key) ──────────
if $has_usage_data; then
    # Subscription mode — extract all usage fields (single jq call, here-string)
    eval "$(jq -r '
        @sh "five_hour_pct=\(.five_hour.utilization // 0)",
        @sh "five_hour_reset_iso=\(.five_hour.resets_at // "")",
        @sh "seven_day_pct=\(.seven_day.utilization // 0)",
        @sh "seven_day_reset_iso=\(.seven_day.resets_at // "")",
        @sh "extra_enabled=\(.extra_usage.is_enabled // false)",
        @sh "extra_pct=\(.extra_usage.utilization // 0)",
        @sh "extra_used=\(.extra_usage.used_credits // 0)",
        @sh "extra_limit=\(.extra_usage.monthly_limit // 0)"
    ' <<< "$usage_data" 2>/dev/null)"

    LC_NUMERIC=C printf -v five_hour_pct '%.0f' "${five_hour_pct:-0}" 2>/dev/null
    LC_NUMERIC=C printf -v seven_day_pct '%.0f' "${seven_day_pct:-0}" 2>/dev/null

    # 5-hour rate limit with reset time
    usage_color "$five_hour_pct"; five_hour_color=$REPLY
    out+="${sep}${white}5h${rst} ${five_hour_color}${five_hour_pct}%${rst}"
    five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
    [ -n "$five_hour_reset" ] && out+=" ${gray}@${five_hour_reset}${rst}"

    # 7-day rate limit with reset datetime
    usage_color "$seven_day_pct"; seven_day_color=$REPLY
    out+="${sep}${white}7d${rst} ${seven_day_color}${seven_day_pct}%${rst}"
    seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
    [ -n "$seven_day_reset" ] && out+=" ${gray}@${seven_day_reset}${rst}"

    # Extra usage credits (only shown when enabled on the account)
    if [ "$extra_enabled" = "true" ]; then
        LC_NUMERIC=C printf -v extra_pct_int '%.0f' "${extra_pct:-0}" 2>/dev/null
        # Credits are in cents — divide by 100 for dollars (needs awk for float division)
        extra_used_fmt=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", ${extra_used:-0}/100}" 2>/dev/null)
        extra_limit_fmt=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", ${extra_limit:-0}/100}" 2>/dev/null)
        if [ -n "$extra_used_fmt" ] && [ -n "$extra_limit_fmt" ] \
           && [[ "$extra_used_fmt" != *'$'* ]] && [[ "$extra_limit_fmt" != *'$'* ]]; then
            usage_color "$extra_pct_int"; extra_color=$REPLY
            out+="${sep}${white}extra${rst} ${extra_color}\$${extra_used_fmt}/\$${extra_limit_fmt}${rst}"
        else
            out+="${sep}${white}extra${rst} ${green}enabled${rst}"
        fi
    fi
else
    # API key mode — cumulative session tokens and cost
    if [ -n "$total_in" ]; then format_tokens "$total_in"; in_fmt=$REPLY; else in_fmt="NA"; fi
    if [ -n "$total_out" ]; then format_tokens "$total_out"; out_fmt=$REPLY; else out_fmt="NA"; fi
    out+="${sep}${gray}in:${rst}${orange}${in_fmt}${rst}"
    out+=" ${gray}out:${rst}${orange}${out_fmt}${rst}"
    if [ -n "$total_cost" ]; then
        LC_NUMERIC=C printf -v cost_fmt '%.2f' "$total_cost" 2>/dev/null
        out+="${sep}${yellow}\$${cost_fmt}${rst}"
    else
        out+="${sep}${gray}NA${rst}"
    fi
fi

# ── Line 2 (worktree, conditional) ────────────────────────────────────────────
if [ -n "$wt_name" ]; then
    wt_line="${cyan}${wt_name}${rst}"
    [ -n "$wt_branch" ] && wt_line+="${gray}@${rst}${green}${wt_branch}${rst}"
    if [ -n "$wt_orig_cwd" ] || [ -n "$wt_orig_branch" ]; then
        wt_line+="${sep}${cyan}${wt_orig_cwd##*/}${rst}"
        [ -n "$wt_orig_branch" ] && wt_line+="${gray}@${rst}${green}${wt_orig_branch}${rst}"
    fi
    if [ -n "$wt_orig_cwd" ]; then
        orig_path="${wt_orig_cwd/#$HOME/\~}"
        wt_line+="${sep}${gray}${orig_path}${rst}"
    fi
    out+="\n${wt_line}"
fi

# ── Output ───────────────────────────────────────────────────────────────────
printf '%b' "$out"
exit 0
