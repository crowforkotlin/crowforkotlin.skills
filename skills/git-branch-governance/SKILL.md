---
name: git-branch-governance
description: Design, audit, and document Git branch rules, including branch names, sources, merge targets, releases, hotfixes, protection, cleanup, and exceptions. Use when creating or reviewing branching policy, CONTRIBUTING guidance, branch protection settings, release procedures, or the choice between a feature-branch, release-assisted, or Git Flow model.
---

# Git Branch Governance

Produce one branch policy that a contributor can follow and a repository owner can enforce. Select the least complex branch model supported by the repository's release and support requirements.

## Inspect Before Writing

1. Read contribution, release, deployment, ownership, and CI documentation.
2. Inspect the default branch, active long-lived branches, tags, recent merge history, and repository-host settings when access is available.
3. Record the actual release cadence, deployment frequency, supported versions, validation environments, team access model, and emergency-fix requirements.
4. Preserve existing explicit rules unless the user asks for migration. Mark every unresolved material fact as an assumption.
5. Read [branch-rules.md](references/branch-rules.md) before designing or auditing a policy. Apply the common rules and exactly one topology section.

## Select One Topology

| Topology | Select when | Branches |
| --- | --- | --- |
| Feature branch | The repository has one current line, frequent integration, and releases from the default branch | Protected `main` and short-lived work branches |
| Release-assisted | The repository stabilizes scheduled releases or supports multiple versions | Protected `main`, short-lived work branches, and temporary `release/*` or active `support/*` branches |
| Git Flow | Separate integration and production histories are required for scheduled releases and parallel hotfix work | Protected `main` and `develop`, plus `feature/*`, `release/*`, and `hotfix/*` branches |

Choose the feature-branch model when the evidence does not require another long-lived branch. Do not add `develop`, release branches, or environment branches by habit. Treat fork access as a contribution method layered over the selected model.

## Define The Branch Contract

For every allowed branch or pattern, specify all of the following:

- one purpose
- one source branch or commit
- one merge target
- one owner role
- one lifetime or retirement condition
- protection and required checks
- deletion or retention rules

Use the standard name grammar only when the repository has no documented equivalent:

```text
<type>/<work-item>-<short-description>
```

Use lowercase ASCII letters, digits, hyphens, and one slash. Do not use spaces, underscores, personal names, generic labels such as `changes`, secrets, or nested path segments. Prefer a maximum length of 60 characters. Use only prefixes the repository needs, such as `feature/`, `fix/`, `docs/`, `refactor/`, `test/`, and `chore/`; reserve `release/`, `support/`, and `hotfix/` for the selected topology.

## Define Merge And Release Controls

- Name exact source and target branches. Do not write `merge upstream` or `merge to the release branch` without branch names.
- Require the checks, reviews, ownership approvals, discussion resolution, conflict status, and current-target validation needed before merge.
- Choose one default merge method: squash, merge commit, or rebase merge. State the reason and any release or hotfix exception.
- Release from a reviewed immutable commit or tag. Do not move or reuse a published release tag.
- State how a release fix or production hotfix reaches every affected active line, in order.
- Prefer promoting immutable artifacts over branches named after environments. Document an environment-branch exception only when the deployment system requires it.

## Map To Repository Controls

Translate the policy into controls the repository host can enforce:

- required pull or merge requests
- required build, test, lint, security, and policy checks
- reviewer and code-owner rules
- merge strategy and merge queue, when available
- blocked force pushes and deletion on protected branches and tags
- limited bypass access with recorded reason and follow-up review
- automatic deletion or scheduled review of merged and stale work branches

Do not claim a control is enabled unless repository evidence confirms it. Label unavailable product or plan features as proposed or optional.

## Review The Policy

Confirm that:

- ordinary work has exactly one default integration path;
- every branch type has one source, target, owner, and retirement rule;
- releases point to immutable tags or commits;
- protected branches reject direct pushes, force pushes, and accidental deletion unless an explicit exception applies;
- required checks and reviews run before merge;
- release and hotfix changes reach every affected active line;
- naming examples satisfy the declared grammar;
- exceptions have an owner, start time, expiration time, follow-up validation, and cleanup.

## Produce The Result

For a design request, return the selected topology, evidence-based reason, branch contract, naming rules, merge and protection controls, release and hotfix procedure, and migration steps when current practice differs.

For an audit, report concrete conflicts and missing controls first, with repository evidence, then provide corrected policy language or settings.

For an implementation request, edit only the requested documentation or configuration. Do not change remote protections, delete branches, rewrite history, or push unless the user explicitly authorizes those actions.

Use [policy-template.md](references/policy-template.md) for a ready-to-adopt policy document. Replace every placeholder, remove guidance comments, and omit sections that do not apply.

## Communication Rules

- Name the repository evidence, branch names, controls, commands, and observed settings that support each conclusion.
- Use direct, restrained language. Do not add greetings, small talk, jokes, emojis, emotional wording, or sign-offs.
- Do not use undefined jargon or invented terminology. When writing Chinese, avoid `链路`, `闭环`, `沉淀`, `抓手`, `护栏`, `赋能`, `编排`, `对齐`, and `打通` unless one is a defined technical term required by the task.
- Report observed controls separately from proposed controls. Do not claim that a protection rule, check, or branch operation exists without evidence.
