#!/bin/bash
# PreToolUse:Bash hook — safety guard.
# Blocks destructive commands before they run. Exit 0 = allow, exit 2 = block.
# Mirrors Dex's dex-safety-guard.sh pattern, tightened for Stein's single-vault
# client deployment (no migration lock, no scraper-preference logic).

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

block() {
  echo "{\"decision\":\"block\",\"reason\":\"$1\"}"
  exit 2
}

warn() {
  echo "{\"decision\":\"allow\",\"reason\":\"WARNING: $1\"}"
  exit 0
}

# === HARD BLOCKS ===

# Recursive delete targeting root, home, or a user's home directory.
# Checked as two conditions (recursive+force flags present, AND a root-like
# target) rather than one combined regex — anchoring a flag pattern directly
# against a target pattern is brittle when the target is the last token on
# the line (e.g. "rm -rf ~" has nothing trailing the "~" to anchor on).
HAS_RF_FLAGS=0
if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]])rm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|-r\s+-f|-f\s+-r|--recursive.*--force|--force.*--recursive)'; then
  HAS_RF_FLAGS=1
fi

if [[ "$HAS_RF_FLAGS" == "1" ]] && echo "$COMMAND" | grep -qE '(^|[[:space:]])(/|~|"\$HOME"|\$HOME|/Users(/[^[:space:]]*)?)([[:space:]]|$)'; then
  block "Blocked: recursive delete targeting root, home, or /Users"
fi

if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+/([[:space:]]|$)'; then
  block "Blocked: rm -rf /"
fi

# Disk wiping / formatting
if echo "$COMMAND" | grep -qiE '(diskutil\s+eraseDisk|mkfs\s|dd\s+if=)'; then
  block "Blocked: disk wipe/format command"
fi

# Force push to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)'; then
  block "Blocked: force push to main/master"
fi
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*\s+(main|master).*--force'; then
  block "Blocked: force push to main/master"
fi

# SQL destruction
if echo "$COMMAND" | grep -qiE '(DROP\s+TABLE|DROP\s+DATABASE)'; then
  block "Blocked: SQL DROP command"
fi

# GitHub repo deletion
if echo "$COMMAND" | grep -qE 'gh\s+repo\s+delete'; then
  block "Blocked: GitHub repo deletion"
fi

# Protected client content — never delete or overwrite Personality/ via shell.
# Mirrors CLAUDE.md's "Protected content rule": the client's own words are
# always off limits to silent overwrite. Edits via the Edit/Write tools still
# go through normal review; this only blocks raw shell destruction.
if echo "$COMMAND" | grep -qE '(rm|mv)\s+.*Personality/'; then
  block "Blocked: shell command targeting Personality/ — this is protected client content. Use the Edit tool if a change is actually needed."
fi

# === WARNINGS (allow but flag) ===

if echo "$COMMAND" | grep -qE 'chmod\s+777'; then
  warn "chmod 777 grants full permissions to all users. Consider more restrictive permissions."
fi

if echo "$COMMAND" | grep -qE 'kill\s+-9'; then
  warn "kill -9 force-terminates without cleanup. Ensure this is the intended process."
fi

# === DEFAULT: ALLOW ===
exit 0
