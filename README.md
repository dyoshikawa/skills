# Skills

A collection of 38 skills for maintaining OSS projects on GitHub — triaging issues, reviewing and merging pull requests, cutting releases, and keeping branches tidy.

Each skill is a plain Markdown file with YAML frontmatter, following the [Agent Skills](https://code.claude.com/docs/en/skills) convention, so it can be used with any coding agent that reads that format.

## Layout

```
skills/
├── <name>.md              # the skill itself
└── <name>/references/     # supporting material, for the few skills that ship it
```

Reference links inside a skill body are written relative to `skills/`, so they resolve when browsing this repository. If you install a skill as `<name>/SKILL.md` instead, move its `references/` directory alongside the skill and drop the `<name>/` prefix from those links.

## Requirements

Most skills drive the [GitHub CLI](https://cli.github.com/) (`gh`, authenticated) and `git`. A few need more:

- `git-worktree-runner` — the `gtr` CLI (`git gtr`)
- `playwright-cli` — the `playwright-cli` command
- `opencode-gpt-review` — [opencode](https://opencode.ai/) with GitHub Copilot configured

Skills that run a project's checks call `pnpm cicheck` when the project defines it.

## Notes

These skills are designed as a set and refer to each other by name — `goal-pr` runs `review-pr` and `merge-pr`, `goal-release` runs `draft-release` and `merge-pr`, and the `batch-*` skills drive several in a loop. Picking a skill in isolation works, but check its body for the ones it delegates to.

Some skills assume a `maintainer-scrap` label for notes-to-self issues, and that `main` is the default branch.

## Skills

### Issues

| Skill | Description |
| --- | --- |
| [`create-issue`](skills/create-issue.md) | Create a GitHub issue with detailed description, purpose, and appropriate labels |
| [`create-issue-with-websearch`](skills/create-issue-with-websearch.md) | Create a GitHub issue from a vague idea by thoroughly researching the topic on the web to sharpen the specification before filing |
| [`create-scrap-issue`](skills/create-scrap-issue.md) | Create a GitHub issue that consolidates passed content into a single scrap issue with background context and solution details, labeled as maintainer-scrap. Use when the user wants to create a scrap issue, jot down notes as a GitHub issue, or save findings for later. |
| [`draft-issue-to-external-repository`](skills/draft-issue-to-external-repository.md) | Draft a GitHub issue targeting a third-party repository (outside this project's owner). Researches the target repo's conventions and the topic in depth, iterates with the user on scope and tone, and produces a final body saved to tmp/external-repository-issues/*.md for the user to post manually when gh auth lacks permission on the target. |
| [`explain-issue`](skills/explain-issue.md) | Explain a GitHub issue: the background problem and the proposed solution |
| [`post-issue-comment`](skills/post-issue-comment.md) | Post a reply comment on a GitHub issue in English with a natural, concise writing style, based on the intent passed as arguments |
| [`triage-issues`](skills/triage-issues.md) | Triage open GitHub issues by reviewing unlabeled ones and applying the most appropriate labels based on their content |
| [`understand-scrap-issues`](skills/understand-scrap-issues.md) | Fetch the most recent maintainer-scrap issues (up to 3) and understand their content |
| [`resolve-scrap-issues`](skills/resolve-scrap-issues.md) | Fetch recent maintainer-scrap issues, validate each with web research, then either close the ones that need no action or open a single consolidated pull request that resolves the ones that do |
| [`batch-all-issues`](skills/batch-all-issues.md) | Resolve every open issue one at a time: fact-check each with web research, close the ones that need no action, and run the `goal-pr` skill to fix, review, and merge the ones that do — repeating until no actionable issues remain. |
| [`batch-all-scrap-issues`](skills/batch-all-scrap-issues.md) | Resolve every open maintainer-scrap issue one at a time: fact-check each with web research, close the ones that need no action, and run the `goal-pr` skill to fix, review, and merge the ones that do — repeating until no actionable scrap issues remain. |

### Pull requests

| Skill | Description |
| --- | --- |
| [`commit-push-pr`](skills/commit-push-pr.md) | Commit current changes, push to remote, and create or update a pull request. Use when the user wants to commit and create a PR, push changes and open a pull request, or ship their current work as a PR. |
| [`explain-pr`](skills/explain-pr.md) | Explain a PR: the background problem and the proposed solution |
| [`diff-analyze`](skills/diff-analyze.md) | Analyze the differences between the current branch and origin/main, and summarize the current work progress |
| [`review-pr`](skills/review-pr.md) | Review a pull request for code quality and security issues. Use when the user wants to review a PR, check PR code changes, or audit a pull request. Triggers on: "review PR", "review pull request", "check this PR", "the `review-pr` skill". |
| [`review-pr-lite`](skills/review-pr-lite.md) | Review a pull request for code quality and security issues without using subagents. Use when the user wants a lighter-weight PR review in a single skill. |
| [`review-and-comments`](skills/review-and-comments.md) | Review a PR for code quality and security issues, then post review comments on it. Runs review-pr followed by post-review-comments sequentially. |
| [`post-review-comments`](skills/post-review-comments.md) | Post line-level review comments and an overall review comment on a PR in English with a natural, concise writing style |
| [`opencode-gpt-review`](skills/opencode-gpt-review.md) | Run the `review-pr` skill on another model (github-copilot/gpt-5.4) via opencode, then thoroughly investigate and vet the resulting findings, and present only the valid ones to the user. |
| [`security-scan-diff`](skills/security-scan-diff.md) | Scan for malicious code in git diff between a tag/commit and HEAD |
| [`goal-pr`](skills/goal-pr.md) | Drive a pull request to a clean state and merge it: run the `review-pr` skill, fix every mid-or-above finding, and repeat until no mid-or-above findings remain, then merge. Use when the user wants to finish a PR by reviewing, fixing, and merging it, or triggers on "the `goal-pr` skill". |
| [`merge-pr`](skills/merge-pr.md) | Merge a pull request using gh pr merge --admin |
| [`prs-awaiting-author`](skills/prs-awaiting-author.md) | List open pull requests where the ball is in the author's court: CI is failing, review comments are unaddressed, or a maintainer question is awaiting the author's reply. Use when the user wants to see PRs awaiting author action. |
| [`prs-awaiting-maintainer`](skills/prs-awaiting-maintainer.md) | List open pull requests where the ball is in the maintainer's court: CI is green and the PR is ready for a maintainer to review, re-review, or merge. Use when the user wants to see PRs awaiting maintainer action. |
| [`batch-review-prs-awaiting-maintainer`](skills/batch-review-prs-awaiting-maintainer.md) | Batch-triage open pull requests: list PRs with prs-awaiting-maintainer, review each with review-pr, then post-review-comments when there are merge-blocker findings, or create-scrap-issue for non-blocking findings and merge-pr when there are none. Use when the user wants to review and resolve a batch of PRs in one pass. |
| [`babysit-dependabot-pr`](skills/babysit-dependabot-pr.md) | Babysit a Dependabot dependency-bump PR all the way to merge: verify the author is the genuine Dependabot bot, diagnose and resolve any CI failure (excluding or fixing a breaking bump when needed), get every check green, and merge. Use when the user wants to shepherd a Dependabot bump PR to merge. |

### Releases

| Skill | Description |
| --- | --- |
| [`release-dry-run`](skills/release-dry-run.md) | Dry run for release: summarize changes since last release and suggest version bump. |
| [`draft-release`](skills/draft-release.md) | Draft a new release of the project. |
| [`goal-release`](skills/goal-release.md) | Cut a release end to end: use the `draft-release` skill to open the release PR and draft GitHub release, wait for CI to turn green, run the `merge-pr` skill to merge the release PR, then finish any post-release distribution updates that depend on the published release assets. Use when the user wants to draft and merge a release in one go, or triggers on "the `goal-release` skill". |
| [`draft-release-post`](skills/draft-release-post.md) | リリース告知のXポスト下書きを作成する |

### Branches and worktrees

| Skill | Description |
| --- | --- |
| [`pull-main`](skills/pull-main.md) | Switch to main branch and pull latest changes with prune. Use when the user wants to pull latest main, update main, or sync main with remote. |
| [`rebase-latest-main`](skills/rebase-latest-main.md) | Fetch latest origin/main and rebase it onto the current branch, resolving conflicts if necessary. Use when the user wants to rebase on main, update their branch with latest main, or sync with upstream. |
| [`clean-branches`](skills/clean-branches.md) | Clean up unnecessary local branches and prune stale remote-tracking branches |
| [`clean-worktrees`](skills/clean-worktrees.md) | Clean git worktrees created by git-worktree-runner |
| [`git-worktree-runner`](skills/git-worktree-runner.md) | Manages git worktrees using git-worktree-runner (gtr). Use when the user needs to create, list, remove, or navigate worktrees with `git gtr` commands, open editors or AI tools in worktrees, manage parallel development branches, or check out GitHub PRs (including from forks) into worktrees. |

### Other

| Skill | Description |
| --- | --- |
| [`playwright-cli`](skills/playwright-cli.md) | Automate browser interactions, test web pages and work with Playwright tests. |
| [`porting-another-repository`](skills/porting-another-repository.md) | Plan how to port a feature, configuration, or implementation from this repository into another repository. Analyzes the source feature here and the target repo's conventions, then writes a multi-file porting plan (overview, source analysis, target analysis, plan, diff) to tmp/porting-another-repository-{YYYYMMDD-HHmm}/*.md for the user to review and apply manually. |
| [`skill-creator`](skills/skill-creator.md) | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. |

## Development

```bash
pnpm install
pnpm exec simple-git-hooks   # install the pre-commit hook
pnpm secretlint
```

The pre-commit hook runs secretlint over staged files through lint-staged.

## License

MIT
