---
name: garbage-collect-memory
description: >-
  Garbage-collect the git-managed memory files under memories/: delete
  knowledge that no longer holds or is no longer needed, and merge duplicated
  entries into one — within a file and across the repository and topic files —
  so the memory stays short, current and consistent. Use when the user asks to
  clean up, prune, tidy, deduplicate or garbage-collect the memories, or when
  the memory files have grown long enough that stale or repeated entries get in
  the way.
---

# Garbage-Collect Memory

`record-session-memory` only ever adds and updates entries, so over time `memories/` collects facts that went stale, threads that were closed, and the same lesson written down twice in different words. This skill is the counterpart: it removes what is no longer needed and folds duplicates together, without losing anything that still matters.

## What to delete

Delete an entry when **one** of these is true — and you have checked it, not guessed it:

- **It no longer holds.** The code, config, deployment or external service has changed since it was written (a pitfall fixed upstream, a workaround for a bug that is gone, a version pin that was lifted, a model or API that was replaced).
- **It is superseded.** A later decision reversed or replaced it (for example, a "use X" entry after the user switched to Y). Keep only the decision in force; drop the history unless the reason for the reversal is itself worth knowing.
- **It is finished.** An open thread, pending task or TODO that has since been done, merged or abandoned.
- **It is now derivable.** The fact has since landed in the code, a README, CLAUDE.md, a skill or a test, so the repository itself tells the next session.
- **It describes something that is gone.** A repository removed from `repos/`, a service no longer used, a script or file that was deleted.
- **It never mattered again.** A one-off detail of a single session that is not a pitfall, a decision or reusable knowledge.

Do **not** delete:

- The user's stated decisions and preferences, unless the user has since replaced them.
- Pitfalls that still reproduce, even if old — age alone is not a reason.
- Anything you cannot verify either way. When in doubt, keep it; at most add or refresh its date.

## What to merge

- **Duplicates in one file** — two entries that state the same fact, or one that is a subset of another: keep one entry that carries everything the pair said, in the fitting section.
- **Duplicates across files** — the same knowledge in `memories/repos/<repo>.md` and a topic file, or in two repository files: cross-repository knowledge lives once in the topic file (`memories/<topic>.md`); the repository file keeps only what is specific to that repository. Do not leave a pointer behind unless the repository file would otherwise lose context a reader needs.
- **Contradictions** — two entries that disagree: find out which is true now, keep that one, delete the other.
- **Scattered pieces** — several small entries about one subject spread across sections: gather them under one section, one entry where they read as one fact.

Merging must not drop information: the merged entry keeps every detail from its sources that still holds, and the most recent date among them.

## How to verify

Before deleting or rewriting an entry, check it against the source of truth that it is about:

- Code and config — `grep`/read the file in `repos/<repo>` (pull first with `git -C repos/<repo> pull --ff-only` when the clone may be behind; skip the pull if the working tree has uncommitted changes of another session).
- History — `git -C repos/<repo> log --oneline -S '<keyword>'` or `git log` on the workspace, to see when a thing was fixed, removed or decided.
- GitHub state — `gh issue view` / `gh pr view` for threads that were "open" or "pending".
- Other memory files and skills — to find the duplicate or the newer statement.

Do not call paid or rate-limited external APIs, deploy, or change anything outside `memories/` to verify an entry. If the only way to verify is such a call, keep the entry.

## Workflow

1. Run `git status` in the workspace. If `memories/` has uncommitted changes from another session, leave those files alone or stop and tell the user.
2. Read `memories/README.md`, then every file under `memories/` (or only the ones the user named). Note each file's size (`wc -l memories/*.md memories/repos/*.md`) to see where the growth is.
3. Go file by file. For each entry, decide **keep**, **delete** or **merge** using the rules above, verifying as described. Also look across files for the same subject.
4. Edit the files: delete, merge and move entries; keep each file's one-line purpose and its section structure; remove sections left empty. Delete a file that is left with nothing, and create no new files except when moving cross-repository knowledge into a topic file that does not exist yet.
5. Update `memories/README.md` so each line still describes what its file covers, and drop lines for deleted files.
6. Show the user a short summary per file: what was deleted and why, what was merged into what, and any entry you kept only because it could not be verified.
7. Commit only the memory files (`git add memories && git commit`) with a message such as `docs(memories): garbage-collect stale and duplicated entries` — on the workspace's default branch, or through a pull request if your workflow requires one.
