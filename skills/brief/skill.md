---
name: brief
description: Pre-meeting preparation — loads context on who you're meeting with, what's open between you, what you owe them, and how to walk in ready. Run before any important call or meeting.
user-invocable: true
allowed-tools:
  - Read
  - Bash
---

# /brief — Meeting Prep

Prepares you for a meeting in under 2 minutes. Surfaces who you're meeting with, your history with them, what's still open, and what you owe them.

---

## How to invoke

- `/brief [name]` — prep for a meeting with a specific person
- `/brief` — prep for the next meeting on today's calendar (if connected)

---

## Step 1 — Identify who you're meeting with

If a name was provided, search `Brain/People/` for a matching file:
```bash
find "Brain/People" -name "*.md" -not -name "_template.md" | xargs grep -li "[name]" 2>/dev/null
```

If no name given, check the calendar for the next upcoming event today and extract attendee names.

---

## Step 2 — Load person context

For each attendee, read their `Brain/People/[Name].md`.

Surface:
- **Role / company** — who they are
- **Last contact** — when you last spoke; flag if > 30 days with `(⚠️ cold)`
- **Last interaction** — what was discussed last time
- **What's open** — any open items from their file
- **Open commitments** — anything you owe them (from `## Open Commitments` in their file and from `Brain/Commitments.md`)

If no People file exists: say so and note "Consider creating one after this meeting."

---

## Step 3 — Check Master.md for related tasks

Scan `Brain/Master.md` for tasks tagged with this person's name or company. Surface any relevant to today.

---

## Step 4 — Output the brief

```
🗓 MEETING BRIEF — [Name] — [Date/Time if known]

WHO
[Role], [Company]
Last contact: [date] — [what was discussed in one line]

WHAT'S OPEN
- [open item or "Nothing open — clean slate"]

YOU OWE THEM
- [Due date if any] — [commitment, or "Nothing owed"]

SUGGESTED FOCUS
[1-2 questions or topics worth raising based on history and open items]
```

Keep this under one screen. Dense is fine. Exhaustive is not.

---

## Notes

- Multiple attendees: run a block for each person, separated by a divider.
- When uncertain about any detail, mark it `(?)` rather than guessing.
- Nothing here is sent anywhere — this is read-only prep for your eyes only.
