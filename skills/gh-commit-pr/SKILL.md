---
name: gh-commit-pr
description: Create a new governed Git branch for existing repository changes, create a local English or Chinese commit when needed, push the branch, open and verify a GitHub pull request, and summarize the result. Use when the user invokes $gh-commit-pr or explicitly requests one end-to-end workflow that creates a new branch from current uncommitted or committed work and opens a PR. Default to English commits unless the user explicitly requests zh or a Chinese commit message. Do not use for commit-only requests or PR creation on an existing branch.
---

# Commit Changes And Create A GitHub PR

Run the complete branch-to-PR workflow. Invocation authorizes creating one local branch, creating one local commit when uncommitted changes exist, making an ordinary non-force push, and creating one pull request. It does not authorize amending, rebasing, resetting, force-pushing, merging, closing requests, deleting branches, changing repository settings, or discarding changes.

## Require Dependent Skills

Before running any repository-mutating command, confirm that these exact skills are installed, available to the current agent, and readable through the client's skill mechanism:

- `$git-branch-governance`
- `$git-commit-en`
- `$git-commit-zh`
- `$gh-create-pr`

Resolve each dependency by its skill name through the client's skill mechanism. If the client cannot activate a dependency by name, locate that exact skill's `SKILL.md` in the configured skill directories and read it directly. Do not infer availability from a directory name alone. If any required skill is missing or unreadable by either route, stop without creating a branch, commit, push, or PR, and tell the user exactly which skill is unavailable. Read the complete `SKILL.md` for `$git-branch-governance`, `$gh-create-pr`, and the selected commit skill before continuing. Follow each dependency's constraints during its phase; do not treat this skill's summary as a replacement for that dependency.

## Select Commit Language

- Select `$git-commit-zh` only when the user explicitly requests `zh`, `中文提交`, or a Chinese commit message. The surrounding conversation language alone does not select Chinese.
- Select `$git-commit-en` when the user explicitly requests `en` or English, and by default when no language is specified.
- If the request explicitly contains conflicting language requirements, stop and ask the user to choose one language before mutating the repository.

## Run Preflight Checks

Complete all checks before creating the branch:

1. Require `git` and `gh` on `PATH`. Require the working directory to resolve to an accessible Git repository with a named `HEAD` branch.
2. Inspect applicable repository instructions and contribution files. Preserve explicit base-branch, branch-naming, validation, and PR-template conventions.
3. Reject unresolved conflicts and any merge, rebase, cherry-pick, or revert operation in progress. Do not attempt automatic recovery.
4. Identify every staged, unstaged, untracked, and deleted path with `git status --porcelain=v1 --untracked-files=all`.
5. Resolve the intended GitHub host, target `OWNER/REPO`, GitHub default branch, base ref, push remote, and fork head owner. Use `gh repo view` and the inspection process from `$gh-create-pr`; do not assume `origin` or `main` when evidence says otherwise.
6. Require `gh auth status --hostname <host>` and `gh repo view <target> --json nameWithOwner,defaultBranchRef,url` to succeed. Require `git ls-remote` to reach the relevant Git remote. Never print or inspect token values.
7. Require the target repository, base branch, push remote, and head owner to be unambiguous. For a fork, use the fork as the push remote and the upstream repository as the PR target.
8. Fetch the target base after authentication and remote checks so committed changes are compared against current remote state. Prefer an unambiguous configured target remote; otherwise fetch the target clone URL and preserve `FETCH_HEAD` as the comparison ref. Record the exact base ref for `$gh-create-pr`. Do not update a local branch, pull, merge, or rebase.
9. Verify that the current `HEAD` is not behind `<base-ref>` using `git rev-list --left-right --count <base-ref>...HEAD`. If it is behind, stop before branch creation and ask the user to update the source branch; do not merge or rebase automatically. Stop as well when the refs have no usable merge base.
10. Inspect the complete work that would enter the PR: run `git -P diff HEAD`, read every untracked path, and inspect `git -P diff <base-ref>...HEAD`, name status, and commit log. If output truncates, continue path by path until every change is covered.
11. Determine whether work exists from both sources:
   - **Uncommitted work:** the porcelain status is non-empty.
   - **Committed work:** `HEAD` contains at least one commit not in the resolved base ref and the three-dot diff contains at least one changed path.
12. If neither source contains work, stop without mutation and tell the user there are no changes to submit.

Stop on any failed or ambiguous precondition and report the exact check that failed plus the minimum user action needed to continue. Do not create a partial workflow when preflight already proves that the PR cannot be completed.

## Create A New Branch

1. Apply `$git-branch-governance` and the repository's existing conventions to choose one short-lived work-branch name. Use its standard `<type>/<work-item>-<short-description>` grammar only when the repository has no documented equivalent.
2. Infer the narrowest supported type and description from the complete diff. Use `feature/`, `fix/`, `docs/`, `refactor/`, `test/`, or `chore/` as appropriate. Never use personal names, secrets, `changes`, `update`, or another generic description.
3. Keep the name lowercase, use only the syntax allowed by the governing convention, and prefer at most 60 characters. Check both local refs and `git ls-remote --heads <push-remote>`; if the name exists, derive another specific name and never overwrite or reuse it.
4. Before creating the local branch, run a non-mutating `git push --dry-run <push-remote> HEAD:refs/heads/<branch>` to validate remote authentication, branch-name rules, and likely push permission. Stop on failure. A dry run is not permission to perform the actual push early.
5. Create the new branch at the current `HEAD` with `git switch -c <branch>`. This preserves already-committed work and any working-tree changes. Do not reset the source branch or move commits between branches.
6. Verify that `HEAD` is attached to the new branch before continuing.

## Commit Uncommitted Work

If uncommitted work was found during preflight:

1. Invoke the selected commit skill in its explicit **commit mode**. Tell it to auto commit the complete inspected working tree. Do not request only a message and do not reproduce its message-generation rules locally.
2. Require the selected skill to inspect all changes, stage the complete reviewed change set, and create one local commit with its generated message. It must not push.
3. Verify that the commit succeeded, record its full SHA and subject, and require a clean working tree before PR creation. If hooks fail or files remain changed, stop before push and report the state without bypassing hooks or discarding changes.

If the tree was already clean and committed work exists, preserve the existing commits and do not create an empty or synthetic commit. The commit-language skill is not invoked on this path.

After either path, require a clean working tree and at least one changed path plus one commit in `<base-ref>...HEAD`. Stop if the branch would produce an empty PR.

## Create And Verify The PR

1. Invoke `$gh-create-pr` in **Create PR** mode for the new branch. Explicitly request its ordinary push and PR-creation workflow; do not stop after drafting metadata.
2. Pass the resolved target repository, base branch, base ref, push remote, and fork-qualified head when applicable. Let `$gh-create-pr` inspect the complete committed branch diff and repository PR template.
3. Create a ready PR by default. Use a draft only when the user explicitly requests one or the repository's requirements make the work intentionally not review-ready.
4. Never force-push. If a non-fast-forward push is rejected, stop and report it.
5. Let `$gh-create-pr` reject duplicate PRs and verify the created PR by reading it back. Do not create a second PR when one already exists.

## Handle Failures

- Before branch creation, fail without mutations.
- After branch creation or commit, preserve all completed local work. Do not roll back, delete the branch, reset, or amend.
- If push succeeds but PR creation or verification fails, report the published branch and the failure. Do not delete the remote branch.
- Never claim that a commit, push, PR, or check succeeded unless the corresponding command or GitHub read-back confirms it.

## Summarize The Result

Report the final outcome with the repository, base and head branches, created branch name, commit language, commit SHA and subject or preserved commit count, push remote, PR URL, draft state, and observed check status. Also report any remaining local changes or partial completion. Keep the summary concise and never expose credentials.
