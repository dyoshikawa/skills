---
name: record-session-memory
description: >-
  Record what this session taught into the git-managed memory files under
  memories/ — pitfalls to watch for in later sessions and domain knowledge worth
  reusing — split by repository and by technical area. Use when the user asks to
  remember something, to save the session's learnings, or at the end of a piece
  of work that produced non-obvious knowledge.
---

# Record Session Memory

Distil the knowledge this session produced into `memories/` so the next session starts with it, without re-deriving it from the code or the conversation.

## What belongs in memory

Keep only what is **not derivable** from the repository itself (code, README, CLAUDE.md, git history) and is likely to matter again:

- **Pitfalls and their fixes** — things that failed once and why: a tool quirk, a flag that does not do what its name says, an environment difference between local and production, a check that CI runs which is easy to trip.
- **Reusable domain knowledge** — how an external service really behaves (its data formats, limits, terms), a design decision and the reason it was made that way, the meaning of a non-obvious convention.
- **Working preferences the user stated** — how they want work delivered, verified, committed or reported.
- **State that is not in git** — what is deployed where, which secrets exist (by name only, never their values), what is still pending or unresolved.

Leave out: anything readable from the code or docs, one-off details of this conversation, transcripts, and any secret, token, or personal data.

## Where it goes

- `memories/repos/<repo>.md` — knowledge specific to one repository under `repos/` (named after its directory).
- `memories/<topic>.md` — knowledge that cuts across repositories, one file per technical area (`cloudflare-workers.md`, `playwright.md`, `openrouter.md`, `github-actions.md`, …). Create a new topic file when no existing one fits; do not grow a catch-all.
- `memories/README.md` — the index: one line per file, what it covers. Keep it in sync.

## Format

Each file starts with a one-line purpose, then sections by theme. Entries are short and factual, in English, and carry a date (`YYYY-MM-DD`) when the fact may go stale:

```markdown
# my-app

Repository-specific notes for `repos/my-app`.

## Deployment

- (2026-09-14) Served at https://my-app.example.com (Workers Custom Domain); workers.dev redirects there. `workers_dev: true` must stay in wrangler.jsonc or wrangler switches the address off.

## Pitfalls

- `pkill -f "wrangler dev"` kills the calling shell too (its own command line matches): use a pattern like `cli.js d[e]v`.
```

## Workflow

1. Read `memories/README.md` and the files touched by this session's work, so entries are updated rather than duplicated.
2. Go through the session and list candidate facts under the four headings above. Be selective: a handful of sharp entries beats a page of narrative.
3. For each fact, pick the file by the rule in "Where it goes". Update an existing entry when it is the same fact (correct it if it was wrong; delete it if it no longer holds); otherwise add one under the fitting section.
4. Update `memories/README.md` for any file added or removed.
5. Show the user a short summary of what was recorded and where, then commit the memory files (`git add memories && git commit`) with a message such as `docs(memories): record <topic>` — the workspace commits straight to `main`.
