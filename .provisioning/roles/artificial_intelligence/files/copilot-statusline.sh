#!/usr/bin/env bash
# Copilot CLI status line.
# Line 1: where/what  — time, host, dir, git (+uncommitted), session lines, effort · tier, remote
# Line 2: meters      — context · left · cache · duration │ api time │ tokens
# Line 3: session     — name, remote task, version, monthly AIC budget (only when present)
# Colors stay dim until a value needs attention (yellow ≥50%, red ≥80%).

input=$(cat)

US=$'\x1f'
IFS="$US" read -r cwd tier effort ctx_pct ctx_used ctx_size ctx_left \
  cache_read cache_write cur_in tot_in tot_out tot_reason \
  dur_ms api_ms added removed sname version \
  remote rtask rpr <<<"$(jq -r '
  def n: if . == null then "" else tostring end;
  [ .workspace.current_dir // .cwd,
    (.model.auto_tier // .model.pending_auto_tier),
    (.model.reasoning_effort // .model.effort),
    (.context_window.current_context_used_percentage // .context_window.used_percentage),
    (.context_window.current_context_tokens // .context_window.total_tokens),
    (.context_window.displayed_context_limit // .context_window.context_window_size),
    (if .context_window.remaining_tokens != null then
       .context_window.remaining_tokens
     elif .context_window.current_context_tokens != null
        and .context_window.displayed_context_limit != null then
       "<" + (([0, (.context_window.displayed_context_limit - .context_window.current_context_tokens)] | max) | tostring)
     else .context_window.remaining_tokens end),
    .context_window.current_usage.cache_read_input_tokens,
    .context_window.current_usage.cache_creation_input_tokens,
    .context_window.current_usage.input_tokens,
    .context_window.total_input_tokens,
    .context_window.total_output_tokens,
    .context_window.total_reasoning_tokens,
    .cost.total_duration_ms,
    .cost.total_api_duration_ms,
    .cost.total_lines_added,
    .cost.total_lines_removed,
    .session_name,
    .version,
    (.remote.connected // false),
    .remote.task_name,
    .remote.pull_request_number
  ] | map(n) | join("\u001f")' <<<"$input" 2>/dev/null)"

[ -z "$cwd" ] && cwd=$PWD
[ -z "$effort" ] && effort=$(jq -r '.effortLevel // empty' ~/.copilot/settings.json 2>/dev/null)

R=$'\033[0m'; DIM=$'\033[2m'; YEL=$'\033[0;33m'; RED=$'\033[0;31m'; GRN=$'\033[0;32m'
SEP=" ${DIM}│${R} "

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

# 125000 ms -> 2m, 3900000 -> 1h05m
fmt_dur() {
  local mins=$(( ${1%.*} / 60000 ))
  if [ "$mins" -ge 60 ]; then printf '%dh%02dm' $((mins/60)) $((mins%60)); else printf '%dm' "$mins"; fi
}

# ── Line 1 ────────────────────────────────────────────────────────────────
line1=$(printf '\033[0;33m[%s]\033[0m \033[2m%s\033[0m \033[1;32m➜\033[0m \033[0;36m%s\033[0m' "$(date +%H:%M:%S)" "$(hostname -s)" "$(basename "$cwd")")
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo detached)
  line1+=$(printf ' \033[1;34mgit:(\033[0;31m%s\033[1;34m)\033[0m' "$branch")
  # Uncommitted lines (staged + unstaged), shown after the dirty marker
  read -r ua ur < <(git -C "$cwd" -c core.useBuiltinFSMonitor=false diff HEAD --numstat 2>/dev/null |
    awk '$1 != "-" { a += $1; r += $2 } END { print a + 0, r + 0 }')
  if [ "${ua:-0}" -gt 0 ] || [ "${ur:-0}" -gt 0 ]; then
    line1+=" ${YEL}✗${R} ${DIM}Δ${R}${GRN}+${ua}${R}${DIM}/${R}${RED}−${ur}${R}"
  elif ! git -C "$cwd" -c core.useBuiltinFSMonitor=false diff --cached --quiet 2>/dev/null; then
    line1+=" ${YEL}✗${R}"
  fi
fi
# Lines written during this session
if [ "${added:-0}${removed:-0}" != "00" ] && [ -n "$added$removed" ]; then
  line1+=" ${GRN}+${added:-0}${R}${DIM}/${R}${RED}−${removed:-0}${R}"
fi
if [ -n "$effort$tier" ]; then
  m="$effort${effort:+${tier:+ · }}$tier"
  line1+=$(printf ' \033[0;35m[%s]\033[0m' "$m")
fi
if [ "$remote" = "true" ]; then
  line1+=" ${YEL}☁${R}"
  [ -n "$rpr" ] && line1+="${DIM} PR#${rpr}${R}"
fi

# ── Line 2 ────────────────────────────────────────────────────────────────
segs=()
s=""
if [ -n "$ctx_pct" ]; then
  p=$(printf '%.0f' "$ctx_pct")
  c=$(level_color "$p" "$GRN")
  filled=$(( (p * 8 + 50) / 100 )); [ "$filled" -gt 8 ] && filled=8
  bar=""; for ((i=0; i<8; i++)); do [ $i -lt $filled ] && bar+="▰" || bar+="▱"; done
  s="${DIM}ctx${R} ${c}${bar} ${p}%${R}"
  [ -n "$ctx_used" ] && [ -n "$ctx_size" ] && s+=" ${DIM}$(human "$ctx_used")/$(human "$ctx_size")${R}"
  if [ -n "$ctx_left" ]; then
    if [[ "$ctx_left" == \<* ]]; then
      s+=" ${DIM}(<$(human "${ctx_left#<}") left)${R}"
    else
      s+=" ${DIM}($(human "$ctx_left") left)${R}"
    fi
  fi
fi

# Cache hit ratio of the latest call: read / (fresh + read + written)
if [ -n "$cache_read" ]; then
  total=$(( ${cache_read:-0} + ${cache_write:-0} + ${cur_in:-0} ))
  if [ "$total" -gt 0 ]; then
    hit=$(( cache_read * 100 / total ))
    if [ "$hit" -lt 20 ]; then cache_s="${YEL}cache ${hit}%${R}"; else cache_s="${DIM}cache ${hit}%${R}"; fi
    s+="${s:+ ${DIM}·${R} }$cache_s"
  fi
fi

[ -n "$dur_ms" ] && s+="${s:+ ${DIM}·${R} }${DIM}$(fmt_dur "$dur_ms")${R}"
[ -n "$s" ] && segs+=("$s")

# Time spent waiting on the API
[ -n "$api_ms" ] && [ "${api_ms%.*}" -ge 60000 ] && segs+=("${DIM}api $(fmt_dur "$api_ms")${R}")

# Cumulative tokens: in ↑ / out ↓ / reasoning ∴
if [ -n "$tot_in" ] || [ -n "$tot_out" ]; then
  t="${DIM}↑$(human "${tot_in:-0}") ↓$(human "${tot_out:-0}")"
  [ -n "$tot_reason" ] && t+="($(human "$tot_reason")∴)"
  segs+=("${t}${R}")
fi

# Monthly AIC budget: unofficial endpoint, cached 5 min, refreshed in the background
qf="$HOME/.copilot/.statusline-quota"
if [ ! -s "$qf" ] || [ -n "$(find "$qf" -mmin +5 2>/dev/null)" ]; then
  ( gh api copilot_internal/user -q '.quota_snapshots.premium_interactions | select(.entitlement > 0) | [.credits_used, .entitlement] | @tsv' >"$qf.tmp" 2>/dev/null \
      && [ -s "$qf.tmp" ] && mv "$qf.tmp" "$qf"; rm -f "$qf.tmp" ) </dev/null >/dev/null 2>&1 &
fi
[ -r "$qf" ] && read -r q_used q_total <"$qf"

# ── Line 3 ────────────────────────────────────────────────────────────────
meta=()
[ -n "$sname" ] && meta+=("$sname")
[ -n "$rtask" ] && meta+=("$rtask")
[ -n "$version" ] && meta+=("v$version")

printf '%s' "$line1"
if [ ${#segs[@]} -gt 0 ]; then
  out=""; for s in "${segs[@]}"; do out+="${out:+$SEP}$s"; done
  printf '\n%s' "$out"
fi
# 5064 -> "5 064"
group() { awk -v x="$1" 'BEGIN { s = x ""; while (length(s) > 3) { r = " " substr(s, length(s) - 2) r; s = substr(s, 1, length(s) - 3) } print s r }'; }
out=""; for s in "${meta[@]}"; do out+="${out:+ · }$s"; done
[ -n "$out" ] && out="${DIM}${out}${R}"
if [ -n "$q_total" ] && [ "$q_total" -gt 0 ]; then
  qp=$(( (q_used * 100 + q_total / 2) / q_total ))
  out+="${out:+ ${DIM}·${R} }$(level_color "$qp" "$DIM")$(group "$q_used") of $(group "$q_total") AIC (${qp} %)${R}"
fi
[ -n "$out" ] && printf '\n%s' "$out"
