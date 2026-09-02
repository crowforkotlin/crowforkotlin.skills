---
name: gh-commit-pr
description: Create a new Git branch from the current repository changes, create one local English or Chinese commit when needed, push the branch, open one GitHub pull request, and verify the result. Use when the user invokes $gh-commit-pr or explicitly requests this complete branch-to-commit-to-PR operation. Use English commits by default and Chinese commits only when explicitly requested. Do not use for commit-only requests or for creating a PR on an existing branch.
---

# Commit Changes And Create A GitHub PR

Run the complete local branch, commit, push, and pull request operation only after an explicit end-to-end request. One invocation permits one new local branch, one new local commit when uncommitted changes exist, one ordinary non-force push, and one pull request. It does not permit amending, rebasing, resetting, force-pushing, merging, closing, deleting, changing repository settings, or discarding changes.

## Load Required Skills

Before any repository-changing command, load these exact skills:

- `$git-branch-governance`
- `$git-commit-en` or `$git-commit-zh`
- `$gh-create-pr`

Resolve each name through the client's skill mechanism. If that is unavailable, read the matching `SKILL.md` from a configured skill directory. Do not infer that a dependency is available from a directory name. Stop before mutation if a required skill cannot be loaded. Read the complete branch, PR, and selected commit skill instructions.

## Select Commit Language

- Use `$git-commit-zh` only when the user explicitly requests `zh`, a Chinese commit, or Chinese commit text.
- Use `$git-commit-en` when the user explicitly requests English or when no language is specified.
- Stop and ask the user to choose one language when the request contains conflicting language instructions.

## Run Read-Only Preflight

Finish every check below before creating the branch:

1. Confirm that `git` and `gh` are available, the directory is a Git repository, and `HEAD` is attached to a named branch.
2. Read repository instructions, contribution files, pull request templates, ownership rules, and release notes that apply to the change.
3. Reject unresolved conflicts and an in-progress merge, rebase, cherry-pick, or revert. Do not repair these states automatically.
4. Record every staged, unstaged, deleted, untracked, and unmerged path with `git status --porcelain=v1 --untracked-files=all`.
5. Resolve the GitHub host, target `OWNER/REPO`, default branch, base ref, push remote, and fork head owner. Use `gh repo view` and `$gh-create-pr`; do not assume `origin` or `main` without evidence. Never inspect token values.
6. Require `gh auth status --hostname <host>`, `gh repo view <target> --json nameWithOwner,defaultBranchRef,url`, and `git ls-remote <push-remote>` to succeed. Do not inspect token values.
7. Require the target repository, base branch, push remote, and head owner to be unambiguous. For a fork, use the fork as the push remote and the upstream repository as the PR target.
8. Fetch the target base only after authentication and remote checks. Prefer the resolved target remote; otherwise fetch the target clone URL and retain `FETCH_HEAD` as the comparison ref. Record the exact base ref for `$gh-create-pr`. Do not pull, merge, rebase, update a local branch, or move a local branch.
9. Compare the current `HEAD` with the resolved base using `git rev-list --left-right --count <base-ref>...HEAD`. Stop when `HEAD` is behind the base or no usable merge base exists.
10. Inspect the complete submitted work: `git -P diff HEAD`, every untracked path, `git -P diff <base-ref>...HEAD`, name status, and commit log. Continue path by path if output is truncated.
11. Require either a non-empty working tree or at least one changed commit and path in `<base-ref>...HEAD`. Stop without mutation when there is no work to submit.

Report the exact failed check and the minimum user action when any precondition is missing or ambiguous.

## Create The Branch

1. Apply `$git-branch-governance` and repository naming rules to choose one short-lived branch name.
2. Use a specific lowercase type and description such as `feature/`, `fix/`, `docs/`, `refactor/`, `test/`, or `chore/`. Do not use personal names, secrets, `changes`, `update`, or another generic label.
3. Check local refs and `git ls-remote --heads <push-remote>`. Choose another specific name if the candidate already exists. Prefer a maximum length of 60 characters.
4. Run `git push --dry-run <push-remote> HEAD:refs/heads/<branch>` before creating the branch. Stop if the check fails.
5. Create the branch with `git switch -c <branch>` and verify that `HEAD` now names it. Preserve all existing commits and working-tree changes.

## Commit Uncommitted Work

When preflight found uncommitted changes:

1. Invoke the selected commit skill in its explicit commit mode and request one commit for the complete inspected working tree.
2. Let that skill inspect, stage, and commit the full reviewed change set. Do not recreate its message rules here, request only a message, or let it push.
3. Verify the commit SHA and subject, then require a clean working tree. Stop if hooks fail or any path remains changed; do not bypass hooks or discard changes.

When the tree was clean and committed work exists, preserve the existing commits and do not create an empty commit.

After either path, require a clean working tree, one changed path, and one commit in `<base-ref>...HEAD`. Stop before push if the branch would create an empty PR.

## Create And Verify The PR

1. Invoke `$gh-create-pr` in Create PR mode with the resolved repository, base branch, base ref, push remote, and fork-qualified head when needed.
2. Let `$gh-create-pr` inspect the committed diff, repository template, duplicate PRs, and GitHub authentication.
3. Create a ready PR unless the user explicitly requests a draft or repository evidence requires a draft.
4. Use an ordinary push only. Stop on a non-fast-forward rejection and never force-push.
5. Read the created PR back and verify its URL, open state, exact title and body, base, head, draft state, commit count, and observed checks. Do not create a second PR.

## Handle Partial Completion

- Fail before branch creation when preflight fails.
- Preserve a branch or commit already created. Do not delete, reset, amend, or roll it back automatically.
- If push succeeds but PR creation or verification fails, report the published branch and exact failure. Do not delete the remote branch.
- State only results confirmed by commands or GitHub read-back.

## Report

Report the repository, base branch, head branch, created branch, commit language, commit SHA and subject or preserved commit count, push remote, PR URL, draft state, observed check status, and remaining local changes. Keep the report factual and concise. Do not expose credentials.

## Communication Rules

- Name exact paths, commands, Git refs, API calls, and observed results.
- Use direct, restrained language. Do not add greetings, small talk, jokes, emojis, emotional wording, or sign-offs.
- Do not use undefined jargon or invented terminology. When writing Chinese, avoid `链路`, `闭环`, `沉淀`, `抓手`, `护栏`, `赋能`, `编排`, `对齐`, and `打通` unless one is a defined technical term required by the task.
- Report only actions performed, results observed, failures, and necessary next steps. Never claim that a commit, push, PR, or check succeeded without evidence.
