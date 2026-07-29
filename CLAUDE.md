# [Name]'s AI System — Entry Point

Read `Personality/[Name].md` fully at session start. It contains everything about who this person is, their projects, their patterns, and how to work with them.

**Execution style:** Execute end-to-end without stopping to ask "want me to proceed?" Only pause at genuine blockers or decisions that couldn't have been anticipated.

**Protected content rule:** This system never writes outside its own clearly marked sections. The client's own words, notes, and writing are always off limits — never overwrite, restructure, or silently replace them.

**Uncertainty marking:** When not confident about a link, routing decision, task assignment, or factual claim, mark it with `(?)` rather than committing confidently. Never guess and present it as certain.

---

## At the Start of Every Session

1. Check if `System/.setup_progress` exists — if it does, skip steps 2–6 and say: "It looks like your setup wasn't finished — we stopped at Step [N]. Want to pick up where we left off, or start fresh?" Then run `/setup`.
2. Read `Personality/[Name].md`
3. Read `Personality/Working_Preferences.md`
4. Read `Personality/Mistake_Patterns.md`
5. Read `Brain/Master.md` — what's open and in flight
6. Check `Brain/Inbox.md` for unprocessed items
7. Read the most recent session file in `Brain/Session_Logs/`
8. Greet briefly, note anything urgent, ask what we're working on

---

## Session Logging — Active Throughout Every Session

Write to the session log frequently. Trigger points:
- A decision is made → log the decision AND the reasoning
- Something is researched → log what was found and what it led to
- A concept or framework is explained → log what it is and why it matters
- Direction changes → log what changed and why
- Any insight worth remembering → log it

Format: `**[HH:MM]** What happened and why it mattered.`

---

## Learning Loop

- Client corrects you → append to `Personality/Mistake_Patterns.md` immediately
- Client expresses a preference → update `Personality/Working_Preferences.md` immediately
- Do this silently — no announcement

---

---

## Associative Linking — Active Throughout Every Session

The vault builds a knowledge graph over time. Wikilinks are the mechanism — every `[[link]]` makes a topic discoverable without manual search.

**Inline linking rule:** Whenever a named person, project, company, or framework appears in a session log entry, link it with `[[Name]]`. Do this at the entry level, not just at the file top. This is what feeds the graph.

**Topic hubs** live in `Brain/Topics/`. A hub is a short description + Key Files + Related links. Create one after a topic recurs ~2-3 times across sessions. Threshold exists to avoid hub proliferation on first mention.

**Hub structure** (use `Brain/Topics/_template.md`):
- One-paragraph description of the topic
- **Key Files** — the 3-5 most important permanent files for this topic (project file, key plans, reference docs). Not session logs — those are discovered via search.
- **Related** — other hubs this connects to
- Add to `Brain/Topics/INDEX.md` when created

**When a topic surfaces mid-session:**
1. Check `Brain/Topics/` for an existing hub — if found, the Key Files section is the starting point
2. Run `grep -rl "[[TopicName]]" Brain/` to surface all files that mention it — this is the backlink equivalent
3. If the topic has recurred 2-3 times and no hub exists, create one

**Do not hand-maintain backlink lists in hub files** — Obsidian computes those automatically. Hub content = description + Key Files + Related only.

---

## Key Files

- `Personality/[Name].md` — who they are
- `Personality/Priorities.yaml` — their strategic priorities
- `Brain/Master.md` — live task board
- `Brain/Inbox.md` — raw captures
- `Brain/Session_Logs/` — permanent session record
- `Brain/Topics/` — knowledge graph hub pages
- `Brain/Topics/INDEX.md` — flat directory of all hubs
- `System/integrations.yaml` — which tools are connected

---

## The Consigliere Rule — /recall Before Discussing

Before discussing any topic where prior knowledge might exist — a person, a project, a decision, a framework — run `/recall [topic]` first. The system has memory; use it.

**Memory questions always trigger /recall.** When the client asks "do you remember", "did we discuss", "have we talked about", "do we have anything on" — treat it as an explicit `/recall [topic]` invocation and run the search before answering. Never answer a memory question from context alone.

---

## Knowledge Dual-Write — Active Throughout Every Session

When a decision, insight, framework, or people context surfaces in conversation, write it to the appropriate Layer 2 file immediately — not at session end.

Where things go:
- Decisions with reasoning → **project file first, then session log.** Write the decision to the relevant project file before logging it to the session. Session logs are the narrative record; project files are the authoritative state record. A decision that lands only in a session log is effectively buried — future sessions read the project file and will treat a closed question as open. The `decision-check.sh` hook fires as a mechanical reminder, but write order is the real enforcement.
- Frameworks or named concepts → `Brain/Knowledge/Frameworks/`
- Competitive or market insights → `Brain/Knowledge/AI_and_Agents/` or `Brain/Knowledge/Business/`
- People context → `Brain/People/[Name].md`

Same pattern as backlog sync: happens the moment the knowledge surfaces, not at wrap time.

---

## Layer 2 Audit — Nightly Background Job

`Brain/System/Scripts/layer2-audit.py` runs nightly at 10pm via launchd. It reads that day's session logs, extracts Layer 2-worthy content (decisions with reasoning, frameworks, competitive observations, people insights), and writes to the appropriate `Brain/Knowledge/` or `Brain/People/` files autonomously. Audit trail at `Brain/System/layer2-audit-log.md`.

Also runs as part of `/eod` when the client does a manual end-of-day review.
