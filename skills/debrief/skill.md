---
name: debrief
description: Post-meeting processing — paste your notes or a transcript and the system extracts commitments, updates the People file, and logs the interaction. Run immediately after any important meeting.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# /debrief — Meeting Debrief

Paste your meeting notes or a transcript. The system extracts what matters, updates the People file, and turns any promises into tracked commitments before they evaporate.

---

## How to invoke

`/debrief` — then paste notes or transcript when prompted.
Or: `/debrief [paste notes directly after the command]`

---

## Step 1 — Identify the meeting

Ask (or infer from the notes):
1. Who was the meeting with?
2. What date was it? (default: today)

Find their People file: `Brain/People/[Name].md`

---

## Step 2 — Extract commitments

Scan the notes/transcript for promise language.

**Things you committed to:**
- "I'll send...", "I'll look into...", "I'll get you...", "I'll follow up...", "Let me check on...", "I'll connect you with...", "By [date]..."

**Things they committed to:**
- "I'll send you...", "I'll get back to you...", "I'll check...", "We'll..."

For each commitment:
- Classify: mine vs. theirs
- Extract: what exactly, by when (if no date stated, default to 7 days out)
- Format: `[Due YYYY-MM-DD] What — made [today's date]`

When the language is ambiguous, mark it `(?)` rather than writing it as a firm commitment — flag it for the client to confirm.

---

## Step 3 — Update the People file

Open `Brain/People/[Name].md` and make these changes:

1. **Update `Last contact:`** to today's date
2. **Rewrite `## Last Interaction`:**
   ```
   *Date:* [today]
   *What was discussed:* [2–3 sentence summary]
   *What's open:* [bulleted list of open items]
   ```
3. **Add your commitments** to `## Open Commitments`
4. **Check off previously open items** that were resolved in this meeting

---

## Step 4 — Write commitments to Master.md

For **your commitments** — add to `Brain/Master.md` under the relevant project section:
```
- [ ] [COMMITMENT — Due YYYY-MM-DD] [What] — promised to [Name] on [date]
```

For **their commitments** — add a follow-up task:
```
- [ ] [Follow up — YYYY-MM-DD] Chase [Name] on: [what they said they'd do]
```

---

## Step 5 — Write to Commitments ledger

Append to `Brain/Commitments.md` (your commitments only):
```
- [ ] [Due YYYY-MM-DD] [What] — promised to [[Name]] — made [date]
```

---

## Step 6 — Confirm

Output a summary:
```
✅ DEBRIEF COMPLETE — [Name] — [Date]

Updated: Brain/People/[Name].md
Last contact: updated to today

YOUR COMMITMENTS ([count]):
- [list]

THEIR COMMITMENTS TO FOLLOW UP ([count]):
- [list]

Added to Master.md: [count] tasks
```

---

## Notes

- Don't invent commitments. Extract only what was actually said.
- If notes are sparse, extract what's there and note what couldn't be inferred.
- The `(?)` marker applies here — uncertain commitments get flagged, not assumed.
- Run /brief before the next meeting with this person — the People file update you just made will surface automatically.
