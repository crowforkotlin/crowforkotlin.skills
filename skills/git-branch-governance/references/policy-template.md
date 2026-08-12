# Git Branch Policy Template

Use this template only after selecting a topology and reading `references/branch-rules.md`. Replace every angle-bracket placeholder, remove guidance comments, and omit inapplicable sections. Produce one coherent policy rather than multiple options.

```markdown
# Git Branch Policy

## Scope

This policy applies to <repositories, teams, and contributors>. It governs branch creation, integration, release preparation, production fixes, and branch retirement.

The repository uses the <feature-branch | release-assisted | Git Flow> topology because <repository-specific reason>.

## Branch Contract

| Branch or pattern | Purpose | Create from | Merge into | Owner | Lifetime | Protected |
| --- | --- | --- | --- | --- | --- | --- |
| `<branch>` | <single purpose> | `<source>` | `<target>` | <role> | <duration or retirement condition> | <yes/no> |

Branches not listed in this table MUST NOT be created without an approved exception.

## Naming

Work branches MUST use `<type>/<work-item>-<short-description>`.

- Allowed types: `<minimal prefix list>`.
- Work-item rule: <required format or explicit statement that it is optional>.
- Description rule: <lowercase syntax and length limit>.
- Examples: `<valid-name>`, `<valid-name>`.

## Work Branch Workflow

1. Create the branch from the latest `<source branch>`.
2. Keep the branch limited to <scope expectation>.
3. Synchronize it with `<source branch>` by <approved synchronization method>.
4. Open a <pull request | merge request> targeting `<target branch>`.
5. Satisfy all review and automated checks.
6. Merge with <squash | merge commit | rebase merge>.
7. Delete the source branch after merge.

## Merge Requirements

A change MUST satisfy all of the following before merge:

- <required status checks>.
- <required approval count and ownership rules>.
- <discussion and conflict requirements>.
- <latest-target or merge-queue requirement>.
- <work-item, changelog, or documentation requirement>.

## Releases

<State the exact release source, stabilization path, immutable tag format, artifact creation point, and branch retirement rule.>

## Production Hotfixes

<State the qualifying severity, exact branch point, review path, release tag, deployment authority, and propagation order to every affected active line.>

## Branch And Tag Protection

The following branches and patterns MUST be protected: `<patterns>`.

Protection MUST:

- Require <pull requests or merge requests> and passing checks.
- Block force pushes and deletion.
- Restrict bypass access to <roles>.
- Require <approval and code-owner settings>.
- Protect release tags matching `<tag pattern>` from deletion or retargeting.

## Lifecycle

- Work branches SHOULD live for no more than <duration>.
- Merged branches MUST be deleted <automatically or by role>.
- Stale branches are reviewed after <duration> and handled by <owner/process>.
- Release and support branches are retired when <condition>.

## Exceptions

An exception requires approval from <owner>. The request MUST record the bypassed rule, reason, scope, actor, start time, expiration, follow-up validation, reconciliation, and cleanup. Emergency actions MUST receive retrospective review within <duration>.

## Ownership And Review

<role> owns this policy. Review it every <interval> and after any material change to release cadence, deployment architecture, supported-version policy, or repository-host controls.
```

## Adaptation Rules

- For a feature-branch workflow, omit a separate release-branch table entry and describe releases from `main`.
- For a release-assisted workflow, include `release/*` or `support/*` only when the repository actually uses that lifecycle.
- For Git Flow, include `main`, `develop`, `feature/*`, `release/*`, and `hotfix/*`, including every back-merge or forward-port target.
- For an existing repository, add a migration section with current state, target state, ordered protection changes, open-branch handling, cutover date, owner, and rollback plan.
- For a GitHub-specific request, translate requirements into rulesets, required reviews, required status checks, merge queue, deletion, force-push, and tag rules as applicable.
- For a GitLab-specific request, translate requirements into protected branches and tags, approval rules, status checks or pipelines, merge trains, push and merge roles, and deletion rules as applicable.
- Label unavailable plan or tier features as optional controls; never present them as already enabled.
