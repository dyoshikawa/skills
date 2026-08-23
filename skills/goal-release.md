---
name: goal-release
description: >-
  Cut a release end to end: use the `draft-release` skill to open the release PR and draft
  GitHub release, wait for CI to turn green, run the `merge-pr` skill to merge
  the release PR, then finish any post-release distribution updates that depend
  on the published release assets. Use when the user wants to draft and merge a
  release in one go, or triggers on "the `goal-release` skill".
---

# Goal Release

new_version = the user's request

This skill drives a release all the way to merge. It uses the `draft-release` skill to
open the release pull request (and create the draft GitHub release), waits for
the PR's CI checks to pass, runs the `merge-pr` skill to merge it, and finally
completes any post-release distribution update that can only happen once the
release assets are built.

## 1. Draft the Release

Use the `draft-release` skill with `new_version`.

- If `new_version` is provided (e.g. `v1.2.3` or `1.2.3`), it must match the
  semver shape `^v?\d+\.\d+\.\d+$` — if it does not, stop and report instead
  of passing it on. Pass a valid value through unchanged; the `draft-release` skill
  normalizes the `v` prefix itself.
- If `new_version` is empty, pass no argument; the `draft-release` skill determines the
  next version automatically via the `release-dry-run` skill.

When the `draft-release` skill finishes, it has:

- created a `release/v<version>` branch with the version-bump commits,
- opened a pull request against `main`, and
- created a draft GitHub release `v<version>` with the release notes.

If the `draft-release` skill failed partway (e.g. the PR exists but the draft release
was not created, or it stopped before opening the PR), stop here and report
the partial state to the user instead of continuing.

## 2. Resolve the Release PR

Use the PR number or URL that the `draft-release` skill's `gh pr create` printed in
Step 1 when available. Otherwise, identify the pull request from the current
`release/v<version>` branch:

```bash
gh pr view --json number,title,state,headRefName
```

Confirm that `headRefName` matches the `release/v<version>` branch created in
Step 1. This skill must only ever merge that release PR — if the resolved PR
is a different one, stop and report to the user instead of merging.

## 3. Wait for CI

Wait for the release PR's GitHub Actions checks to finish:

```bash
gh pr checks <pr_number> --watch
```

If the watch reports that no checks are registered yet, wait a moment and
retry — checks can take a few seconds to appear right after the PR is opened.

- If every check passes, proceed to Step 4.
- If a check fails, investigate and fix the failure on the release branch
  (run the project's CI check script locally — `pnpm cicheck` when it exists —
  then commit and push), and wait for the re-run.
  Never proceed to the merge while any check is `fail` or `pending`.
- Fixes must legitimately resolve the failure. Never make a check green by
  skipping or deleting tests, weakening lint or type-check configuration, or
  editing GitHub Actions workflows.
- Set a safety cap of **3** fix attempts. If CI is still red after the cap,
  stop and report the failing checks to the user instead of merging.

If any fix commit beyond the `draft-release` skill's own version-bump commits was
pushed, stop before merging and report the extra commits to the user for
confirmation. The release PR must reach the merge step containing only
reviewed, expected content.

## 4. Merge the Release PR

Use the `merge-pr` skill with the release PR number. It re-verifies the PR
state and CI status, merges with `gh pr merge --admin --merge`, posts a
thank-you comment, and cleans up the local branch.

Note: the `goal-pr` skill tells agents not to auto-merge PRs that touch `package.json`
or release configuration. That restriction does not apply here — merging the
version-bump release PR is this skill's explicit purpose, and the user opted
into it by invoking the `goal-release` skill.

## 5. Finish the Post-Release Distribution Update

Many projects publish release artifacts from a workflow that runs after the
release PR merges, and maintain a downstream distribution file that embeds the
checksums of those artifacts (a Homebrew tap formula, a package manifest for
another registry, and so on). Such a file can only be regenerated once the
assets exist.

First determine whether this project has such a step at all — check its release
documentation, `.github/workflows/**`, and any generator script under
`scripts/**`. **If it does not, skip straight to Step 6** and say so in the
report.

When it does:

1. Wait for the asset-publishing workflow run triggered by the merge to
   complete:

   ```bash
   gh run list --workflow "<asset workflow name>" --branch "release/v<version>" \
     --limit 1 --json databaseId,status,conclusion,headBranch
   gh run watch <run_id>
   ```

   Such workflows commonly trigger on every closed PR to `main` (non-release
   runs are job-level skipped but still listed), so filter by the release
   branch as shown. The run can take a few seconds to appear right after the
   merge — if the list is empty, wait and retry. Confirm the watched run
   belongs to this release (its `headBranch` is the `release/v<version>` branch
   of the PR merged in Step 4) and concluded with `success`. If it failed, stop
   and report — the distribution file must not be regenerated from stale
   assets.

2. Wait until the GitHub release is published (no longer a draft). Draft-release
   asset URLs return 404 for unauthenticated users, and package managers
   normally fetch the distribution file straight from `main`, so landing it
   before the release is public would break installation for everyone:

   ```bash
   gh release view v<version> --json isDraft --jq .isDraft
   ```

   Poll until this prints `false`. If the publishing workflow failed (e.g. a
   registry publish error) and the release stays a draft, stop and report
   instead of updating the distribution file.

3. Regenerate the distribution file from the released checksums, using the
   project's own generator script and checksum asset:

   ```bash
   git checkout main && git pull
   gh release download v<version> --pattern <checksums asset> --dir ./tmp --clobber
   # run the project's generator, e.g.
   #   pnpm exec tsx scripts/<generator>.ts <version> ./tmp/<checksums asset> <output file>
   rm -f ./tmp/<checksums asset>
   ```

4. If `git diff --quiet -- <output file>` reports no change, the file is
   already up to date — skip ahead to the final report.

5. Otherwise commit the regenerated file on a branch and merge it right
   away (`main` is branch-protected, so the change must land via a PR; merging
   it immediately with admin rights is this skill's explicit purpose, same
   as the release PR itself):

   ```bash
   git switch -c release-dist/v<version>
   git add <output file>
   git commit -m "chore: update <output file> to v<version>"
   git push -u origin release-dist/v<version>
   gh pr create --base main --title "chore: update <output file> to v<version>" \
     --body "Automated distribution update for the v<version> release."
   gh pr merge --admin --merge --delete-branch
   ```

   If a previous attempt already pushed the `release-dist/v<version>` branch or
   opened its PR, reuse them instead of failing: force-push the branch with
   `git push --force-with-lease` and skip `gh pr create` when
   `gh pr list --head release-dist/v<version>` shows an open PR.

   Only the regenerated distribution file may be committed here. If anything
   else shows up in `git status`, stop and report instead of committing it.

## 6. Final Report

Report to the user:

- The merged release PR number and title.
- The new version and a link to the GitHub release (published automatically by
  the project's publishing workflow, which Step 5 waits for).
- Whether a post-release distribution file was updated (and its PR number), was
  already up to date, or does not apply to this project.
- Any CI fixes that were needed along the way.
