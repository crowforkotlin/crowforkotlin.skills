---
name: gh-create-issue
description: Draft, create, or update GitHub issues in English with reproducible commands and an explicit severity level. Use when the user asks to report, file, open, write, or rewrite a bug, defect, regression, or design gap, or asks for an issue template, severity scale, or reproduction steps for an issue. Produces bodies whose every claim is backed by a command the reporter ran, whose commands work in zsh and bash, and whose prose avoids abstract or filler wording. Do not use for pull requests, commits, or code review.
---

# Report Verifiable GitHub Issues

An issue is usable when a maintainer can run one command block and see the
reported behavior. Write in English. Name files, symbols, commands, and observed
output; drop everything else.

## Select A Mode

- **Draft**: return one title and one complete body. Do not call a mutating
  `gh` command.
- **Create**: create exactly one issue after the body passes the checks below.
- **Update**: replace the body of an existing issue. Keep its title and
  labels unless the user asked to change them.

Do not close, label, assign, or comment on other issues unless asked.

## Required Body

Use [assets/issue-template.md](assets/issue-template.md) unchanged. The five
headings are mandatory and stay in this order:

1. `Severity: <level>` — the first line of the body, with an optional reason in
   parentheses.
2. `## Impact` — what breaks, for whom, under which configuration.
3. `## Location` — `path:line` for every file that must change, with the
   symbol or expression at that line.
4. `## Reproduction` — commands and their observed output.
5. `## Expected` — the behavior that would make the issue closable.

Add `## Scope` only when the defect is limited to one entry point, platform, or
option; state what is unaffected. Add `## Notes` only for a first-seen commit or
a linked issue.

## Choose The Severity

Read [references/severity-levels.md](references/severity-levels.md). Judge the
reach of the defect first, then the trigger. Summary:

| Level | Reach |
| --- | --- |
| `critical` | Core functionality unusable, severe data damage, a security violation, or a system-wide failure. |
| `high` | Core functionality, a critical runtime flow, or a compatibility contract breaks; no workaround. |
| `medium` | Part of the functionality, one scenario, or one platform breaks; a workaround exists. |
| `low` | Edge cases, misleading diagnostics, documentation drift, or non-core paths. |

A defect that fails closed (rejects input it should accept) is `low`. A defect
that fails open (accepts input it should reject) is at least `medium`.

## Write Reproduction Commands

Every command in `## Reproduction` must have been executed by you before
publishing, and its real output must appear in the body.

- Resolve the repository root once at the top of the block with an explicit
  `cd /absolute/path/to/repo` or `cd "$(git rev-parse --show-toplevel)"`.
- Quote every glob. In zsh, `--include=*.kt` fails with
  `no matches found: --include=*.kt`; write `--include='*.kt'`.
- Prefer `git grep -n 'pattern' -- '*.kt'` over `grep -rn --include=...`.
  `git grep` searches tracked files only, so build output and
  `node_modules` never pollute the result.
- Prefer commands with stable output: exit codes, file modes, byte counts,
  HTTP status codes. Do not paste interleaved log noise.
- Paste observed output verbatim in a separate block, prefixed with the command
  that produced it. Trim unrelated lines; never invent, reformat, or round
  numbers.
- Remove shell prompts, `JAVA_TOOL_OPTIONS` notices, and timestamps.
- No placeholders. `<cli>`, `<repo>`, `<path>`, `...`, `TODO`, and `TBD` are
  rejected by the checker; write the concrete value.

Read [references/verification-commands.md](references/verification-commands.md)
for command shapes that work in both zsh and bash, and for the Gradle and JVM
harness patterns used in this repository family.

## Write Prose

- One claim per sentence. State the condition, then the result.
- Name the symbol and file. "The cache ignores the limit" is rejected;
  `WasmlineFileCache.put()` protects the entry it just wrote, so the newest entry
  is never a trim candidate is accepted.
- No motivation, benefit, or roadmap sentences. No praise. No "it would be
  nice if". No restating the title in the first paragraph.
- Do not describe a fix. If the issue must state a direction, keep it to one
  sentence under `## Expected` and phrase it as an acceptance condition.
- Drop these words: simply, obviously, clearly, robust, seamless, holistic,
  leverage, utilize, various, proper, properly, ensure, make sure, as needed,
  etc., and so on, some issues, should work.
- Write `low`, not `low severity issue`. Write `404`, not `an error`.
- English only. No mixed-language sentences, no Chinese punctuation.

## Check Before Publishing

Run the bundled checker on the exact body file:

```bash
python3 scripts/check-issue-body.py --body issue.md --title 'fix(loader): enforce the cache byte limit'
```

It rejects a missing heading, a missing fenced command block, a placeholder, a
non-English character, a banned word, a severity outside the four levels, and a
title that is not `<type>(<scope>): <summary>` or longer than 72 characters.
Fix every reported line, then run it again.

## Create Or Update

```bash
gh auth status
gh issue create --repo <owner>/<repo> --title '<title>' --body-file issue.md
gh issue edit <number> --repo <owner>/<repo> --body-file issue.md
```

After the call returns, read the issue back and confirm the posted body matches
the file:

```bash
gh issue view <number> --repo <owner>/<repo> --json title,body --jq '.title, .body' | head -40
```

Report the issue URL. If the call fails, report the exact `gh` error and the
body file path; do not claim the issue exists.
