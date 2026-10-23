---
name: sync-repo-skills
description: >-
  Mirror the skills of a repository under repos/ into this workspace as
  `<repo>-<name>` copies (repos/<repo>/.rulesync/skills/<name> ->
  .rulesync/skills/<repo>-<name>), rewriting each copy's name and its
  references to sibling skills so the imported set calls itself, and removing
  copies whose source skill is gone. Use when the user asks to import or sync a
  repository's skills into the workspace, e.g. "repos/rulesync のスキルを同期",
  "sync the rulesync skills", "take repo X's skills into the workspace".
---

# Sync Repo Skills

Bring the skills of one repository under `repos/` into this workspace, prefixed with the repository name so they sit alongside the workspace's own skills without clashing. The copy is a mirror: re-running it updates changed skills, adds new ones and deletes the copies whose source skill has disappeared. The generated tool directories (`.claude/skills/`, `.opencode/skills/`, …) are gitignored; only `.rulesync/skills/` is committed.

This assumes a workspace managed with [rulesync](https://github.com/dyoshikawa/rulesync): the script reads and writes `.rulesync/skills/` and expects `rulesync generate` afterwards. It needs bash 4+ and GNU find.

`repo` = the argument (a directory name under `repos/`, e.g. `rulesync`). Ask for it if none was given.

## What the script does

`scripts/sync.sh <repo> [repos-root]` (relative to this skill's directory) — the source of truth for the logic; read its header comment for details. In short, for every `repos/<repo>/.rulesync/skills/<name>/`:

- Copies the directory whole (`references/`, `LICENSE.txt`, …) to `.rulesync/skills/<repo>-<name>/`, replacing any previous copy.
- Sets the frontmatter `name` to `<repo>-<name>` and adds a `# synced-from: repos/<repo>/.rulesync/skills/<name>` YAML comment below it. The comment is the marker that tells a synced copy from a native workspace skill, and it counts only right below the `name:` line, where the script puts it; only marked directories are ever deleted.
- In `SKILL.md` only, rewrites backticked mentions of any skill of the source set to the prefixed name (`` `goal-pr` `` → `` `rulesync-goal-pr` ``), so `rulesync-goal-pr` drives `rulesync-review-pr` and not the workspace's own `review-pr`, which may differ. A skill's own name in its own body is left alone unless the line says "skill", because such self-mentions are usually a same-named command (`playwright-cli`). `references/*.md` is never rewritten.
- Applies the prefix literally, so a source skill whose name already starts with `<repo>-` ends up double-prefixed (`rulesync-rulesync-feature-research`); the report lists these.
- Leaves `targets:` and everything else in the frontmatter as it was.
- Treats the source repository as untrusted: it stops with an error, before touching anything, if a skill directory name has anything but letters, digits, `.`, `_` and `-` in it (hidden directories such as rulesync's `.curated/` are skipped), if the source or destination skills directory is reached through a symlink, or if a source skill directory or anything inside one is a symlink. A symlinked entry under `.rulesync/skills/` is never pruned or replaced.

The `[repos-root]` argument only matters when the workspace checkout has no `repos/` of its own (a git worktree): pass the main checkout's, e.g. `/path/to/main-checkout/repos`.

## Workflow

1. Make sure `repos/<repo>` is up to date (`git -C repos/<repo> pull`) unless the user wants a specific checkout synced; the copies are a snapshot and do not track the repository afterwards.
2. Run the script from the workspace root:

   ```sh
   <this skill's directory>/scripts/sync.sh <repo>
   ```

   It prints a report: added / updated / unchanged / removed skills, double-prefixed names, whether an unprefixed workspace skill of the same name exists and is identical to the source, every rewritten line, and the self-mentions it skipped. A directory listed under "overwrote directories that had no synced-from marker" was either an earlier hand-made import (fine) or a native skill that happened to carry the prefix — check with `git diff` before going on.
3. Review the rewritten and skipped lines. Revert by hand a rewrite whose token is a command, path or product name rather than the skill; prefix by hand a skipped self-mention that does mean the skill. Keep a note of such manual fixes in the commit message: the next sync overwrites the copy, so they have to be reapplied (or the script's rule extended) then.
4. Run `rulesync generate` and make sure it exits 0; spot-check one generated copy (`.claude/skills/<repo>-<name>/SKILL.md`) has the prefixed `name`.
5. Report to the user: the counts, the double-prefixed names, which copies duplicate an identical workspace skill and which differ from it, and any manual fixes from step 3.
6. Commit the sync (`git add .rulesync/skills && git commit`) with a message such as `chore(skills): sync <repo> skills` — on the workspace's default branch, or through a pull request if your workflow requires one. Do not push unless asked.
