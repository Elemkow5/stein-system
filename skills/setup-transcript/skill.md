---
name: setup-transcript
description: Compiles the /setup interview into a structured transcript and emails it to Andrew, which triggers the AI Workflow Assessment. Run at the very end of Session 1, after /wrap.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Bash
  - mcp__*__send_gmail_message
  - mcp__*__create_draft
---

# /setup-transcript — Send Setup Interview to Andrew

Compiles the /setup interview into a structured transcript and emails it to Andrew. Triggers the AI Workflow Assessment in Andrew's system.

Run this at the end of Session 1, after /wrap completes.

---

## Instructions

### Step 1 — Load the interview materials

Read the following files:
- `Personality/[Name].md` — who they are
- `Personality/Priorities.yaml` — their strategic priorities
- `Personality/Working_Preferences.md` — how they like to work
- `Personality/Mistake_Patterns.md` — what to avoid
- `Brain/Master.md` — their initial task board
- `System/integrations.yaml` — tools and platforms connected
- The most recent file in `Brain/Session_Logs/` — the raw session record

Also read any files in `Brain/People/` and `Goals/` that were created during /setup.

### Step 2 — Compile the transcript

Compose a structured document using this format:

---

```
SETUP INTERVIEW TRANSCRIPT
Client: [Name]
Date: [today's date]
Conducted by: Andrew Wohlberg

---

WHO THEY ARE
[3-4 sentences from Personality/[Name].md — role, business, context]

THEIR WORLD
[What they do day-to-day. Key responsibilities. What takes up most of their time.]

PROJECTS IN FLIGHT
[List each active project with a 1-2 sentence description of where it stands]

GOALS
[3-year, annual, quarterly — pulled from Goals/ files]

TOP PRIORITIES
[From Priorities.yaml — what they're optimizing for right now]

PEOPLE IN THEIR WORLD
[Key contacts written during /setup — name, role, relationship context]

TOOLS AND PLATFORMS
[From integrations.yaml — what they use, what's connected, what isn't]

TIME SINKS AND FRUSTRATIONS
[Direct quotes or close paraphrases from the session log — what's costing them time, what's falling through cracks, what they'd automate first if they could]

WORKING PREFERENCES
[From Working_Preferences.md — how they like to communicate, work, be challenged]

INITIAL TASK BOARD
[From Brain/Master.md — what tasks were identified in the session]

OPEN QUESTIONS
[Anything that came up but wasn't resolved — gaps in the transcript, things worth following up on]

RAW SESSION LOG
[Full contents of the most recent Brain/Session_Logs/ file]
```

---

### Step 3 — Send the email

Send an email using the Gmail MCP with:
- **To:** awohlberg@gmail.com
- **Subject:** Interview Complete
- **Body:** The full transcript compiled in Step 2

If Gmail is not connected, tell the client: "Gmail isn't connected yet — we need to connect it before I can send this. Go to cowork.claude.ai → Integrations → Google and connect Gmail, then run `/setup-transcript` again."

### Step 4 — Confirm

Tell the client:

> "Sent. Andrew will review your interview and build out your personalized module plan. You'll hear from him before your next session."

---

## Notes

- This runs on the client's machine using their connected Gmail — the email comes from their account
- Andrew's Make.com scenario watches for subject "Interview Complete" — the exact subject line must match
- If the session log is sparse, pull more context from the Personality files — the transcript should give Andrew enough to run /intake-assess without needing the raw conversation
- Never summarize away specifics — quotes and concrete details are what make the assessment useful
