---
name: seed
description: One-time onboarding step — runs after /import-setup, before /lets-go. Enriches People stubs and projects with 30 days of real interaction history from connected sources, discovers contacts and topics not mentioned in the setup interview, and writes a passive seed report for the client to review.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - mcp__*__search_threads
  - mcp__*__get_thread
  - mcp__*__list_events
  - mcp__*__search_events
  - mcp__*__slack_read_channel
  - mcp__*__slack_read_thread
  - mcp__*__slack_search_public
  - mcp__*__slack_search_public_and_private
  - mcp__*__search_gmail_messages
  - mcp__*__get_gmail_message_content
---

# /seed — Onboarding Data Backfill

Runs once during onboarding, after `/import-setup` and before `/lets-go`. Takes the People stubs and project entries from the interview and enriches them with real interaction history. Also discovers contacts and topics the client didn't mention. Writes a passive report the client reviews on their own time.

**Email is required.** Calendar, Slack, and Drive are optional — the skill runs on whatever is connected and skips the rest silently.

**Mode:** Non-interactive during the run. One report written at the end. No questions asked mid-skill.

---

## Step 1 — Read Configuration

Read `System/integrations.yaml`. Extract every service block.

Set:
```
SEED_WINDOW_DAYS = 30
SEED_START_DATE = today's date minus 30 days (format: YYYY-MM-DD)
SEED_END_DATE = today's date
```

All source searches in Steps 3–8 use `SEED_START_DATE` as the lookback boundary.

Build the active source list — a source is **active** only if `enabled: true` AND `mcp_server` is set (non-empty). Mark each:
- Email: ✅ active / ❌ missing
- Calendar: ✅ active / ⏭ skipped
- Slack: ✅ active / ⏭ skipped
- Drive folder: ✅ active / ⏭ skipped (active if `inbox_folder.local_path` is non-empty)

**If email is not active — abort immediately:**
> "/seed requires an email integration to run. Gmail or Outlook isn't connected yet.
>
> To connect: open Claude Desktop → click + → Connectors → connect Google or Microsoft.
>
> Once connected, run /seed again."

Stop here. Do not proceed.

**If email is active — announce and continue:**
> "Starting /seed. Window: [SEED_START_DATE] → [SEED_END_DATE].
> Active sources: [list active sources]
> Skipping: [list inactive sources]"

---

## Step 2 — Load Known Entities

Read all files in `Brain/People/`. For each file, extract:
- Full name (from the `# [Full Name]` header)
- Email address (from `**Email:**` field, if already captured)
- Company (from `**Company:**` field, if present)

Build `KNOWN_PEOPLE` list: `[{name, email_if_known, company_if_known, filename}]`

Read `Brain/Master.md`. Extract all project names — these are `##` section headers (e.g., `## Project Apollo` → `Project Apollo`). Skip generic sections: `## Today`, `## This Week`, `## Tasks`, `## Backlog`, `## Parking Lot`, `## Commitments`.

Build `KNOWN_PROJECTS` list: `[project name strings]`

Note the counts — used in Step 11 summary.

---

## Step 3 — Pass 1: Enrich People Files from Email

*Skip this step entirely if email is not active — it always is (required), so this always runs.*

For each person in `KNOWN_PEOPLE`:

**Search:**
- If email address known: search `from:[email] OR to:[email]` since `SEED_START_DATE`
- If email address not known: search `from:"[Full Name]" OR to:"[Full Name]"` since `SEED_START_DATE`
- Cap results at 50 threads per person

**For each thread found:**
- Extract: date, subject line, sender, snippet/summary, any action language ("will send", "can you", "by Friday", "following up", "I owe you")
- Capture email address from thread if not already in `KNOWN_PEOPLE` entry — save it

**If 1+ threads found:**

Update the People file. Identify the most recent thread. Write:

```markdown
## Last Interaction
*Date:* [YYYY-MM-DD]
*Channel:* Email — "[Subject]"
*Summary:* [1 sentence — what the thread was about]
*Open:* [action item if detected, else "(none identified)"]
```

Then write or update `## Interaction History` — last 3–5 threads as dated bullets, most recent first:
```markdown
## Interaction History
- [YYYY-MM-DD] Email — "[Subject]" — [one-phrase summary]
- [YYYY-MM-DD] Email — "[Subject]" — [one-phrase summary]
```

If `**Email:**` field in the People file is empty and you captured an address, add it:
```
**Email:** [captured address]
```

**If 0 threads found:** Leave the People file as-is. Note this person in the seed report under "People With No Recent Activity."

---

## Step 4 — Pass 1: Enrich People Files from Calendar

*Skip entirely if calendar is not active.*

For each person in `KNOWN_PEOPLE`:

Search past calendar events since `SEED_START_DATE` where their name appears as an attendee.

For each event found:
- Extract: date, event title, attendees, event description (if present)

**If 1+ events found:**

Append to `## Interaction History` in their People file (insert above existing email entries if the event is more recent):
```markdown
- [YYYY-MM-DD] Calendar — "[Event Title]" — [attendees if more than 2 people, else omit]
```

If the most recent calendar event is newer than the most recent email: update `## Last Interaction` to reflect the calendar event instead:
```markdown
## Last Interaction
*Date:* [YYYY-MM-DD]
*Channel:* Calendar — "[Event Title]"
*Summary:* [1 sentence from event description, or "Meeting with [name]" if no description]
*Open:* (none identified)
```

**If 0 events found:** Skip. Do not modify the People file.

---

## Step 5 — Pass 1: Enrich People Files from Slack

*Skip entirely if Slack is not active.*

For each person in `KNOWN_PEOPLE`:

Search DMs with that person since `SEED_START_DATE`. Also search public channels for messages from that person.

Filter to surface only: direct questions, decisions, action items, direct mentions. Skip: reactions, one-word replies, "sounds good", "thanks".

For each relevant message found:
- Extract: date, channel (DM or #channel-name), message summary

**If 1+ messages found:**

Append to `## Interaction History`:
```markdown
- [YYYY-MM-DD] Slack ([DM or #channel]) — [one-phrase summary]
```

If more recent than existing Last Interaction: update `## Last Interaction`.

**If 0 messages found:** Skip.

---

## Step 6 — Pass 1: Enrich Projects from All Active Sources

For each project in `KNOWN_PROJECTS`:

**Email:** Search for subject lines or snippets mentioning the project name since `SEED_START_DATE`. Cap at 20 results per project.

**Calendar (if active):** Search event titles mentioning the project name since `SEED_START_DATE`.

**Slack (if active):** Search messages mentioning the project name since `SEED_START_DATE`.

**If any activity found across any source:**

Open `Brain/Master.md`. Find the `## [Project Name]` section. Insert a `### Recent Activity (from /seed)` block immediately after the section header:

```markdown
### Recent Activity (from /seed — [SEED_START_DATE] to [SEED_END_DATE])
[List each item, most recent first:]
- [YYYY-MM-DD] Email — "[Subject]" with [sender/recipient name]
- [YYYY-MM-DD] Calendar — "[Event Title]" with [attendees]
- [YYYY-MM-DD] Slack — [summary]
```

**If 0 activity found:** Note in seed report as "no recent activity found." Do not modify Master.md.

---

## Step 7 — Pass 2: Discover New People

Collect all sender names and email addresses seen across all active sources in the last 30 days (from the threads/events/messages already pulled in Steps 3–5 — do not make additional API calls).

Filter out:
- Anyone already in `KNOWN_PEOPLE` (by name or email)
- Obvious noise: addresses or display names containing: `no-reply`, `noreply`, `newsletter`, `notifications`, `donotreply`, `support@`, `hello@`, `info@`, `billing@`, `admin@`, `mailer`, `unsubscribe`, `mailchimp`, `sendgrid`, `hubspot`, `linkedin`, `twitter`, `facebook`, common calendar system senders

Count appearances per remaining name across all sources.

**For each name appearing 3 or more times:**

Create `Brain/People/[FirstName]_[LastName].md`:

```markdown
# [Full Name]
**Role:** (not captured — discovered by /seed)
**Company:** [if inferable from email domain or context]
**Email:** [email address if captured]
**Relationship type:** (to fill in)
**Discovered by:** /seed on [YYYY-MM-DD] — not yet reviewed

---

## Last Interaction
*Date:* [most recent appearance date]
*Channel:* [Email / Calendar / Slack] — "[subject or event title]"
*Summary:* [1-line summary]
*Open:* (none identified)

---

## Interaction History
[last 3 appearances, most recent first:]
- [YYYY-MM-DD] [Channel] — "[subject/title]"
- [YYYY-MM-DD] [Channel] — "[subject/title]"
- [YYYY-MM-DD] [Channel] — "[subject/title]"

---

## Notes
(to fill in)

---

## Open Items
- [ ]

---

## Open Commitments
<!-- Format: - [ ] [Due YYYY-MM-DD] What — made YYYY-MM-DD -->
```

Track: list of names created, for the seed report.

**If name is ambiguous** (first name only, or very common name like "John" with no last name or email): skip. Do not create a file for an unidentifiable contact.

---

## Step 8 — Pass 2: Surface Topic and Project Candidates

From the threads, events, and messages already collected in Steps 3–6, extract recurring terms:
- Email: subject line text (strip Re:, Fwd:, common prefixes)
- Calendar: event title text (strip "Meeting:", "Call:", "Sync:", "1:1:", "Intro:")
- Slack: channel names and topic keywords

Filter out:
- Names already captured (people, known projects)
- Generic noise: Meeting, Call, Sync, Follow Up, Quick Chat, Catch Up, Hello, Thanks, FYI, Introduction, Schedule, Reschedule

Count occurrences per remaining term across all sources.

Collect terms appearing **3 or more times** that do not match any name in `KNOWN_PEOPLE` or any project in `KNOWN_PROJECTS`.

**Do not create any files.** This list goes to the seed report only — the client decides what to do with it.

---

## Step 9 — Drive Folder Ingest

*Skip entirely if `inbox_folder.local_path` is empty or the path does not exist.*

```bash
ls "[inbox_folder.local_path]"
```

If the folder exists and has files:

For each file:
- Attempt to read it (supports: .md, .txt, .pdf, .docx — use Read tool)
- If readable: extract key content — what is this document, what does it say about the business, services, people, or processes?
- If unreadable (format not supported, encrypted, etc.): note as ⚠️ in seed report, skip

Append extracted content to `Brain/Business.md` under `## Additional Context`. Add one subsection per document:

```markdown
### [Filename] (ingested [YYYY-MM-DD])
**Type:** [Pitch deck / SOP / Proposal / Bio / Other]
[Extracted content — key facts, services, pricing, process, voice/language, people mentioned. Do not dump full text — summarize and extract facts.]
```

Track: list of filenames with status (✅ read / ⚠️ could not read).

---

## Step 10 — Write Brain/seed-report.md

Save to `Brain/seed-report.md`:

```markdown
# /seed Report — [YYYY-MM-DD]
*Sources used: [comma-separated list of active sources]*
*Window: [SEED_START_DATE] → [SEED_END_DATE]*

---

## New People Found (not mentioned in setup)

These contacts appeared frequently in your [sources] and have been added to Brain/People/.
Review each file — add their role, how you know them, and any open items.

[For each discovered People file created:]
- **[Name]** — [email if captured] — appeared [N] times across [sources] → [Brain/People/filename.md]

[If none:]
No new contacts discovered above the threshold (3+ appearances).

---

## People With No Recent Activity

These people were mentioned in your setup interview but had no matching email, calendar,
or Slack activity in the last 30 days. They may use a different email address, or contact
may have been infrequent recently.

[For each person from the interview with 0 matches:]
- **[Name]** — no activity found in [sources checked]

[If none:]
All setup contacts had at least one interaction in the last 30 days.

---

## Project Activity Found

[For each project in KNOWN_PROJECTS:]
- **[Project Name]** — [N] email threads · [N] calendar events · [N] Slack mentions → added to Brain/Master.md

[For each project with 0 activity:]
- **[Project Name]** — no recent activity found in connected sources

---

## Topic and Project Candidates

These recurring terms appeared across your [sources] but weren't mentioned in your setup
interview. They may represent active projects, clients, or recurring topics worth tracking.

Review this list. If any should be a project, client, or topic in your system, tell your
AI system and it will create the right files.

[For each candidate term:]
- "[Term]" — appeared [N] times ([sources where found])

[If none:]
No additional recurring topics found beyond known projects and contacts.

---

## Drive Documents Ingested

[If Drive active:]
[For each file successfully read:]
- ✅ [Filename] → content added to Brain/Business.md

[For each file that couldn't be read:]
- ⚠️ [Filename] — could not read ([reason: format not supported / file empty / access error])

[If Drive not connected or folder empty:]
Drive folder not connected or empty — skipped.

---

*Review this report before your first /checkin. The "New People Found" section is the most
important — these are contacts the system discovered that you haven't told it about yet.
Open each file and add context if they matter to your work.*
```

---

## Step 11 — Close

Say:

> "/seed complete.
>
> Here's what was built:
> - [N] People files enriched with 30-day history
> - [N] new contacts discovered and added to Brain/People/
> - [N] projects enriched with recent activity
> [If Drive active:] - [N] documents ingested into Brain/Business.md
>
> Full report saved to Brain/seed-report.md — review it before your first /checkin. The "New People Found" section has contacts the system found that you haven't told it about yet.
>
> Ready for /lets-go."

---

## Error Handling

- **Any single source fails mid-run:** Log the error in the seed report under the relevant section ("⚠️ [Source] — returned an error: [message]"), skip that source, continue with remaining sources. Never abort mid-run due to a single source failure.
- **People file write fails:** Note in seed report, skip that file, continue.
- **Master.md write fails:** Note in seed report, continue.
- **0 results from all sources for a person:** Note in "People With No Recent Activity." Do not modify their file.
- **Ambiguous name match:** When uncertain if a found contact matches the intended person (e.g., "John" matching multiple people), skip rather than writing incorrect data. Note in seed report.
