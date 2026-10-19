# Skills

A collection of 45 skills for maintaining OSS projects on GitHub — triaging issues, reviewing and merging pull requests, cutting releases, and keeping branches tidy — plus a few general-purpose ones for writing, notes and workspace tooling.

Each skill is a `SKILL.md` with YAML frontmatter, following the [Agent Skills](https://code.claude.com/docs/en/skills) convention, so it can be used with any coding agent that reads that format.

## Installation

### With `skills`

The [`skills`](https://www.npmjs.com/package/skills) CLI copies skills straight into your project.

```bash
# See what is in here first
npx skills add dyoshikawa/skills --list

# Install everything
npx skills add dyoshikawa/skills

# Install only what you need
npx skills add dyoshikawa/skills --skill review-pr --skill merge-pr

# Install for a specific agent, into the user directory, without prompts
npx skills add dyoshikawa/skills -a claude-code -g -y
```

### With `rulesync`

[`rulesync`](https://www.npmjs.com/package/rulesync) fetches skills into `.rulesync/` and generates the config files for every agent you target, so one copy feeds Claude Code, Cursor, Copilot, and the rest.

```bash
# Fetch into .rulesync/ (the fetch command defaults to --features skills)
npx rulesync fetch dyoshikawa/skills

# Fetch only some skills, or pick them from a checkbox prompt
npx rulesync fetch dyoshikawa/skills --skills review-pr,merge-pr
npx rulesync fetch dyoshikawa/skills --interactive

# Then emit the per-agent config files
npx rulesync generate
```

To keep the skills declared rather than copied ad hoc, add them to `rulesync.jsonc` and run `npx rulesync install`:

```jsonc
{
  "targets": ["claudecode", "copilot"],
  "features": ["skills"],
  "sources": [{ "source": "dyoshikawa/skills", "skills": ["review-pr", "merge-pr"] }],
}
```

## Layout

```
skills/
└── <name>/
    ├── SKILL.md
    └── references/   # supporting material, for the few skills that ship it
```

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
| [`create-issue`](skills/create-issue/SKILL.md) | Create a GitHub issue with detailed description, purpose, and appropriate labels |
| [`create-issue-with-websearch`](skills/create-issue-with-websearch/SKILL.md) | Create a GitHub issue from a vague idea by thoroughly researching the topic on the web to sharpen the specification before filing |
| [`create-scrap-issue`](skills/create-scrap-issue/SKILL.md) | Create a GitHub issue that consolidates passed content into a single scrap issue with background context and solution details, labeled as maintainer-scrap. Use when the user wants to create a scrap issue, jot down notes as a GitHub issue, or save findings for later. |
| [`draft-issue-to-external-repository`](skills/draft-issue-to-external-repository/SKILL.md) | Draft a GitHub issue targeting a third-party repository (outside this project's owner). Researches the target repo's conventions and the topic in depth, iterates with the user on scope and tone, and produces a final body saved to tmp/external-repository-issues/*.md for the user to post manually when gh auth lacks permission on the target. |
| [`explain-issue`](skills/explain-issue/SKILL.md) | Explain a GitHub issue: the background problem and the proposed solution |
| [`post-issue-comment`](skills/post-issue-comment/SKILL.md) | Post a reply comment on a GitHub issue in English with a natural, concise writing style, based on the intent passed as arguments |
| [`triage-issues`](skills/triage-issues/SKILL.md) | Triage open GitHub issues by reviewing unlabeled ones and applying the most appropriate labels based on their content |
| [`understand-scrap-issues`](skills/understand-scrap-issues/SKILL.md) | Fetch the most recent maintainer-scrap issues (up to 3) and understand their content |
| [`resolve-scrap-issues`](skills/resolve-scrap-issues/SKILL.md) | Fetch recent maintainer-scrap issues, validate each with web research, then either close the ones that need no action or open a single consolidated pull request that resolves the ones that do |
| [`batch-all-issues`](skills/batch-all-issues/SKILL.md) | Resolve every open issue one at a time: fact-check each with web research, close the ones that need no action, and run the `goal-pr` skill to fix, review, and merge the ones that do — repeating until no actionable issues remain. |
| [`batch-all-scrap-issues`](skills/batch-all-scrap-issues/SKILL.md) | Resolve every open maintainer-scrap issue one at a time: fact-check each with web research, close the ones that need no action, and run the `goal-pr` skill to fix, review, and merge the ones that do — repeating until no actionable scrap issues remain. |

### Pull requests

| Skill | Description |
| --- | --- |
| [`commit-push-pr`](skills/commit-push-pr/SKILL.md) | Commit current changes, push to remote, and create or update a pull request. Use when the user wants to commit and create a PR, push changes and open a pull request, or ship their current work as a PR. |
| [`explain-pr`](skills/explain-pr/SKILL.md) | Explain a PR: the background problem and the proposed solution |
| [`diff-analyze`](skills/diff-analyze/SKILL.md) | Analyze the differences between the current branch and origin/main, and summarize the current work progress |
| [`review-pr`](skills/review-pr/SKILL.md) | Review a pull request for code quality and security issues. Use when the user wants to review a PR, check PR code changes, or audit a pull request. Triggers on: "review PR", "review pull request", "check this PR", "the `review-pr` skill". |
| [`review-pr-lite`](skills/review-pr-lite/SKILL.md) | Review a pull request for code quality and security issues without using subagents. Use when the user wants a lighter-weight PR review in a single skill. |
| [`review-and-comments`](skills/review-and-comments/SKILL.md) | Review a PR for code quality and security issues, then post review comments on it. Runs review-pr followed by post-review-comments sequentially. |
| [`post-review-comments`](skills/post-review-comments/SKILL.md) | Post line-level review comments and an overall review comment on a PR in English with a natural, concise writing style |
| [`opencode-gpt-review`](skills/opencode-gpt-review/SKILL.md) | Run the `review-pr` skill on another model (github-copilot/gpt-5.4) via opencode, then thoroughly investigate and vet the resulting findings, and present only the valid ones to the user. |
| [`security-scan-diff`](skills/security-scan-diff/SKILL.md) | Scan for malicious code in git diff between a tag/commit and HEAD |
| [`goal-pr`](skills/goal-pr/SKILL.md) | Drive a pull request to a clean state and merge it: run the `review-pr` skill, fix every mid-or-above finding, and repeat until no mid-or-above findings remain, then merge. Use when the user wants to finish a PR by reviewing, fixing, and merging it, or triggers on "the `goal-pr` skill". |
| [`merge-pr`](skills/merge-pr/SKILL.md) | Merge a pull request using gh pr merge --admin |
| [`prs-awaiting-author`](skills/prs-awaiting-author/SKILL.md) | List open pull requests where the ball is in the author's court: CI is failing, review comments are unaddressed, or a maintainer question is awaiting the author's reply. Use when the user wants to see PRs awaiting author action. |
| [`prs-awaiting-maintainer`](skills/prs-awaiting-maintainer/SKILL.md) | List open pull requests where the ball is in the maintainer's court: CI is green and the PR is ready for a maintainer to review, re-review, or merge. Use when the user wants to see PRs awaiting maintainer action. |
| [`batch-review-prs-awaiting-maintainer`](skills/batch-review-prs-awaiting-maintainer/SKILL.md) | Batch-triage open pull requests: list PRs with prs-awaiting-maintainer, review each with review-pr, then post-review-comments when there are merge-blocker findings, or create-scrap-issue for non-blocking findings and merge-pr when there are none. Use when the user wants to review and resolve a batch of PRs in one pass. |
| [`babysit-dependabot-pr`](skills/babysit-dependabot-pr/SKILL.md) | Babysit a Dependabot dependency-bump PR all the way to merge: verify the author is the genuine Dependabot bot, diagnose and resolve any CI failure (excluding or fixing a breaking bump when needed), get every check green, and merge. Use when the user wants to shepherd a Dependabot bump PR to merge. |

### Releases

| Skill | Description |
| --- | --- |
| [`release-dry-run`](skills/release-dry-run/SKILL.md) | Dry run for release: summarize changes since last release and suggest version bump. |
| [`draft-release`](skills/draft-release/SKILL.md) | Draft a new release of the project. |
| [`goal-release`](skills/goal-release/SKILL.md) | Cut a release end to end: use the `draft-release` skill to open the release PR and draft GitHub release, wait for CI to turn green, run the `merge-pr` skill to merge the release PR, then finish any post-release distribution updates that depend on the published release assets. Use when the user wants to draft and merge a release in one go, or triggers on "the `goal-release` skill". |
| [`draft-release-post`](skills/draft-release-post/SKILL.md) | リリース告知のXポスト下書きを作成する |

### Branches and worktrees

| Skill | Description |
| --- | --- |
| [`pull-main`](skills/pull-main/SKILL.md) | Switch to main branch and pull latest changes with prune. Use when the user wants to pull latest main, update main, or sync main with remote. |
| [`rebase-latest-main`](skills/rebase-latest-main/SKILL.md) | Fetch latest origin/main and rebase it onto the current branch, resolving conflicts if necessary. Use when the user wants to rebase on main, update their branch with latest main, or sync with upstream. |
| [`clean-branches`](skills/clean-branches/SKILL.md) | Clean up unnecessary local branches and prune stale remote-tracking branches |
| [`clean-worktrees`](skills/clean-worktrees/SKILL.md) | Clean git worktrees created by git-worktree-runner |
| [`git-worktree-runner`](skills/git-worktree-runner/SKILL.md) | Manages git worktrees using git-worktree-runner (gtr). Use when the user needs to create, list, remove, or navigate worktrees with `git gtr` commands, open editors or AI tools in worktrees, manage parallel development branches, or check out GitHub PRs (including from forks) into worktrees. |

### Workspace and memory

These assume a workspace that keeps several repositories cloned under `repos/` and long-lived notes under `memories/` (one file per repository in `memories/repos/`, one per technical area, indexed by `memories/README.md`). `sync-repo-skills` also expects the workspace to be managed with `rulesync` (it writes `.rulesync/skills/` and runs `rulesync generate`).

| Skill | Description |
| --- | --- |
| [`record-session-memory`](skills/record-session-memory/SKILL.md) | Record what this session taught into the git-managed memory files under memories/ — pitfalls to watch for in later sessions and domain knowledge worth reusing — split by repository and by technical area. Use when the user asks to remember something, to save the session's learnings, or at the end of a piece of work that produced non-obvious knowledge. |
| [`garbage-collect-memory`](skills/garbage-collect-memory/SKILL.md) | Garbage-collect the git-managed memory files under memories/: delete knowledge that no longer holds or is no longer needed, and merge duplicated entries into one — within a file and across the repository and topic files — so the memory stays short, current and consistent. Use when the user asks to clean up, prune, tidy, deduplicate or garbage-collect the memories, or when the memory files have grown long enough that stale or repeated entries get in the way. |
| [`sync-repo-skills`](skills/sync-repo-skills/SKILL.md) | Mirror the skills of a repository under repos/ into this workspace as `<repo>-<name>` copies (`repos/<repo>/.rulesync/skills/<name>` -> `.rulesync/skills/<repo>-<name>`), rewriting each copy's name and its references to sibling skills so the imported set calls itself, and removing copies whose source skill is gone. Use when the user asks to import or sync a repository's skills into the workspace, e.g. "repos/rulesync のスキルを同期", "sync the rulesync skills", "take repo X's skills into the workspace". |

### Other

| Skill | Description |
| --- | --- |
| [`grilling`](skills/grilling/SKILL.md) | Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases. |
| [`playwright-cli`](skills/playwright-cli/SKILL.md) | Automate browser interactions, test web pages and work with Playwright tests. |
| [`porting-another-repository`](skills/porting-another-repository/SKILL.md) | Plan how to port a feature, configuration, or implementation from this repository into another repository. Analyzes the source feature here and the target repo's conventions, then writes a multi-file porting plan (overview, source analysis, target analysis, plan, diff) to tmp/porting-another-repository-{YYYYMMDD-HHmm}/*.md for the user to review and apply manually. |
| [`security-scan-repository`](skills/security-scan-repository/SKILL.md) | Scan an entire repository for security issues and malicious code — leaked secrets, injection and code-execution flaws, supply chain and CI/CD risks, insecure configuration, and malicious instructions hidden in AI rule files. Use when the user wants a whole-repository security scan or audit, rather than the diff-scoped `security-scan-diff`. |
| [`skill-creator`](skills/skill-creator/SKILL.md) | Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations. |
| [`yomiyasu`](skills/yomiyasu/SKILL.md) | AIが生成した日本語の推敲に使うスキル。「この文章を読みやすくして」「AIっぽさをなくして」「自然な日本語にして」「文章を脱臭して」といった依頼や、技術記事、仕様書、PR説明文、社内レポート、エッセイ・noteの文章を見直すときに使用する。意味と条件を保ち、不自然な比喩、曖昧な主述関係、不要な装飾やコピー調を整える。 |
| [`zenn-cli`](skills/zenn-cli/SKILL.md) | Zenn CLI による Scrap の一覧・取得・作成・更新・コメント投稿を、安全に行う。`zenn-cli`、Scrap、API キー、公開範囲、Secret・AI scan を扱う時に使う。 |

## Third-party skills

[`grilling`](skills/grilling/LICENSE.txt) ([mattpocock/skills](https://github.com/mattpocock/skills)) and [`yomiyasu`](skills/yomiyasu/LICENSE) ([nanaism/yomiyasu](https://github.com/nanaism/yomiyasu)) are redistributed under their own MIT licenses, which ship inside their directories.

## Development

```bash
pnpm install
pnpm exec simple-git-hooks   # install the pre-commit hook
pnpm secretlint
```

The pre-commit hook runs secretlint over staged files through lint-staged.

## License

MIT
