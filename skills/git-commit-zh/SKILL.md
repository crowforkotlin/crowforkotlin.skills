---
name: git-commit-zh
description: Generate one precise Chinese Git commit message from the complete working-tree status and diff. Use when the user requests a Chinese commit message or asks to summarize current Git changes for a commit in Chinese.
---

# Chinese Git Commit Message

Generate exactly one Chinese commit message from the repository state. Do not modify files, stage changes, create commits, or perform any other write operation.

## Workflow

1. Run `git status` to capture staged, unstaged, untracked, and unmerged paths.
2. Run `git -P diff HEAD` to capture the complete patch, including staged and unstaged changes. The `-P` option is required; do not substitute `git diff HEAD`.
3. For every untracked path reported by `git status`, inspect its contents with a read-only command. `git -P diff HEAD` does not include untracked file contents.
4. Read all collected output. Infer the primary intent, affected scope, behavior, and risk from the status and patch. Do not infer changes that are absent from the evidence.
5. Assess change scale using the number of changed files and the total added and removed lines:

   - Treat a non-behavioral change as small when it affects at most two files and at most 15 lines.
   - Treat a change as complex when it affects five or more files, adds, deletes, or renames paths, or changes core logic.
   - Treat every other change as normal.

6. Select the commit type using the highest-priority applicable intent:

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

7. Write the message using the format `<type>(<scope>): <subject>`. Omit the scope when no stable module or component is clearly affected.
8. Output only the message in one Markdown code block. Do not add a title, explanation, analysis, citation, or extra blank line.

## Message Rules

- Write every message line in Chinese, including the subject, bullets, and detail paragraph. Keep the conventional type token (`feat`, `fix`, `refactor`, `config`, `docs`, `style`, `build`, or `chore`) unchanged.
- Use an imperative, direct subject after the colon and omit a terminal period.
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
