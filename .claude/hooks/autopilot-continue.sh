#!/usr/bin/env bash
# Stop hook: while autopilot is on, keep Claude working through docs/plan.md
# one task at a time. Lets Claude stop when autopilot is off, the plan is done,
# Claude reported BLOCKED:, or the continuation cap is reached.
set -euo pipefail

input=$(cat)
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
flag="$root/.claude/autopilot.on"
plan="$root/docs/plan.md"
counter="$root/.claude/.autopilot-count"
max="${OHANA_AUTOPILOT_MAX:-25}"

stop_autopilot() {
  rm -f "$flag" "$counter"
  jq -n --arg m "Autopilot stopped: $1" '{systemMessage: $m}'
  exit 0
}

[ -f "$flag" ] || exit 0
[ -f "$plan" ] || stop_autopilot "docs/plan.md not found"

last=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""')
if printf '%s' "$last" | grep -q 'BLOCKED:'; then
  stop_autopilot "Claude reported BLOCKED"
fi

next=$(grep -m1 -E '^[[:space:]]*- \[ \] ' "$plan" | sed -E 's/^[[:space:]]*- \[ \] //' || true)
[ -n "$next" ] || stop_autopilot "all tasks in docs/plan.md are done"

count=$(( $(cat "$counter" 2>/dev/null || echo 0) + 1 ))
[ "$count" -le "$max" ] || stop_autopilot "reached $max steps (OHANA_AUTOPILOT_MAX)"
echo "$count" > "$counter"

jq -n --arg t "$next" --arg n "$count/$max" '{
  decision: "block",
  reason: ("Autopilot step " + $n + ". Next task in docs/plan.md: \"" + $t + "\". Follow the Autopilot workflow in CLAUDE.md. If it needs the human, reply with BLOCKED: <reason>.")
}'
