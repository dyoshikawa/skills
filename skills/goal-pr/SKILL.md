---
name: goal-pr
description: >-
  Drive a pull request to a clean state and merge it: run the `review-pr` skill,
  fix every mid-or-above finding, and repeat until no mid-or-above findings
  remain, then merge. Use when the user wants to finish a PR by reviewing,
  fixing, and merging it, or triggers on "the `goal-pr` skill".
---

# Goal PR

target_pr = the user's request

This skill drives a pull request all the way to merge. It repeatedly runs
the `review-pr` skill, fixes every finding of severity `mid` or above, and merges the PR
once a review round reports no `mid`-or-above findings.

## 0. Determine and Prepare the Target PR

1. If `target_pr` is provided (e.g. `123`, `#123`, or a PR URL), use it.
2. Otherwise, look for the PR of the current branch:

   ```bash
   gh pr view --json number,title,state,headRefName 2>/dev/null
   ```

3. If no PR exists yet, create one (this satisfies the "PR is the goal" intent):
   - Use the `commit-push-pr` skill to commit the current changes, push the
     branch, and open a PR.
   - Then resolve `target_pr` to the freshly created PR number.

Confirm that the current local branch really is the PR's head branch, because
the fix phase below runs the repository's checks and pushes fixes onto that
branch. A matching branch name alone is not enough — a fork PR can use any name,
including `main` or one of your own branches. Read the PR's head identity:

```bash
gh pr view <target_pr> --json headRefName,headRefOid,isCrossRepository,baseRefName
git fetch origin
git rev-parse HEAD
```

Continue only when all of these hold; otherwise ask the user how to proceed and
stop:

- `isCrossRepository` is `false` (the head branch lives in this repository).
  Fork PRs are not driven by this skill.
- `headRefName` is not `baseRefName` or the repository's default branch.
- The current local branch name equals `headRefName`.
- `git rev-parse HEAD` equals `headRefOid` (the local branch holds exactly the
  PR's head commit). If the local branch is only ahead with your own unpushed
  commits, push them first (`git push origin 'HEAD:refs/heads/<headRefName>'`)
  and re-read; if it is only behind, fast-forward with
  `git pull --ff-only`. Anything else means the branches diverged — ask.

## 1. Exit Condition

The loop exits when a single review round satisfies **both** of:

- **0** findings of severity `mid`, `high`, or `critical` (only `low` findings,
  or none at all, may remain).
- The PR's GitHub Actions checks are **green** — no check is `fail` or
  `pending`.

Set a hard safety cap of **10 iterations**. If the exit condition is still not
met at the cap, stop the loop and report the remaining findings (and any failing
CI) to the user for a manual decision instead of merging.

## 2. Iteration Loop

Repeat the following until the exit condition is satisfied or the cap is hit.

### 2-1. Review Phase

First record the PR head commit this round reviews as `reviewed_sha`:

```bash
gh pr view <target_pr> --json headRefOid --jq .headRefOid
```

A clean round only approves that commit. Then use the `review-pr` skill with `target_pr`. It assigns each finding a
severity (`low` / `mid` / `high` / `critical`) and a sequential number, and also
reports the GitHub Actions workflow status.

Note: the `review-pr` skill only reads remote state and must not switch the local branch.
Keep that constraint intact during the review phase.

### 2-2. Evaluate the Exit Condition

Use both the findings and the GitHub Actions status from the review result.

- If `mid + high + critical == 0` **and** CI is green (no `fail` / `pending`
  check): exit the loop and go to **Section 3**.
- If there are `mid`-or-above findings, or any CI check is failing: proceed to
  the fix phase to address them.
- If the findings are clean but CI is still `pending`: wait for the checks to
  finish (re-check with `gh pr checks <pr>`), then re-evaluate. Do not proceed to
  merge while checks are pending.

### 2-3. Fix Phase

Fix every finding of severity `mid` or above on the current branch (you may also
fix `low` findings opportunistically). Unlike the review phase, this phase works
on the local branch directly:

1. Edit the relevant files to address each `mid`-or-above finding. If you
   intentionally reject a finding, record the reason and treat it as resolved.
2. Run `pnpm cicheck` (or the narrower `pnpm cicheck:code` / `cicheck:content`
   when appropriate) and fix any failures before continuing.
3. Stage only the files you changed for the fix (review `git status` first so
   unrelated or generated files are not swept in), commit with a descriptive
   message, and push to the PR's head branch:

   ```bash
   git status
   git add <changed files>
   git commit -F <message file>
   git push origin 'HEAD:refs/heads/<headRefName>'
   ```

   Write the commit message to a file outside the working tree with the
   file-writing tool and pass it with `-F`, rather than putting free-form text
   in `-m "..."`: review findings can quote PR or issue text, and backticks or
   `$(...)` inside double quotes run in your shell. Keep the push refspec in
   single quotes as shown (escape any `'` in the branch name as `'\''`).

Emit a short status line such as
`Iteration N — mid: X, high: Y, critical: Z; pushed fixes`, then return to
**Section 2-1** so the updated PR (and its CI) is reviewed again.

## 3. Merge

Only reach this step once the exit condition in Section 1 holds — clean findings
**and** green CI. Apply the safety rules below **before** invoking `merge-pr`;
if one of them holds the PR, do not invoke it. Otherwise merge the PR by using the `merge-pr` skill with
`target_pr` and the clean round's `reviewed_sha`. That skill verifies the PR is
open, checks GitHub Actions status, merges with `gh pr merge --admin --merge
--match-head-commit <reviewed_sha>`, posts a thank-you comment, and cleans up
the local branch. If the PR head is no longer `reviewed_sha` (someone pushed
after the review), do not merge: return to Section 2-1 and review the new head.

Safety rules for the merge:

- **Never merge while any check is `fail` or `pending`.** `gh pr merge --admin`
  bypasses required checks, so it must not be used to force past red or
  in-progress CI. If CI is failing, return to the fix phase; if it is pending,
  wait.
- If the PR touches GitHub Actions workflows, build/release configuration, or
  dependency manifests (e.g. `package.json`, lockfiles), do **not** auto-merge.
  Stop and ask the user to confirm, since these changes carry higher risk. When
  an autonomous caller (e.g. `batch-all-issues`) invoked this skill, do not wait:
  leave the PR open and return `Held`.
- If the caller marked the PR as having a **lower-trust origin** (e.g.
  `batch-all-issues` for a fix derived from a non-maintainer's issue), check the
  final diff right before merging (`gh pr diff <target_pr> --name-only`, plus
  the diff itself for auth/secret code). If it touches agent instructions or their tooling (`CLAUDE.md`, `AGENTS.md`, `.claude/**`, `.rulesync/**`, skill definitions, hooks, MCP configs) or authentication, permission, or secret-handling code, do not
  merge: leave the PR open and report it as `Held`. Check the final diff, not
  the first fix, since fix rounds can add files.

## 4. Final Report

After the loop ends, report to the user:

- **Outcome**: `Merged` (exit condition met and PR merged), `Held` (exit
  condition met; merge left to the user because the final diff hit a
  lower-trust or high-risk rule in Section 3), or `Capped` (hit the iteration
  cap without converging; not merged).
- **Iterations**: how many review/fix rounds were executed.
- **Final severity summary**: the counts per severity from the last review
  round.
- **Result**: the merged PR number and title, or — when capped — the list of
  remaining `mid`-or-above findings for the user to decide on.
