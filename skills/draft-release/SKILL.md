---
name: draft-release
description: "Draft a new release of the project."
---

First, let's work on the following steps.

1. Confirm that you are currently on the main branch and pull the latest changes. If not on main branch, switch to main branch.
2. Compare code changes between the previous version tag and the latest commit to prepare the release description.

- Write in English.
- Do not include confidential information.
- Sections, `What's Changed`, `Contributors` and `Full Changelog` are needed.
- `./tmp/release-notes/*.md` will be used as the release notes.

Then, from $ARGUMENTS, get the new version without v prefix, and assign it to $new_version. For example, if $ARGUMENTS is "v1.0.0", the new version is "1.0.0".

If $ARGUMENTS is empty, determine the new version automatically by performing the `release-dry-run` skill.

Let's resume the release process.

3. Run `git pull`.
4. Run `git checkout -b release/v${new_version}`.
5. If the project hardcodes its version anywhere outside `package.json` (for example a version constant or a `getVersion()` helper in the CLI entry point), update it to ${new_version} and run the project's CI check script (`pnpm cicheck` when it exists). If the checks fail, fix the code until pass. Then, execute `git add`, `git commit` and `git push`. Skip this step when the project derives its version from `package.json` at runtime.
6. Update the version with `pnpm version ${new_version} --no-git-tag-version`.
7. Since `package.json` will be modified, execute `git commit` and `git push`.
8. As a precaution, verify that every hardcoded version location found in step 5 now reports ${new_version}.
9. Run `gh pr create` to the main branch.
10. Create a **draft** release using `gh release create v${new_version} --draft --title v${new_version} --notes-file ./tmp/release-notes/*.md` command on the repository you are working in. This creates a draft release so that the release-asset workflow can upload assets later.

Note: distribution artifacts that embed checksums of the release binaries (for example a Homebrew tap formula) are NOT updated here. Those checksums only exist after the release PR merges and the asset-publishing workflow uploads them. The `goal-release` skill performs that update as its post-merge step. When releasing manually without the `goal-release` skill, run that step yourself after the assets are published, following the project's own documented procedure.
