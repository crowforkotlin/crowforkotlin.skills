---
name: git-commit-en
description: Generate one precise English Git commit message from the complete working-tree status and diff. Create the local commit when the request contains auto commit, automatic commit, or an equivalent explicit request to commit. Always return the final message when changes are present, even without a commit instruction. Never push.
---

# English Git Commit Message

Generate exactly one English commit message from the repository state. Always finish message generation when changes are present. When the request contains an affirmative automatic-commit instruction, create one local commit after generating the message; otherwise remain read-only and output the message. Never push.

## Select The Mode

- **Commit mode:** Use when the request contains `auto commit`, `auto-commit`, `automatic commit`, `自动提交`, or a clear equivalent such as "commit these changes" or "提交当前修改". Match these expressions case-insensitively. Treat a positive match as authorization to create one local commit after inspection; no additional confirmation is needed.
- **Message mode:** Use for every other request, including requests for a message, draft, preview, or summary. Always inspect the repository and output one final message. Missing an auto-commit phrase is not a reason to stop, ask for confirmation, or omit the message.
- An explicit negative instruction such as `do not commit` or `不要提交` overrides an otherwise matching phrase and keeps message mode.

## Workflow

1. Confirm the working directory is inside a Git repository. Do not add separate authorization, branch-name, or workflow-state gates; report an actual Git error if a command cannot run.
2. Run `git status` to capture staged, unstaged, untracked, and unmerged paths.
3. Run `git -P diff HEAD` to capture the complete patch, including staged and unstaged changes. The `-P` option is required; do not substitute `git diff HEAD`.
4. For every untracked path reported by `git status`, inspect its contents with a read-only command. `git -P diff HEAD` does not include untracked file contents.
5. When the working tree has no changes, report that no commit can be created and return the clean-tree result without asking for more input.
6. Read all collected output. Infer the primary intent, affected scope, behavior, and risk from the status and patch. Do not infer changes that are absent from the evidence.
7. Assess change scale using the number of changed files and the total added and removed lines:

   - Treat a non-behavioral change as small when it affects at most two files and at most 15 lines.
   - Treat a change as complex when it affects five or more files, adds, deletes, or renames paths, or changes core logic.
   - Treat every other change as normal.

8. Use change scale only to choose the amount of detail in the message; never use it as a reason to stop or withhold the final message.

9. Select the commit type using the highest-priority applicable intent:

   | Intent | Type |
   | --- | --- |
   | New user-visible capability | `feat` |
   | Defect correction | `fix` |
   | Internal restructuring without behavior change | `refactor` |
   | Runtime or repository configuration | `config` |
   | Documentation-only change | `docs` |
   | Formatting-only change | `style` |
   | Build or dependency tooling | `build` |
   | Other maintenance | `chore` |

10. Write the message using the format `<type>(<scope>): <subject>`. Omit the scope when no stable module or component is clearly affected.
11. In message mode, output only the final message in one Markdown code block. Do not add a title, explanation, analysis, citation, or extra blank line.
12. In commit mode, follow the commit procedure below with this exact message and report the resulting commit information.

## Create The Commit

1. Complete all read-only inspection and finalize the message before staging anything. Keep the generated message available even if a later commit step fails.
2. Review the inspected paths for likely credentials, private keys, tokens, generated secrets, or clearly unrelated changes. Do not commit an identified risky path; report it after the final message.
3. From the repository root, run `git add -A` so the staged snapshot matches the complete working tree that the message describes. Do not silently select only part of the inspected changes.
4. Run `git diff --cached --quiet` and interpret its status exactly: `0` means the index is empty and must stop, `1` means staged changes are present, and any other status is an error that must stop.
5. Re-read `git -P diff --cached` and `git status`. Commit only the inspected snapshot; report an unexpected staged change as a Git error.
6. Create one commit using the exact generated message without Markdown fences. Put a multiline message in a temporary file outside the repository, run `git commit -F <message-file>`, and remove the temporary file whether the commit succeeds or fails. Do not interpolate the message through a shell command.
7. If staging, Git, or a hook step fails or modifies the working tree, report the generated message and the exact result. Do not bypass hooks with `--no-verify` and do not retry with a different message unless the user asks.
8. Verify the new commit with `git show --stat --oneline --decorate HEAD` and inspect `git status --short` for any remaining changes.
9. Report the commit hash, the exact message, and any remaining working-tree changes. Do not run `git push`.

Do not amend an existing commit, rebase, reset, force any operation, or push unless the user separately requests that action. Commit mode authorizes only staging the inspected working-tree changes and creating one new local commit.

## Message Rules

- Write every message line in English, regardless of the language used in source files, comments, history, or the diff.
- Use imperative mood, lowercase the subject after the colon, and omit a terminal period.
- Keep the subject specific and concise; describe the purpose rather than listing file names.
- Add 2-5 `- ` bullets for normal or complex changes. Each bullet must identify a material change supported by the diff.
- For normal or complex changes, add a short paragraph after the bullets covering motivation, key implementation details, or relevant impact. Do not invent motivation when the diff does not establish it.
- For small changes, output the subject and at most two bullets; omit the detail paragraph.
- Preserve the distinction between added, modified, deleted, renamed, copied, untracked, and unmerged paths when it affects the summary.
- Never output multiple candidate messages.

## Output Shape

```text
<type>(<scope>): <subject>

- <material change>
- <material change>

<brief implementation or impact summary>
```

The Markdown fence is presentation only and is never part of the commit message.
