#!/bin/bash
# PostToolUse hook — fires when session log files are written/edited
# If new content contains a decision entry, reminds to update the project file first

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check session log files
if [[ -z "$FILE" || "$FILE" != *"Brain/Session_Logs/"* || "$FILE" != *.md ]]; then
  exit 0
fi

# Get the content being written
if [[ "$TOOL" == "Write" ]]; then
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [[ "$TOOL" == "Edit" ]]; then
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

# Fire if the new content adds a decision bullet
if echo "$NEW_CONTENT" | grep -qE "^- \[.+\].*(decided|confirmed|resolved|locked|brand|model|split|pricing|strategy)"; then
  echo "{\"hookSpecificOutput\": {\"hookEventName\": \"PostToolUse\", \"additionalContext\": \"📋 DECISION CHECK: Decision logged to session log. Project-file-first protocol: update the relevant project file now if not already done — session logs are not the authoritative project record.\"}}"
  exit 0
fi

# Also fire if writing a full session file with non-empty Decisions section
if [[ "$TOOL" == "Write" ]]; then
  if echo "$NEW_CONTENT" | grep -A 3 "^## Decisions" | grep -qE "^- "; then
    echo "{\"hookSpecificOutput\": {\"hookEventName\": \"PostToolUse\", \"additionalContext\": \"📋 DECISION CHECK: Session log has Decisions entries. Project-file-first protocol: confirm the relevant project file is updated — session logs are not the authoritative project record.\"}}"
  fi
fi
