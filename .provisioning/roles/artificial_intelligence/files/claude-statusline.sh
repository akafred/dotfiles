#!/usr/bin/env bash
# Claude Code status line.
# Line 1: where/what  — time, dir, git, model · effort, fast mode
# Line 2: meters      — context · cache · session time │ cost │ rate limits
# Colors stay dim until a value needs attention (yellow ≥50%, red ≥80%).

input=$(cat)

US=$'\x1f'
IFS="$US" read -r cwd model effort fast ctx_pct ctx_used ctx_size cost dur_ms added removed \
  cache_warm cache_hit five_pct five_reset week_pct week_reset <<<"$(jq -r '
  def n: if . == null then "" else tostring end;
  [ .workspace.current_dir // .cwd,
    .model.display_name,
    .effort.level,
    (.fast_mode // false),
    (.context_window.used_percentage
       // (if (.context_window.context_window_size // 0) > 0
           then .context_window.total_input_tokens * 100 / .context_window.context_window_size
           else null end)),
    .context_window.total_input_tokens,
    .context_window.context_window_size,
    .cost.total_cost_usd,
    .cost.total_duration_ms,
    .cost.total_lines_added,
    .cost.total_lines_removed,
    .prompt_cache.warm,
    .prompt_cache.hit_ratio,
    .rate_limits.five_hour.used_percentage,
    .rate_limits.five_hour.resets_at,
    .rate_limits.seven_day.used_percentage,
    .rate_limits.seven_day.resets_at
  ] | map(n) | join("\u001f")' <<<"$input" 2>/dev/null)"

R=$'\033[0m'; DIM=$'\033[2m'; YEL=$'\033[0;33m'; RED=$'\033[0;31m'; GRN=$'\033[0;32m'
SEP=" ${DIM}│${R} "

# Color for a percentage: dim/green below 50, yellow 50–79, red 80+.
level_color() { # $1=int pct, $2=color when low
  if [ "$1" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$1" -ge 50 ]; then printf '%s' "$YEL"
  else printf '%s' "$2"; fi
}

# 63735 -> 64k, 1000000 -> 1M, 1500000 -> 1.5M
human() {
  awk -v x="$1" 'BEGIN {
    if (x >= 1000000) { s = sprintf("%.1f", x/1000000); sub(/\.0$/, "", s); print s "M" }
    else printf "%dk\n", (x/1000) + 0.5 }'
}

# ── Line 1 ────────────────────────────────────────────────────────────────
line1=$(printf '\033[0;33m[%s]\033[0m \033[1;32m➜\033[0m \033[0;36m%s\033[0m' "$(date +%H:%M:%S)" "$(basename "$cwd")")
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo detached)
  line1+=$(printf ' \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m' "$branch")
  if ! { git -C "$cwd" -c core.useBuiltinFSMonitor=false diff --quiet 2>/dev/null &&
         git -C "$cwd" -c core.useBuiltinFSMonitor=false diff --cached --quiet 2>/dev/null; }; then
    line1+=" ${YEL}✗${R}"
  fi
fi
if [ "${added:-0}${removed:-0}" != "00" ] && [ -n "$added$removed" ]; then
  line1+=" ${GRN}+${added:-0}${R}${DIM}/${R}${RED}−${removed:-0}${R}"
fi
m="$model${effort:+ · $effort}"
line1+=$(printf ' \033[0;35m[%s]\033[0m' "$m")
[ "$fast" = "true" ] && line1+=" ${YEL}⚡fast${R}"

# ── Line 2 ────────────────────────────────────────────────────────────────
segs=()

# Context: 8-cell bar + percent + used/size
if [ -n "$ctx_pct" ]; then
  p=$(printf '%.0f' "$ctx_pct")
  c=$(level_color "$p" "$GRN")
  filled=$(( (p * 8 + 50) / 100 )); [ "$filled" -gt 8 ] && filled=8
  bar=""; for ((i=0; i<8; i++)); do [ $i -lt $filled ] && bar+="▰" || bar+="▱"; done
  s="${DIM}ctx${R} ${c}${bar} ${p}%${R}"
  [ -n "$ctx_used" ] && [ -n "$ctx_size" ] && s+=" ${DIM}$(human "$ctx_used")/$(human "$ctx_size")${R}"
fi

# Cache belongs with context: hit ratio while warm; loud when cold (next request re-reads everything)
cache_s=""
if [ "$cache_warm" = "false" ]; then
  cache_s="${YEL}cache cold${R}"
elif [ -n "$cache_hit" ]; then
  cache_s="${DIM}cache $(printf '%.0f' "$(awk -v x="$cache_hit" 'BEGIN{print x*100}')")%${R}"
fi
if [ -n "$cache_s" ]; then s+="${s:+ ${DIM}·${R} }$cache_s"; fi

# Session length follows the cache in the same group
if [ -n "$dur_ms" ]; then
  mins=$(( ${dur_ms%.*} / 60000 ))
  if [ "$mins" -ge 60 ]; then dur_s="$((mins/60))h$(printf '%02d' $((mins%60)))m"; else dur_s="${mins}m"; fi
  s+="${s:+ ${DIM}·${R} }${DIM}${dur_s}${R}"
fi
[ -n "$s" ] && segs+=("$s")

# Cost on its own
[ -n "$cost" ] && segs+=("${DIM}$(printf '$%.2f' "$cost")${R}")

# Rate limits: 5h · 7d; show reset time once a limit reaches 50%
lim() { # $1=label $2=pct $3=reset epoch $4=reset date format
  [ -z "$2" ] && return
  local p; p=$(printf '%.0f' "$2")
  local c; c=$(level_color "$p" "$DIM")
  local out="${c}$1 ${p}%${R}"
  if [ "$p" -ge 50 ] && [ -n "$3" ]; then out+=" ${DIM}↻$(date -r "${3%.*}" "$4" 2>/dev/null)${R}"; fi
  printf '%s' "$out"
}
l5=$(lim 5h "$five_pct" "$five_reset" +%H:%M)
l7=$(lim 7d "$week_pct" "$week_reset" '+%a %H:%M')
lims="$l5${l5:+${l7:+ ${DIM}·${R} }}$l7"
[ -n "$lims" ] && segs+=("$lims")

printf '%s' "$line1"
if [ ${#segs[@]} -gt 0 ]; then
  out=""; for s in "${segs[@]}"; do out+="${out:+$SEP}$s"; done
  printf '\n%s' "$out"
fi
