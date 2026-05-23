#!/bin/bash
# Claude Code statusline
#
# Line 1 (always):
#   Model | dir@branch (+N -M) | ctx/max (%) | api/session | +lines/-lines | 5h %@reset | 7d %@reset [| extra $used/$limit]
#
# Line 2 (worktree sessions only):
#   name@wt-branch | dir@orig-branch | ~/orig/cwd
#
# Segment 6 fallback chain:
#   1. Native rate_limits from input JSON (after first API response)
#   2. OAuth usage API with 60s cache (before first message / session start)
#   3. Cumulative tokens + cost (API key users / no OAuth token)
#
# Dependencies: jq, git, curl (OAuth fallback only)
#
# Performance:
# - All input JSON fields extracted in a single jq call (not 15+ separate invocations)
# - Helper functions set REPLY variable instead of stdout to avoid subshell forks
# - format_tokens uses pure bash arithmetic (no awk)
# - Float rounding uses bash printf -v builtin (no awk/subprocess)
# - Git commands use --no-optional-locks to prevent lock contention
# - Here-strings (<<<) used instead of echo|pipe where possible

# set -f only: tolerate partial/missing input fields and degrade gracefully;
# -e/-u/pipefail would conflict with the script's defensive ${var:-default} idiom.
set -f # disable globbing

# ── ANSI colors (Catppuccin Macchiato, 24-bit truecolor) ────────────────────
# Variables are named by semantic role; the comment notes the Catppuccin hue.
accent='\033[38;2;198;160;246m'  # Mauve    — model name (primary accent)
tokens='\033[38;2;245;169;127m'  # Peach    — context tokens / tier-3 counts
branch='\033[38;2;166;218;149m'  # Green    — git branch, +lines, git added
path='\033[38;2;125;196;228m'    # Sapphire — dir/path, durations, worktree
removed='\033[38;2;237;135;150m' # Red      — -lines, git removed
warn='\033[38;2;238;212;159m'    # Yellow   — tier-3 cost
label='\033[38;2;183;189;248m'   # Lavender — effort brackets, rate-limit labels
dim='\033[38;2;110;115;141m'     # Overlay0 — separators, @, parens, chrome
rst='\033[0m'
sep=" ${dim}|${rst} "

# ── Tunables ────────────────────────────────────────────────────────────────
cache_max_age=60      # seconds — refresh OAuth usage data this often
stale_max_age=1800    # seconds — show stale cache up to 30min if API is down

# ── Helper functions ─────────────────────────────────────────────────────────
# Hot-path functions set REPLY instead of printing to stdout.
# This avoids subshell forks: "func; x=$REPLY" vs "x=$(func)" (the latter forks).

# Compact token display: 1234→"1234", 15234→"15.2k", 1500000→"1.5m"
# Pure bash arithmetic — no awk needed.
format_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        REPLY="$((n / 1000000)).$(((n % 1000000) / 100000))m"
    elif [ "$n" -ge 1000 ]; then
        REPLY="$((n / 1000)).$(((n % 1000) / 100))k"
    else
        REPLY="$n"
    fi
}

format_tokens_round() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        REPLY="$((n / 1000000))m"
    elif [ "$n" -ge 1000 ]; then
        REPLY="$((n / 1000))k"
    else
        REPLY="$n"
    fi
}

# Color-code a percentage: Green <50% < Yellow <70% < Peach <90% < Red
# Rounds the input defensively so floats (e.g. 95.4 from upstream) don't
# trigger "integer expected" errors and fall through to the safe (branch) tier.
# The gradient reuses palette vars: $removed = danger red (same hex as -lines),
# $tokens = peach, $warn = yellow, $branch = green. Cosmetic alias, same bytes.
usage_color() {
    local n
    LC_NUMERIC=C printf -v n '%.0f' "$1" 2>/dev/null || n=0
    if [ "$n" -ge 90 ]; then
        REPLY=$removed  # Red    237,135,150
    elif [ "$n" -ge 70 ]; then
        REPLY=$tokens   # Peach  245,169,127
    elif [ "$n" -ge 50 ]; then
        REPLY=$warn     # Yellow 238,212,159
    else
        REPLY=$branch   # Green  166,218,149
    fi
}

# Format milliseconds → compact duration: 345000→"5m45s", 8000→"8s"
fmt_dur() {
    local sec=$(($1 / 1000)) m s
    m=$((sec / 60))
    s=$((sec % 60))
    if [ "$m" -gt 0 ]; then
        REPLY="${m}m${s}s"
    else
        REPLY="${s}s"
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
    @sh "wt_orig_branch=\(.worktree.original_branch // "")",
    @sh "rl_five_pct=\(.rate_limits.five_hour.used_percentage // "")",
    @sh "rl_five_reset=\(.rate_limits.five_hour.resets_at // "")",
    @sh "rl_seven_pct=\(.rate_limits.seven_day.used_percentage // "")",
    @sh "rl_seven_reset=\(.rate_limits.seven_day.resets_at // "")",
    @sh "effort_level=\(.effort.level // "")"
' <<<"$input" 2>/dev/null)"

# Fallbacks if jq eval produced empty/missing values (e.g. malformed JSON)
: "${model_name:=Claude}" "${ctx_size:=}" "${pct_used:=}"
: "${input_tokens:=}" "${cache_create:=}" "${cache_read:=}"
: "${total_dur_ms:=}" "${api_dur_ms:=}"
: "${lines_added:=}" "${lines_removed:=}" "${total_cost:=}"
: "${total_in:=}" "${total_out:=}"
: "${rl_five_pct:=}" "${rl_five_reset:=}" "${rl_seven_pct:=}" "${rl_seven_reset:=}"
: "${effort_level:=}"

# Context window
if [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null && [ -n "$pct_used" ]; then
    current=$((${input_tokens:-0} + ${cache_create:-0} + ${cache_read:-0}))
    # Upstream sends used_percentage as a float (e.g. 50.7) — round to an int
    # before passing to the integer-comparing usage_color, and display rounded.
    LC_NUMERIC=C printf -v pct_used_int '%.0f' "$pct_used" 2>/dev/null || pct_used_int=0
else
    current="" ctx_size="" pct_used="" pct_used_int=""
fi

# ── Pre-compute display values (zero subshells — all via REPLY) ──────────────
if [ -n "$current" ]; then
    format_tokens "$current"
    ctx_used_fmt=$REPLY
else ctx_used_fmt="NA"; fi
if [ -n "$ctx_size" ]; then
    format_tokens_round "$ctx_size"
    ctx_total_fmt=$REPLY
else ctx_total_fmt="NA"; fi
if [ -n "$pct_used_int" ]; then
    usage_color "$pct_used_int"
    ctx_color=$REPLY
else ctx_color=$dim; fi
if [ -n "$api_dur_ms" ]; then
    fmt_dur "$api_dur_ms"
    api_dur_fmt=$REPLY
else api_dur_fmt="NA"; fi
if [ -n "$total_dur_ms" ]; then
    fmt_dur "$total_dur_ms"
    total_dur_fmt=$REPLY
else total_dur_fmt="NA"; fi

# Format epoch seconds → compact local time string. Native rate_limits.resets_at
# is already epoch; ISO 8601 callers go through format_reset_time → iso_to_epoch.
# Styles: "time"→"7:00pm", "datetime"→"Mar 6, 10:00am", default→"Mar 6"
# BSD branch (date -j -r) covers macOS, GNU branch (date -d @epoch) covers Linux.
# Lowercase only needed on the BSD branch — GNU's %P already emits "am/pm".
format_epoch() {
    local epoch="$1" style="$2" bsd_fmt gnu_fmt result
    { [ -z "$epoch" ] || [ "$epoch" = "null" ]; } && return
    case "$style" in
    time)     bsd_fmt='%l:%M%p'         gnu_fmt='%l:%M%P' ;;
    datetime) bsd_fmt='%b %-d, %l:%M%p' gnu_fmt='%b %-d, %l:%M%P' ;;
    *)        bsd_fmt='%b %-d'          gnu_fmt='%b %-d' ;;
    esac
    result=$(date -j -r "$epoch" +"$bsd_fmt" 2>/dev/null)
    if [ -n "$result" ]; then
        echo "$result" | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]'
    else
        date -d "@$epoch" +"$gnu_fmt" 2>/dev/null | sed 's/  / /g; s/^ //'
    fi
}

# ── OAuth token resolution ───────────────────────────────────────────────────
# Tries credential sources in priority order.
get_oauth_token() {
    # 1. Explicit env var override
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        printf '%s' "$CLAUDE_CODE_OAUTH_TOKEN"
        return 0
    fi
    local token blob
    # 2. macOS Keychain
    if command -v security >/dev/null 2>&1; then
        blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
        token=$(jq -r '.claudeAiOauth.accessToken // empty' <<<"$blob" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            printf '%s' "$token"
            return 0
        fi
    fi
    # 3. Linux credentials file
    if [ -f "$HOME/.claude/.credentials.json" ]; then
        token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            printf '%s' "$token"
            return 0
        fi
    fi
    # 4. GNOME Keyring (2s timeout to avoid hangs if keyring is locked)
    if command -v secret-tool >/dev/null 2>&1; then
        blob=$(timeout 2 secret-tool lookup service "Claude Code-credentials" 2>/dev/null)
        token=$(jq -r '.claudeAiOauth.accessToken // empty' <<<"$blob" 2>/dev/null)
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            printf '%s' "$token"
            return 0
        fi
    fi
}

# ── Fetch usage data (60s cache with atomic writes) ──────────────────────────
# Cache lives under $XDG_CACHE_HOME/claude (or ~/.cache/claude) — user-private,
# not the shared /tmp tree (which is exposed to other local users).
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude"
cache_file="$cache_dir/statusline-usage.json"

fetch_usage_data() {
    local usage_data="" has_data=false
    mkdir -p "$cache_dir" 2>/dev/null
    # Read cache if fresh enough. Guard against future mtimes (clock skew,
    # NTP correction, hostile pre-populated file) — a negative age would
    # otherwise pass the `< cache_max_age` check forever.
    if [ -f "$cache_file" ]; then
        local cache_mtime
        cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
        local age=$(($(date +%s) - ${cache_mtime:-0}))
        if [ "$age" -ge 0 ] && [ "$age" -lt "$cache_max_age" ]; then
            usage_data=$(<"$cache_file")
            has_data=true
        fi
    fi
    # Refresh from API if cache is stale
    if ! $has_data; then
        local token response
        token=$(get_oauth_token)
        if [ -n "$token" ]; then
            response=$(curl -s --max-time 5 \
                -H "Accept: application/json" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $token" \
                -H "anthropic-beta: oauth-2025-04-20" \
                -H "User-Agent: claude-code/2.1.150" \
                "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
            if [ -n "$response" ] && jq -e . <<<"$response" >/dev/null 2>&1; then
                usage_data="$response"
                has_data=true
                # Atomic write: temp file + rename prevents concurrent partial reads.
                # Silence printf's redirect error if mktemp returned empty, and
                # clean up the temp file if either write or rename fails.
                local tmp_cache
                if tmp_cache=$(mktemp "${cache_file}.XXXXXX" 2>/dev/null); then
                    if printf '%s' "$response" >"$tmp_cache" 2>/dev/null &&
                        mv "$tmp_cache" "$cache_file" 2>/dev/null; then
                        : # success
                    else
                        rm -f "$tmp_cache"
                    fi
                fi
            fi
        fi
        # Fall back to stale cache if API call failed — but cap at stale_max_age
        # so a week-old cache doesn't silently mask a week-long API outage.
        if ! $has_data && [ -f "$cache_file" ]; then
            local stale_mtime
            stale_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)
            local stale_age=$(($(date +%s) - ${stale_mtime:-0}))
            if [ "$stale_age" -ge 0 ] && [ "$stale_age" -lt "$stale_max_age" ]; then
                usage_data=$(<"$cache_file")
                has_data=true
            fi
        fi
    fi
    $has_data && printf '%s' "$usage_data"
}

# ── ISO 8601 → epoch (cross-platform) ───────────────────────────────────────
iso_to_epoch() {
    local iso_str="$1" epoch
    # GNU date (Linux) — handles ISO 8601 natively
    epoch=$(date -d "$iso_str" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi
    # BSD date (macOS) — strip fractional seconds and timezone suffix
    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"
    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
    fi
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi
    return 1
}

# Format ISO 8601 timestamp → compact local time string (thin wrapper around
# format_epoch). Styles same as format_epoch.
format_reset_time() {
    local iso_str="$1" style="$2" epoch
    { [ -z "$iso_str" ] || [ "$iso_str" = "null" ]; } && return
    epoch=$(iso_to_epoch "$iso_str") || return
    format_epoch "$epoch" "$style"
}

# ── Build output string ─────────────────────────────────────────────────────
out=""

# Segment 1: Model [effort]
if [ -n "$effort_level" ]; then
    out+="${accent}${model_name}${rst} ${label}[${effort_level}]${rst}"
else
    out+="${accent}${model_name}${rst}"
fi

# Segment 2: workspace dir@branch (+added -removed)
# --no-optional-locks prevents git from writing lock files that block other processes
if [ -n "$cwd" ]; then
    out+="${sep}${path}${cwd##*/}${rst}"
    git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$git_branch" ]; then
        out+="${dim}@${rst}${branch}${git_branch}${rst}"
        git_stat=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null |
            awk '{a+=$1; d+=$2} END {if (a+d>0) printf "+%d -%d", a, d}')
        if [ -n "$git_stat" ]; then
            out+=" ${dim}(${rst}${branch}${git_stat%% *}${rst} ${removed}${git_stat##* }${rst}${dim})${rst}"
        fi
        wt_count=$(git -C "$cwd" --no-optional-locks worktree list --porcelain 2>/dev/null | grep -c '^worktree ')
        if [ "${wt_count:-0}" -ge 2 ]; then
            out+=" ${dim}(wt:${wt_count})${rst}"
        fi
    fi
fi

# Segment 3: Context window — tokens / max (color-coded %)
out+="${sep}${tokens}${ctx_used_fmt}${dim}/${rst}${tokens}${ctx_total_fmt}${rst}"
if [ -n "$pct_used_int" ]; then
    out+=" ${dim}(${rst}${ctx_color}${pct_used_int}%${rst}${dim})${rst}"
else
    out+=" ${dim}(${rst}${ctx_color}NA${rst}${dim})${rst}"
fi

# Segment 4: API response time / total session wall-clock time
out+="${sep}${path}${api_dur_fmt}${rst}${dim}/${rst}${path}${total_dur_fmt}${rst}"

# Segment 5: Lines added/removed (jq's `// 0` guarantees both are non-empty)
out+="${sep}${branch}+${lines_added}${rst}${dim}/${rst}${removed}-${lines_removed}${rst}"

# ── Segment 6: Rate limits (3-tier fallback) ─────────────────────────────────
# 1. Native rate_limits from input JSON (after first API response)
# 2. OAuth usage API (before first message / session start)
# 3. Cumulative tokens + cost (API key users / no OAuth token)

if [ -n "$rl_five_pct" ] || [ -n "$rl_seven_pct" ]; then
    # ── Tier 1: Native rate_limits fields ────────────────────────────────────
    # 5-hour rate limit with reset time
    if [ -n "$rl_five_pct" ]; then
        LC_NUMERIC=C printf -v five_pct_int '%.0f' "$rl_five_pct" 2>/dev/null
        usage_color "$five_pct_int"
        five_color=$REPLY
        out+="${sep}${label}5h${rst} ${five_color}${five_pct_int}%${rst}"
        if [ -n "$rl_five_reset" ]; then
            five_reset=$(format_epoch "$rl_five_reset" "time")
            [ -n "$five_reset" ] && out+=" ${dim}@${five_reset}${rst}"
        fi
    fi

    # 7-day rate limit with reset datetime
    if [ -n "$rl_seven_pct" ]; then
        LC_NUMERIC=C printf -v seven_pct_int '%.0f' "$rl_seven_pct" 2>/dev/null
        usage_color "$seven_pct_int"
        seven_color=$REPLY
        out+="${sep}${label}7d${rst} ${seven_color}${seven_pct_int}%${rst}"
        if [ -n "$rl_seven_reset" ]; then
            seven_reset=$(format_epoch "$rl_seven_reset" "datetime")
            [ -n "$seven_reset" ] && out+=" ${dim}@${seven_reset}${rst}"
        fi
    fi

else
    # ── Tier 2: OAuth usage API fallback (session start, before first message) ──
    usage_data=$(fetch_usage_data)

    if [ -n "$usage_data" ]; then
        eval "$(jq -r '
            @sh "five_hour_pct=\(.five_hour.utilization // 0)",
            @sh "five_hour_reset_iso=\(.five_hour.resets_at // "")",
            @sh "seven_day_pct=\(.seven_day.utilization // 0)",
            @sh "seven_day_reset_iso=\(.seven_day.resets_at // "")",
            @sh "extra_enabled=\(.extra_usage.is_enabled // false)",
            @sh "extra_pct=\(.extra_usage.utilization // 0)",
            @sh "extra_used=\(.extra_usage.used_credits // 0 | floor)",
            @sh "extra_limit=\(.extra_usage.monthly_limit // 0 | floor)"
        ' <<<"$usage_data" 2>/dev/null)"

        # Defensive defaults — if the jq above failed (malformed JSON, jq missing,
        # etc.) the eval is a no-op and none of these vars get set.
        : "${five_hour_pct:=0}"
        : "${five_hour_reset_iso:=}"
        : "${seven_day_pct:=0}"
        : "${seven_day_reset_iso:=}"
        : "${extra_enabled:=false}"
        : "${extra_pct:=0}"
        : "${extra_used:=0}"
        : "${extra_limit:=0}"

        LC_NUMERIC=C printf -v five_hour_pct '%.0f' "$five_hour_pct" 2>/dev/null
        LC_NUMERIC=C printf -v seven_day_pct '%.0f' "$seven_day_pct" 2>/dev/null

        # 5-hour rate limit with reset time
        usage_color "$five_hour_pct"
        five_hour_color=$REPLY
        out+="${sep}${label}5h${rst} ${five_hour_color}${five_hour_pct}%${rst}"
        five_hour_reset=$(format_reset_time "$five_hour_reset_iso" "time")
        [ -n "$five_hour_reset" ] && out+=" ${dim}@${five_hour_reset}${rst}"

        # 7-day rate limit with reset datetime
        usage_color "$seven_day_pct"
        seven_day_color=$REPLY
        out+="${sep}${label}7d${rst} ${seven_day_color}${seven_day_pct}%${rst}"
        seven_day_reset=$(format_reset_time "$seven_day_reset_iso" "datetime")
        [ -n "$seven_day_reset" ] && out+=" ${dim}@${seven_day_reset}${rst}"

        # Extra usage credits (only shown when enabled on the account)
        if [ "$extra_enabled" = "true" ]; then
            LC_NUMERIC=C printf -v extra_pct_int '%.0f' "${extra_pct:-0}" 2>/dev/null
            # Credits are in cents — pure-bash int division for the dollars part,
            # printf builtin for the zero-padded cents. No awk fork needed.
            extra_used_fmt="$((extra_used / 100)).$(printf '%02d' "$((extra_used % 100))")"
            extra_limit_fmt="$((extra_limit / 100)).$(printf '%02d' "$((extra_limit % 100))")"
            if [ -n "$extra_used_fmt" ] && [ -n "$extra_limit_fmt" ]; then
                usage_color "$extra_pct_int"
                extra_color=$REPLY
                out+="${sep}${label}extra${rst} ${extra_color}\$${extra_used_fmt}/\$${extra_limit_fmt}${rst}"
            else
                out+="${sep}${label}extra${rst} ${branch}enabled${rst}"
            fi
        fi

    else
        # ── Tier 3: API key fallback — cumulative session tokens and cost ────
        if [ -n "$total_in" ]; then
            format_tokens "$total_in"
            in_fmt=$REPLY
        else in_fmt="NA"; fi
        if [ -n "$total_out" ]; then
            format_tokens "$total_out"
            out_fmt=$REPLY
        else out_fmt="NA"; fi
        out+="${sep}${dim}in: ${rst}${tokens}${in_fmt}${rst}"
        out+=" ${dim}out: ${rst}${tokens}${out_fmt}${rst}"
        if [ -n "$total_cost" ]; then
            LC_NUMERIC=C printf -v cost_fmt '%.2f' "$total_cost" 2>/dev/null
            out+="${sep}${warn}\$${cost_fmt}${rst}"
        else
            out+="${sep}${dim}NA${rst}"
        fi
    fi
fi

# ── Line 2 (worktree, conditional) ────────────────────────────────────────────
if [ -n "$wt_name" ]; then
    wt_line="${path}${wt_name}${rst}"
    [ -n "$wt_branch" ] && wt_line+="${dim}@${rst}${branch}${wt_branch}${rst}"
    if [ -n "$wt_orig_cwd" ] || [ -n "$wt_orig_branch" ]; then
        wt_line+="${sep}${path}${wt_orig_cwd##*/}${rst}"
        [ -n "$wt_orig_branch" ] && wt_line+="${dim}@${rst}${branch}${wt_orig_branch}${rst}"
    fi
    if [ -n "$wt_orig_cwd" ]; then
        orig_path="${wt_orig_cwd/#$HOME/\~}"
        wt_line+="${sep}${dim}${orig_path}${rst}"
    fi
    out+="\n${wt_line}"
fi

# ── Output ───────────────────────────────────────────────────────────────────
printf '%b' "$out"
exit 0
