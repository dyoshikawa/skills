---
name: create-scrap-issue
description: >-
  Create a GitHub issue that consolidates passed content into a single scrap
  issue with background context and solution details, labeled as
  maintainer-scrap. Use when the user wants to create a scrap issue, jot down
  notes as a GitHub issue, or save findings for later.
---

Create a single GitHub issue that consolidates all the content provided by the user.

## Requirements

- Write the issue entirely in English.
- Always attach the `maintainer-scrap` label to the issue.
- Additionally, judge whether other labels are appropriate based on the content and attach them as needed. For example:
  - `bug` — if the content describes a defect or unexpected behavior
  - `enhancement` — if the content proposes a new feature or improvement
  - `documentation` — if the content relates to docs updates
  - `refactor` — if the content discusses code restructuring
  - Use `gh label list` to check available labels in the repository before attaching.
- Structure the issue so it is easy to understand even when revisited later:
  - **Background**: Describe the context, motivation, and why this matters.
  - **Details**: Include the specific content, observations, or problems passed by the user.
  - **Solution / Next Steps**: Propose a solution or outline actionable next steps.
  - **Provenance**: Where the content came from. Other skills trust `maintainer-scrap` issues because a maintainer wrote them, so say plainly when the content was derived from someone else's material — e.g. "Derived from reviewing contributor PR #123 by `login`", "From issue #45 by `login`" (no `@`, so nobody is pinged), or a web page URL. Write "Maintainer notes" only when the content is the maintainer's own.
- Use a clear, descriptive title that summarizes the scrap topic.
- Use `gh issue create` to create the issue.

## Workflow

1. Review the content provided by the user.
2. Organize and enrich it with background information and proposed solutions.
3. Check available labels with `gh label list` and determine which labels to attach in addition to `maintainer-scrap`.
4. Draft the issue body in the structure above.
5. Write the body to a file outside the working tree with the file-writing tool, then create the issue with `gh issue create --title '<title>' --body-file <body file> --label maintainer-scrap --label <other-labels>` (title in single quotes, escaping any `'` as `'\''`; never inline the body in a double-quoted `--body "..."`, where backticks and `$(...)` run in your shell).
