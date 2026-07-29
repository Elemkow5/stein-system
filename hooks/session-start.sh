#!/bin/bash

# Session Start Hook
# Fires ONCE per session on the SessionStart event — not on every prompt.
# Injects the client's context before the first response.
# Uses vault-relative paths — no hardcoded locations.
#
# Registered under SessionStart in settings.json. Do not move it back to
# UserPromptSubmit: that re-ran this whole block AND the context-index rebuild
# on every single message, which quietly burned context all session long.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"

INBOX="$VAULT_ROOT/Brain/Inbox.md"
SESSIONS_DIR="$VAULT_ROOT/Brain/Session_Logs"
TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%Hh%M")
DAY_OF_WEEK=$(date +"%A")

# Staging dir — per-vault, inside .claude/
STAGING_DIR="$VAULT_ROOT/.claude/staging"
mkdir -p "$STAGING_DIR"
> "$STAGING_DIR/surfaced_this_session.txt"

echo "=== SESSION START ==="
echo "Date: $TODAY ($DAY_OF_WEEK)"
echo ""

# ── Self-heal: the vault skeleton must exist ─────────────────────────────────
# A direct clone has no Brain/, Personality/ or Goals/ — those are gitignored
# and shipped blank in _skeleton/. Install them rather than running on a vault
# with no files to write into.
if [[ ! -d "$VAULT_ROOT/Brain" && -d "$VAULT_ROOT/_skeleton" ]]; then
  SKELETON_QUIET=1 bash "$VAULT_ROOT/System/Scripts/install-skeleton.sh" "$VAULT_ROOT" 2>/dev/null
  echo "--- SKELETON INSTALLED ---"
  echo "Vault folders were missing and have been created from _skeleton/."
  echo ""
fi

# ── Unfinished setup ─────────────────────────────────────────────────────────
if [[ -f "$VAULT_ROOT/System/.setup_progress" ]]; then
  echo "--- SETUP INCOMPLETE ---"
  echo "⚠ System/.setup_progress exists — onboarding didn't finish."
  cat "$VAULT_ROOT/System/.setup_progress"
  echo "Offer to resume /setup before anything else."
  echo ""
fi

# ── Detect the client's name from the Personality identity file ──────────────
# /setup writes Personality/[Name].md with the real name as the first H1.
CLIENT_NAME="there"
for f in "$VAULT_ROOT/Personality/"*.md; do
  [[ -e "$f" ]] || continue
  basename_f=$(basename "$f")
  if [[ "$basename_f" == "Mistake_Patterns.md" || "$basename_f" == "Working_Preferences.md" ]]; then
    continue
  fi
  FIRST_H1=$(grep -m1 "^# " "$f" 2>/dev/null | sed 's/^# //')
  if [[ -n "$FIRST_H1" && "$FIRST_H1" != "[Name]"* ]]; then
    CLIENT_NAME="${FIRST_H1%% —*}"
  fi
  break
done

# ── Core context ─────────────────────────────────────────────────────────────
# Behavioural files only. The identity file (Personality/[Name].md) loads ON
# DEMAND per CLAUDE.md — naming it here would pull it into every session and
# undo the lean-startup design.
echo "--- CORE CONTEXT ---"
echo "Per CLAUDE.md: Read Personality/Working_Preferences.md and Personality/Mistake_Patterns.md now."
echo ""

# ── Last session file ────────────────────────────────────────────────────────
# Sort by modification time and exclude INDEX.md. Sorting by NAME returns
# INDEX.md every time (I sorts before any digit), which loads the whole
# archive instead of the last session.
mkdir -p "$SESSIONS_DIR"
LAST_SESSION=$(ls -t "$SESSIONS_DIR"/*.md 2>/dev/null | grep -v "INDEX.md" | head -1)

echo "--- SESSION CONTINUITY ---"
if [[ -n "$LAST_SESSION" ]]; then
  echo "Last session file: Brain/Session_Logs/$(basename "$LAST_SESSION")"
  echo "Read it for recent context. That is the only session file to read at startup."
else
  echo "No previous sessions — this is session 1."
fi
echo ""
echo "ACTION REQUIRED: create this session's file at:"
echo "Brain/Session_Logs/${TODAY}-${NOW}.md"
echo "Populate its Context section from the previous session file."
echo ""

# ── Inbox ────────────────────────────────────────────────────────────────────
if [[ -f "$INBOX" ]]; then
  INBOX_ITEMS=$(grep -c "^- \[ \]" "$INBOX" 2>/dev/null || echo "0")
  if [[ "$INBOX_ITEMS" -gt 0 ]]; then
    echo "--- INBOX ---"
    echo "⚠ $INBOX_ITEMS unprocessed item(s) in Brain/Inbox.md"
    grep "^- \[ \]" "$INBOX" | head -5
    if [[ "$INBOX_ITEMS" -gt 5 ]]; then
      echo "  ... and $((INBOX_ITEMS - 5)) more"
    fi
    echo ""
  fi
fi

# ── Day-of-week nudges ───────────────────────────────────────────────────────
if [[ "$DAY_OF_WEEK" == "Monday" ]]; then
  echo "--- MONDAY ---"
  echo "📋 Start of the week. Consider /checkin → weekly to set priorities."
  echo ""
fi
if [[ "$DAY_OF_WEEK" == "Friday" ]]; then
  echo "--- FRIDAY ---"
  echo "📋 End of week. Consider /wrap to close out open threads."
  echo ""
fi

# ── Greeting ─────────────────────────────────────────────────────────────────
echo "--- GREETING ---"
echo "Open with: \"Hi ${CLIENT_NAME} — [surface any flags above]. What are we working on?\""
echo ""

# ── Context injection index ──────────────────────────────────────────────────
NODE_BIN=$(command -v node 2>/dev/null || echo "node")
INDEX_SCRIPT="$VAULT_ROOT/.claude/hooks/build-context-index.js"
if [[ -f "$INDEX_SCRIPT" ]]; then
  "$NODE_BIN" "$INDEX_SCRIPT" 2>/dev/null || echo "[context-index] Build failed — skipping"
fi

echo "=== READY ==="
