---
name: gh-create-pr
description: Inspect committed Git branch changes, draft accurate GitHub pull request metadata, push the current branch, create a draft or ready pull request with GitHub CLI, and verify the returned metadata. Use when the user asks to draft, open, create, submit, publish, or update a GitHub PR, push a branch for a PR, or check PR readiness. Do not use for commit-message-only work, code review, merging, or branch-policy design.
---

# Create GitHub Pull Requests

Build pull request metadata from the complete committed branch diff. Keep metadata-only work read-only. Push and create a PR only when the user explicitly requests that action.

## Select A Mode

- **Draft metadata:** Return one proposed title and one complete body. Do not push or run a mutating `gh` command.
- **Create PR:** Inspect, push the current branch with an ordinary non-force push, create one PR, and verify it.
- **Update existing PR:** Change an existing PR only when the user explicitly requests the change. Preserve fields the user did not ask to change.

Do not commit, amend, rebase, force-push, merge, close, delete branches, add reviewers, enable auto-merge, or change repository settings unless separately requested.

## Inspect The Repository

1. Resolve the requested base branch. Otherwise use the GitHub default branch returned by the repository, not an assumed name.
2. Run the bundled read-only inspector from this skill directory:

   ```bash
   python3 scripts/inspect-pr-context.py --repo /absolute/path/to/repository --base <base>
   ```

   Omit `--base` when the inspector should discover the GitHub default branch. Read the complete JSON output.

3. Require a named non-default current branch and a clean working tree for PR creation. A dirty tree means the PR would omit local changes; stop and report it.
4. Inspect every committed change with:

   ```bash
   git -P diff <base-ref>...HEAD
   git diff --name-status <base-ref>...HEAD
   git log --format=fuller <base-ref>..HEAD
   ```

   Read each changed path separately when output is truncated. PR metadata must describe `<base-ref>...HEAD`, not uncommitted files.

5. Require at least one commit and one changed path ahead of the base. Inspect recent merged PR titles with `gh pr list --state merged --limit 20 --json title` only when repository naming conventions are unclear.

## Check Creation Preconditions

Before creating a PR, confirm all of the following:

- The checkout is a Git repository on a named non-default branch.
- The working tree has no staged, unstaged, untracked, or unmerged changes.
- The branch contains a commit and a changed path not present in the base.
- `gh auth status` succeeds for the intended GitHub host.
- The target repository, base branch, push remote, and head branch are unambiguous.
- No open PR already uses the same target repository, base, and head owner/branch.

For a fork, resolve the upstream target, fork push remote, and `OWNER:branch` head explicitly. Ask the user only when local Git and GitHub evidence cannot resolve them safely. If an open PR exists, return its URL and current state instead of creating another one.

## Draft Metadata

Use the repository's PR template and required headings. Without a template, use:

```markdown
## Summary

- <material behavior or contract change>
- <material implementation change>

## Validation

- `<command actually run>`
```

Apply these rules:

- Use the user's explicit title when provided.
- Use the single commit subject when it accurately describes the whole change; otherwise infer one concise title from the patch and commit range.
- Describe behavior, contracts, migrations, and user impact. Do not produce a filename inventory.
- Include 2-5 summary bullets supported by the patch.
- List only validation commands actually run or explicitly supplied by the user. Use `Not run (not requested)` when none ran.
- Add issue links, breaking-change notices, rollout notes, or screenshots only when the evidence requires them.
- Never claim approval, CI success, compatibility, or test coverage without observing it.
- Remove credentials, tokens, private paths, email addresses, and unrelated local details before publishing.

In metadata-only mode, output exactly one title and one complete body.

## Create The PR

After metadata is final, run the bundled creator from this skill directory:

```bash
python3 scripts/create-pr.py \
  --repo /absolute/path/to/repository \
  --repo-slug OWNER/REPO \
  --base <base> \
  --base-ref <local-base-ref> \
  --remote <push-remote> \
  --head <branch-or-owner:branch> \
  --title '<title>' \
  --body '<complete-markdown-body>' \
  --push
```

Add `--draft` only when requested or required by the repository. Use `--dry-run` to validate local state and print commands without network writes. Use an explicit `--base-ref` such as `upstream/main` when the target base is not available as `origin/<base>` or a local branch. Omit optional arguments only when their defaults are unambiguous.

## Verify The Result

After creation, run `gh pr view` and verify:

- URL and open state
- exact title and non-empty body
- base and head branches and head owner
- draft state
- commit count
- current check status

If a PR created in this invocation has incorrect or missing metadata, correct that same PR and read it back again. Do not wait for CI unless the user requests it.

## Report

Lead with the result. Report the PR URL, repository, base/head, draft state, commit count, observed checks, validation commands, and any failure or remaining change. Use only observed facts and do not expose credentials.

## Communication Rules

- Name exact paths, commands, Git refs, API calls, and observed results.
- Use direct, restrained language. Do not add greetings, small talk, jokes, emojis, emotional wording, or sign-offs.
- Do not use undefined jargon or invented terminology. When writing Chinese, avoid `链路`, `闭环`, `沉淀`, `抓手`, `护栏`, `赋能`, `编排`, `对齐`, and `打通` unless one is a defined technical term required by the task.
- Report only actions performed, results observed, failures, and necessary next steps. Never claim that a PR, push, check, or metadata update succeeded without evidence.

## Bundled Scripts

- `scripts/inspect-pr-context.py`: Return JSON for Git, GitHub, branch, diff, dirty-tree, remote, and existing-PR state without changing the repository.
- `scripts/create-pr.py`: Validate a clean branch, optionally push it, create one PR, reject duplicates, and verify returned metadata.
