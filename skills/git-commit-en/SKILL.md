---
name: git-commit-en
description: Generate one precise English Git commit message from the complete working-tree status and diff. Create one local commit when the user explicitly requests an automatic commit or clearly asks to commit the current changes. Always return the final message when changes exist. Never push.
---

# English Git Commit Message

Inspect the complete repository state and generate exactly one English commit message. Create one local commit only in explicit commit mode. Never push.

## Select The Mode

- **Commit mode:** Use when the user says `auto commit`, `auto-commit`, `automatic commit`, `自动提交`, `commit these changes`, or another clear equivalent. Match case-insensitively. This authorizes one local commit after inspection.
- **Message mode:** Use for a request for a message, draft, preview, or summary without an affirmative commit instruction. Inspect the repository and return one final message.
- An explicit `do not commit` or `不要提交` instruction overrides commit mode.

## Inspect The Complete Change Set

1. Confirm that the current directory is inside a Git repository.
2. Run `git status --short --branch` and record staged, unstaged, untracked, deleted, and unmerged paths.
3. Run `git -P diff HEAD`. Do not replace it with `git diff HEAD`; the `-P` flag prevents paging.
4. Read every untracked path separately because `git diff HEAD` does not include it.
5. Read all output before inferring the primary intent, affected scope, behavior, and risk. Do not infer a change absent from the evidence.
6. If the tree is clean, report that no commit can be created. Do not ask for more input.

## Choose The Message

Select the highest-priority applicable type:

| Change intent | Type |
| --- | --- |
| New user-visible capability | `feat` |
| Defect correction | `fix` |
| Internal restructuring without intended behavior change | `refactor` |
| Runtime or repository configuration | `config` |
| Documentation-only change | `docs` |
| Formatting-only change | `style` |
| Build or dependency tooling | `build` |
| Other maintenance | `chore` |

Use `<type>(<scope>): <subject>`. Include a scope only when a stable module or component is clearly supported by the diff.

Assess detail by changed-file count and added/removed lines:

- Small: non-behavioral, at most two files, and at most 15 changed lines.
- Complex: five or more files, a path add/delete/rename, or a core-logic change.
- Normal: every other change.

Use the scale only to choose message detail. Do not use it to stop or omit the message.

## Message Rules

- Write every message line in English.
- Use imperative mood, lowercase the subject after the colon, and omit a terminal period.
- Describe the purpose, not a list of filenames. Keep the subject specific and concise.
- Add 2-5 `- ` bullets for normal or complex changes. Each bullet must describe a material change supported by the diff.
- Add one short detail paragraph for normal or complex changes when the diff establishes motivation, implementation, or impact. Omit it for small changes.
- Preserve added, modified, deleted, renamed, copied, untracked, and unmerged distinctions when they change the summary.
- Avoid undefined jargon, filler, unsupported motivation, credentials, and private paths.
- Never output multiple candidate messages.

Use this shape:

```text
<type>(<scope>): <subject>

- <material change>
- <material change>

<brief implementation or impact summary>
```

The Markdown fence is presentation only and is not part of the commit message.

## Create The Commit

Run these steps only in commit mode:

1. Finalize the message before staging. Keep it available if a later step fails.
2. Review all paths for credentials, private keys, tokens, generated secrets, and clearly unrelated changes. Stop before staging when one is found. Report the generated message and risky path; do not commit a subset of the inspected change set.
3. From the repository root, run `git add -A` to stage the complete inspected working tree. Do not silently select a subset.
4. Run `git diff --cached --quiet`: status `0` means no staged changes and must stop; status `1` means changes are staged; any other status is an error.
5. Re-read `git -P diff --cached` and `git status --short`. Stop if the staged snapshot differs from the inspected change set.
6. Write the exact message, without Markdown fences, to a temporary file outside the repository. Run `git commit -F <message-file>`, then remove the temporary file whether the command succeeds or fails. Do not interpolate the message in a shell command.
7. Do not bypass hooks or retry with a different message after a failure.
8. Verify with `git show --stat --oneline --decorate HEAD` and `git status --short`.

In message mode, output only the final message in one Markdown code block. In commit mode, report the exact message, commit hash, and remaining changes. Never run `git push`.

Do not amend, rebase, reset, force an operation, or push unless the user separately requests it.
