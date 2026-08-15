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

7. Always write the message using the format `<type>(<scope>): <subject>`; `<scope>` is required. Select the narrowest stable English module or component scope supported by the diff. If no stable module or component is clear, use a concise English scope for the affected area; use `workspace` only when no narrower scope is supported by the evidence. A scope may contain only lowercase ASCII letters, digits, and hyphens (for example, `auth`, `photo-grid`, or `ios-build`); never omit it.
8. Output only the message in one Markdown code block. Do not add a title, explanation, analysis, citation, or extra blank line.

## Message Rules

- Write the subject, bullets, and detail paragraph in Chinese. Write `<type>` and `<scope>` in English; keep the conventional type token (`feat`, `fix`, `refactor`, `config`, `docs`, `style`, `build`, or `chore`) unchanged.
- Always include `<scope>`. Write it as a concise English module, component, or affected-area identifier using only lowercase ASCII letters, digits, and hyphens. Never use Chinese, pinyin, or translated prose as a scope. Use `workspace` when the evidence does not support a narrower English scope.
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

For example:

```text
fix(photo-grid): 修复相册网格滚动时的重复加载
```
