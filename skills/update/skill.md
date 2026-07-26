---
name: update
description: Pull the latest system updates (skills, hooks, CLAUDE.md) from the Stein system repo. Run this when Andrew tells you a new version is available or something isn't working right.
user-invocable: true
allowed-tools:
  - Bash
  - Read
---

# /update — Pull System Updates

Pulls the latest skills, hooks, and CLAUDE.md from the Stein system repo. Client data is never touched — only system files update.

---

## Step 1 — Check Current Version

Run:
```bash
cd .claude && git log --oneline -3
```

Note the current commit hash and message so you can show what changed.

---

## Step 2 — Pull Updates

Run:
```bash
git submodule update --remote .claude
```

If this fails (network error, auth issue), stop and report the error clearly. Do not attempt to fix git config — that's Andrew's job.

---

## Step 3 — Show What Changed

Run:
```bash
cd .claude && git log --oneline ORIG_HEAD..HEAD 2>/dev/null || git log --oneline -5
```

List what updated — skill names, hook changes, CLAUDE.md updates. One line per change.

If nothing changed: "Already up to date — no updates available."

---

## Step 4 — Confirm

Tell the client:
- What updated (or that they're current)
- That their personal data (Brain/, Personality/, Goals/) was not touched
- "The new version is active — no restart needed."
