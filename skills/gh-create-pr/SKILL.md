---
name: gh-create-pr
description: Inspect committed Git branch changes, generate accurate GitHub pull request titles and bodies, push the current branch, create draft or ready PRs with GitHub CLI, and verify the resulting metadata. Use when the user asks to draft PR information, open/create/submit a GitHub PR, push a branch for a PR, or check PR readiness. Do not use for commit-message-only requests, code review, merging PRs, or branch-policy design.
---

# Create GitHub Pull Requests

Build PR metadata from the complete committed branch diff, then create and verify the PR only when the user requests that external action.

## Select The Mode

- **Draft metadata:** When the user asks for a title, description, summary, or preview, stay read-only and output the proposed PR information.
- **Create PR:** When the user asks to open, create, submit, or publish a PR, ordinary push of the current branch and `gh pr create` are in scope.
- **Update existing PR:** Change an existing PR only when the user explicitly asks for an update. Never silently replace its title or body.

Do not commit, amend, rebase, force-push, merge, close, delete branches, add reviewers, enable auto-merge, or change repository settings unless the user separately requests that action.

## Inspect The Repository

1. Read applicable repository instructions and contribution files before acting. Inspect `AGENTS.md`, `CONTRIBUTING*`, `.github/PULL_REQUEST_TEMPLATE*`, ownership files, and release documentation when present.
2. Resolve the base branch from the user's request. Otherwise use the repository's GitHub default branch. Do not assume `main`.
3. Run the bundled read-only inspector from the skill directory:

   ```bash
   python3 scripts/inspect-pr-context.py --repo /absolute/path/to/repository --base <base>
   ```

   Omit `--base` when it should discover the GitHub default branch. Read the complete JSON output.
4. Inspect the complete committed PR patch:

   ```bash
   git -P diff <base-ref>...HEAD
   git diff --name-status <base-ref>...HEAD
   git log --format=fuller <base-ref>..HEAD
   ```

   If output truncates, read the diff one changed path at a time until every path is covered. PR content comes from `<base-ref>...HEAD`, not from uncommitted working-tree changes.
5. Inspect recent merged PR titles when repository naming conventions are unclear:

   ```bash
   gh pr list --state merged --limit 20 --json title
   ```

## Enforce Preconditions

Before creating a PR, require all of the following:

- The checkout is a Git repository on a named non-default branch.
- The working tree has no staged, unstaged, untracked, or unmerged changes. Stop rather than creating a PR that omits local work.
- The branch contains at least one commit not in the base branch.
- `gh auth status` succeeds for the intended GitHub host.
- The target repository, base branch, push remote, and head branch are unambiguous.
- No open PR already uses the same target repository and head branch.

If an open PR already exists, return its URL and current state. Do not create a duplicate. If the repository is a fork, explicitly resolve the upstream `OWNER/REPO`, push remote, and `OWNER:branch` head; ask only when local evidence cannot resolve them safely.

## Generate Metadata

Prefer the repository's PR template and preserve its required headings. Otherwise use:

```markdown
## Summary

- <material behavior or contract change>
- <material implementation change>

## Validation

- `<command actually run>`
```

Generate metadata with these rules:

- Use the user's explicit title when provided.
- For one coherent commit, prefer its subject when it accurately describes the complete PR.
- Otherwise infer one concise title from the patch and commit range, following observed repository conventions.
- Describe behavior, contracts, migrations, and user impact; do not turn the summary into a filename inventory.
- Add 2-5 summary bullets supported by the patch.
- List only validation commands actually observed in the current task or explicitly supplied by the user. If none ran, say `Not run (not requested)`.
- Include issue links, breaking-change notices, rollout notes, or screenshots only when evidence requires them.
- Never claim approval, CI success, compatibility, or test coverage without observing it.
- Scan proposed metadata for credentials, tokens, private paths, email addresses, and unrelated local details before publishing.

In metadata-only mode, output exactly one proposed title and one complete body. Do not push or call a mutating `gh` command.

## Create The PR

Use the bundled creator after metadata is finalized. It rejects dirty/default branches, duplicate PRs, empty bodies, and non-fast-forward pushes; it never force-pushes.

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

Add `--draft` only when requested or when the PR is intentionally not review-ready. Use `--dry-run` to preview the commands without network writes. Use `--base-ref upstream/main` when the target base is not available as `origin/<base>` or a local branch. Omit `--repo-slug`, `--base-ref`, `--remote`, or `--head` only when their defaults are unambiguous.

## Verify The Result

After creation, read the PR back with `gh pr view` and verify:

- URL and open state
- exact title and non-empty body
- base and head branches
- draft state
- commit count
- current check status

If a newly created PR has incorrect or missing metadata, correct that same PR and verify it again. Report the PR URL, base/head, draft state, and observed checks. Do not wait for CI unless the user asks.

## Bundled Scripts

- `scripts/inspect-pr-context.py`: Read-only JSON inspection of Git, GitHub, branch, diff, dirty-tree, and existing-PR context.
- `scripts/create-pr.py`: Guarded branch push, PR creation, and read-back verification with structured JSON output.
