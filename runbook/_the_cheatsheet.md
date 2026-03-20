>For a student studying for exams: Markdown notes are the wrong tool. Writing notes feels productive but is passive — you rarely go back and actively recall from
>  them. What works for memorization is spaced repetition (Anki, not markdown). If a student insists on this system, they'd put study material in cheatsheets (since
>  it's reference knowledge, not task tracking), but they'd be better served by flashcard software that forces active recall.
>
>  For a professional software engineer: You don't need to memorize almost anything. The question itself reveals a student mindset that professionals should let go
>  of. Here's what actually happens:
>
>  - Syntax/APIs — you look it up (cheatsheets, LLM, docs). Nobody memorizes function signatures.
>  - Concepts (design patterns, architectural tradeoffs) — you internalize these by building things, not by reading notes. If you've built three microservices, you
>  don't need notes about service boundaries.
>  - Gotchas (that one flag that silently breaks things, the env var that must be set) — this is what cheatsheets are for. Short, specific, born from pain.
>
>  The professional's learning loop is: encounter problem → solve it → maybe add a cheatsheet entry if it'll bite you again. There is no "study" phase. The work IS
>  the studying.
>
>  So in your system:
>  - Cheatsheets cover the "lookup" need
>  - Notes cover the "what am I doing and why" need
>  - Memorization isn't a need — it's a habit from school that doesn't serve you anymore
>
>  senior engineers deliberately invest in structured learning: reading RFCs, design docs, postmortems, doing design drills, and prototyping. Work gives context, but deliberate practice builds depth and range.

# The System: NotesPlus + RunBook

Two directories, two purposes. No overlap.

| Need | Tool |
|---|---|
| "How do I do X?" | Cheatsheet or LLM |
| "What am I doing and why?" | NotesPlus |
| "What have I accomplished?" | NotesPlus (`brag.md`) |
| "How does this internal system work?" | NotesPlus (machine-specific) |
| "What was decided in that meeting?" | NotesPlus |

## Cheatsheets (`~/.local/share/chezmoi/cheatsheets/`)

Synced across all machines via chezmoi. Static reference material.

**What goes here:**
- CLI commands you repeatedly google (git, docker, k8s, curl, jq)
- Language-specific idioms and gotchas
- SQL / regex patterns
- Dev environment setup steps
- Common configuration patterns
- SSH/auth/credential setup
- Deployment procedures (stable ones)
- PR review checklist
- Interview rubric (as interviewer)

**Rule:** A cheatsheet earns its place by being looked up more than once.
encounter problem -> solve it -> google it again -> add to cheatsheet.

**Access:** `<leader>fn` (find), `<leader>fN` (grep)

## NotesPlus (`~/notesplus/`)

Machine-local. NOT synced via chezmoi. Tasks, decisions, context.

**What goes here:**

Daily execution:
- Sprint task tracking and blockers
- Debugging sessions — what you tried, what failed, what fixed it
- PR review notes — feedback you gave or received that has project context
- Incident response — timeline, root cause, remediation

Meetings:
- Standup updates (what you said/committed to)
- 1:1 notes with manager — talking points, outcomes, action items
- Design review decisions — what was agreed and why
- Retro action items

Technical decisions:
- Why you chose library A over B for this project
- Architecture tradeoffs specific to your system
- Workarounds for internal tooling quirks
- Integration details with other teams' services

People & context:
- Who owns what system (different at every job)
- Stakeholder preferences and communication styles
- Onboarding notes for a new codebase

Career tracking:
- Brag document — THE most important file, update weekly
- Skills demonstrated, impact delivered
- Feedback received
- Goals and progress

**Access:** `:NotesPlus`

## Example NotesPlus Structure

```
~/notesplus/
  index.md                    <- task board, entry point
  brag.md                     <- accomplishments log (update weekly)
  migrate-auth-to-oauth.md    <- task: spans multiple days
  fix-payment-race-cond.md    <- task: debugging log
  onboard-orders-service.md   <- context: how internal system works
  1on1-notes.md               <- recurring: manager 1:1s
  q1-retro-actions.md         <- meeting outcome
```

### Example task file: `migrate-auth-to-oauth.md`

```markdown
# Migrate Auth to OAuth

## 2026-03-25
- Spike: evaluated passport.js vs auth0
- Decision: going with auth0, less maintenance
- Talked to @sarah — she owns the session store, needs heads up

## 2026-03-27
- [x] Add auth0 SDK to project
- [x] Update callback URLs in staging
- [ ] Write migration script for existing sessions
- Blocker: need DevOps to whitelist auth0 domain in firewall

## 2026-03-28
- Firewall rule added (ticket OPS-412)
- [ ] Migration script — handle edge case: users with multiple sessions
- [ ] Update API docs
```

### Example brag entry

```markdown
### Q1
- Shipped auth migration to OAuth, reducing login-related incidents by 60%
- Led design review, decision adopted by team of 8
- Mentored intern through first production deploy
- Resolved payment race condition affecting ~500 daily transactions
```

## Philosophy

- **Professionals don't memorize.** The work IS the studying.
  encounter problem -> solve it -> maybe add a cheatsheet if it'll bite you again.
- **Cheatsheets:** things you look up. Short, specific, born from pain.
- **NotesPlus:** things only you know. Context, decisions, accomplishments.
- **LLM:** everything else. Don't collect knowledge you can generate on demand.
