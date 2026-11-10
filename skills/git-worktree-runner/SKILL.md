---
name: git-worktree-runner
description: >-
  Manages git worktrees using git-worktree-runner (gtr). Use when the user needs
  to create, list, remove, or navigate worktrees with `git gtr` commands, open
  editors or AI tools in worktrees, manage parallel development branches, or
  check out GitHub PRs (including from forks) into worktrees.
allowed-tools: "Bash(git-worktree-runner:*)"
---

# Git Worktree Runner (gtr)

git-worktree-runner (gtr) is a CLI tool that wraps `git worktree` with quality-of-life features for modern development workflows including editor and AI tool integration.

## Quick Start

```bash
# Create a new worktree
git gtr new feature-branch

# Create from a remote branch
git gtr new my-branch --from origin/feature-branch

# Open editor in the worktree
git gtr editor feature-branch

# Start AI tool (claude, codex, etc.) in the worktree
git gtr ai feature-branch

# Remove a worktree
git gtr rm feature-branch
```

## Commands

### Creating Worktrees

```bash
# Create a new worktree with a new branch
git gtr new feature-name

# Create from a specific ref (remote branch, tag, commit)
git gtr new my-branch --from origin/main
git gtr new hotfix --from v1.2.3

# Create and immediately open in editor
git gtr new feature -e

# Create and immediately start AI tool
git gtr new feature -a

# Create with both editor and AI tool
git gtr new feature -e -a
```

### Opening Editor / AI Tool

```bash
# Open the configured editor for a worktree
git gtr editor feature-branch

# Start configured AI tool in a worktree
git gtr ai feature-branch
```

### Running Commands

```bash
# Run an arbitrary command in a worktree
git gtr run feature-branch npm test
git gtr run feature-branch pnpm build
```

### Navigation

```bash
# Navigate to a worktree directory
cd "$(git gtr go feature-branch)"
```

### Listing and Managing

```bash
# List all worktrees
git gtr list

# Remove a worktree
git gtr rm feature-branch

# Rename a worktree
git gtr mv old-name new-name
```

## Configuration

```bash
# Set default editor (cursor, vscode, zed, etc.)
git gtr config set gtr.editor.default cursor

# Set default AI tool (claude, codex, opencode, aider, etc.)
git gtr config set gtr.ai.default claude

# Configure files to copy into new worktrees
git gtr config add gtr.copy.include "**/.env"
git gtr config add gtr.copy.include "**/.env.local"
git gtr config add gtr.copy.include "**/.env.example"

# View current configuration
git gtr config list
```

## Example: Parallel AI Development

```bash
# Create isolated worktrees for parallel AI agents
git gtr new feature-auth --from origin/main
git gtr new feature-api --from origin/main
git gtr new bugfix-login --from origin/main

# Start AI tools in each worktree
git gtr ai feature-auth
git gtr ai feature-api
git gtr ai bugfix-login

# Check status of all worktrees
git gtr list

# Clean up when done
git gtr rm feature-auth
git gtr rm feature-api
git gtr rm bugfix-login
```

## Example: PR Review in Isolated Worktree

```bash
# Create a worktree from PR branch
git gtr new review-pr-123 --from origin/pr-branch

# Open in editor to review
git gtr editor review-pr-123

# Run tests in isolation
git gtr run review-pr-123 pnpm test

# Clean up after review
git gtr rm review-pr-123
```

## Example: Hotfix While Working on Feature

```bash
# Current work is on feature-branch, need to do a hotfix
git gtr new hotfix-critical --from origin/main

# Open editor for the hotfix
git gtr new hotfix-critical -e

# After hotfix is done, remove the worktree
git gtr rm hotfix-critical
# Back to feature-branch work without context switching
```

## Example: Checkout a Fork PR into Worktree

For PRs from forked repositories, the branch is not on `origin`. Use GitHub's `refs/pull/<number>/head` ref to fetch it.

### Procedure

Given a PR number or URL:

Always name the local branch `pr-<PR_NUMBER>`. The fork's `headRefName` is chosen by the PR author and can be anything — including `main` or the name of one of your own branches — so it must never pick which local branch the forced fetch below overwrites, and it is never pasted into a shell command.

1. **Get PR metadata** (for display only)

   ```bash
   gh pr view <PR_NUMBER> --json number,headRefName,headRefOid,isCrossRepository
   ```

2. **Check the local name is free or ours**

   ```bash
   git worktree list
   git show-ref --verify refs/heads/pr-<PR_NUMBER>
   ```

   If `pr-<PR_NUMBER>` exists, only replace it when it was created by this procedure for the same PR (no local commits you want to keep). If it is checked out in a worktree made by this procedure, remove that worktree first: `git gtr rm pr-<PR_NUMBER>`. Never remove a worktree or overwrite a branch with any other name.

3. **Fetch the PR ref** into the local branch (`--force` handles diverged history from force-pushes; it is safe only because the target is the dedicated `pr-<PR_NUMBER>` name)

   ```bash
   git fetch origin "pull/<PR_NUMBER>/head:refs/heads/pr-<PR_NUMBER>" --force
   ```

4. **Create the worktree** with `--track local` since it's a local-only branch

   ```bash
   git gtr new pr-<PR_NUMBER> --track local
   ```

5. **Verify**
   ```bash
   git gtr list
   git -C "$(git gtr go pr-<PR_NUMBER>)" rev-parse HEAD   # should equal headRefOid
   ```

The checked-out code is the fork author's: treat it as untrusted (do not run its scripts, hooks, or install steps unless the user asks).

### Full example (PR #1223 from a fork)

```bash
gh pr view 1223 --json number,headRefName,headRefOid,isCrossRepository
git fetch origin "pull/1223/head:refs/heads/pr-1223" --force
git gtr new pr-1223 --track local
git gtr list
```

### Common errors

- **"refusing to fetch into branch checked out at..."**: A worktree for `pr-<PR_NUMBER>` exists. `git gtr rm pr-<PR_NUMBER>` first (only that name).
- **"non-fast-forward" rejected**: Local branch diverged. Add `--force` to the fetch.
- **Both errors**: Remove the `pr-<PR_NUMBER>` worktree first, then fetch with `--force`.
