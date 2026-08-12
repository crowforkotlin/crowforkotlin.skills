# Branch Rules

Use these rules as the normative basis for a repository-specific Git branching policy. Apply the common rules first, then apply exactly one topology section.

## Common Invariants

- Designate one default branch. Prefer `main` for new repositories; preserve an existing default name until an explicit migration is approved.
- Keep the default branch buildable and protected. Under a continuous-release model, keep it deployable at all times.
- Integrate changes through pull or merge requests. Permit direct pushes only through a documented emergency exception.
- Give every branch one purpose and one responsible owner.
- Create work branches from an up-to-date approved source and keep them narrowly scoped.
- Require automated validation appropriate to the change before merge.
- Resolve discussions and required reviews before merge.
- Never rewrite shared or protected branch history.
- Identify releases with immutable, protected tags. Do not move or reuse a published release tag.
- Delete merged work branches promptly. Retain long-lived, release, and support branches only while their documented purpose remains active.

## Standard Branch Names

Use this grammar unless the repository already has a documented equivalent:

```text
<type>/<work-item>-<short-description>
```

Apply these syntax rules:

- Use lowercase ASCII letters, digits, hyphens, and exactly one slash after the type.
- Normalize a tracker key to lowercase, such as `proj-142`.
- Require the work-item segment when the team uses an issue tracker; omit it when no stable work item exists.
- Keep the description brief, imperative or noun-based, and meaningful outside the author's local context.
- Do not use spaces, underscores, personal names, generic labels such as `changes`, or nested path segments.
- Prefer a maximum length of 60 characters. Allow a longer name only when a required work-item identifier makes it unavoidable.

Use only the prefixes the repository needs:

| Prefix | Purpose | Example |
| --- | --- | --- |
| `feature/` | New product behavior | `feature/proj-142-add-sso-login` |
| `fix/` | Non-emergency defect correction | `fix/proj-207-handle-empty-cart` |
| `docs/` | Documentation-only change | `docs/proj-221-update-api-usage` |
| `refactor/` | Internal restructuring without intended behavior change | `refactor/proj-233-split-token-parser` |
| `test/` | Test-only change | `test/proj-241-cover-session-expiry` |
| `chore/` | Maintenance, tooling, or dependency work | `chore/proj-255-upgrade-linter` |
| `experiment/` | Time-boxed work that cannot merge without conversion to an accepted type | `experiment/proj-260-test-cache-layout` |

Reserve these names for topology-specific flows:

| Pattern | Purpose | Example |
| --- | --- | --- |
| `release/<version>` | Stabilize one planned release | `release/2.4.0` |
| `hotfix/<work-item>-<description>` | Correct an urgent production defect | `hotfix/proj-271-fix-token-leak` |
| `support/<major>.<minor>` | Maintain a supported release line | `support/2.3` |

Choose one repository-wide release version format and apply it consistently. Do not mix `release/2.4`, `release/v2.4.0`, and date-based names without an explicit reason.

## Feature-Branch Workflow

Use `main` as the single long-lived branch.

| Branch | Create from | Merge into | Lifetime |
| --- | --- | --- | --- |
| `main` | Not applicable | Not applicable | Permanent |
| Ordinary work branch | Latest `main` | `main` | Hours to a few days |

Apply these rules:

1. Update local `main` and create a work branch from it.
2. Rebase or merge the latest `main` into the work branch according to repository policy. Never force-update another contributor's branch without coordination.
3. Open a pull or merge request early enough for review and CI feedback.
4. Merge only after protection requirements pass.
5. Delete the source branch after merge.
6. Release from a reviewed commit on `main` and attach an immutable version tag.

Prefer this model for continuous integration and continuous delivery. Do not add `develop` merely to collect completed features; use incomplete-feature controls when code must merge before exposure.

## Release-Assisted Workflow

Use `main` for current development and add release or support branches only for stabilization or maintained versions.

| Branch | Create from | Merge into | Lifetime |
| --- | --- | --- | --- |
| `main` | Not applicable | Not applicable | Permanent |
| Ordinary work branch | Latest `main` | `main` | Hours to a few days |
| `release/<version>` | Selected commit on `main` | Release tag; reconcile accepted fixes to `main` | Until release stabilization ends |
| `support/<major>.<minor>` | Released tag or release commit | Same support branch; forward-port fixes to newer active lines | While that version is supported |

Apply these rules:

- Freeze the release branch to stabilization work: defect fixes, version metadata, documentation, and release configuration. Reject new features.
- Create each stabilization fix from the affected release or support branch and merge it back through a pull or merge request.
- Create the release tag from the release branch after all release gates pass.
- Delete a temporary release branch after release and reconciliation unless the branch becomes a declared support line.
- Make a shared defect fix first in the oldest supported line that requires it, then forward-port it in order to each newer supported line and `main`.
- Track every forward-port with linked pull or merge requests. Resolve conflicts explicitly and rerun checks on every target.
- Never merge an older support branch wholesale into a newer line when that would also import version-specific or obsolete changes.

Use immutable artifacts for deployment promotion. If environment branches are unavoidable, order them from least to most restricted, allow changes only by controlled promotion, protect every branch, and prohibit direct feature work on them.

## Git Flow

Use `main` for released production history and `develop` for integration of the next release.

| Branch | Create from | Merge into | Lifetime |
| --- | --- | --- | --- |
| `main` | Not applicable | Not applicable | Permanent |
| `develop` | Initial production baseline | Not applicable | Permanent |
| `feature/*`, `fix/*`, and other ordinary work | Latest `develop` | `develop` | Hours to a few days |
| `release/<version>` | `develop` | `main` and back to `develop` | Until that release ships |
| `hotfix/*` | Released commit on `main` | `main`, `develop`, and every affected active release line | Until the emergency release ships |

Apply these rules:

1. Protect both `main` and `develop` and require pull or merge requests for both.
2. Allow only release and hotfix integration into `main`.
3. Stop feature development on a release branch. Accept only stabilization, documentation, and release metadata changes.
4. Tag the release commit on `main` after the release branch passes all gates.
5. Reconcile the exact release result back into `develop`; do not rely on contributors to recreate fixes manually.
6. Branch a hotfix for the current production line from `main`. Branch a fix for an older maintained version from its `support/*` branch, not from `develop` or an arbitrary historical tag.
7. Tag the corrected release on `main`, then propagate the hotfix to `develop` and every affected active release or support branch.
8. Delete completed feature, release, and hotfix branches after all required integrations finish.

Select Git Flow only when its parallel histories solve an actual release-management need. Account for its extra merge coordination, duplicated protection rules, and reconciliation risk.

## Pull Or Merge Request Controls

Require the following on protected integration and release branches:

- A linked work item or a clear problem statement and scope.
- Passing required build, test, lint, security, and policy checks relevant to the change.
- Approval from at least one qualified reviewer; require code-owner or additional approval for sensitive paths.
- Resolution of blocking discussions and review findings.
- An up-to-date branch or successful merge-queue validation before merge.
- A non-draft state and no unresolved merge conflicts.

Define one default merge strategy:

- Use squash merge when each request represents one logical change and intermediate commits have little long-term value.
- Use merge commits when preserving branch boundaries or coordinated release merges is important.
- Use rebase merge only when contributors maintain reviewable commits and a linear history is required.

Do not combine strategies arbitrarily. Document exceptions, especially for release and hotfix reconciliation merges.

## Fork-Based Contributions

Use forks when contributors should not receive write access to the upstream repository. Keep the upstream repository's selected feature-branch, release-assisted, or Git Flow topology unchanged.

- Create the contribution branch from the current upstream source branch in the contributor's fork.
- Target the same upstream branch that an equivalent in-repository work branch would target.
- Apply the upstream naming rules where the hosting platform exposes the source branch name.
- Run untrusted fork pipelines with restricted tokens and no protected secrets. Require an authorized maintainer to approve any privileged pipeline stage.
- Allow maintainers to update a contributor branch only when the contributor explicitly permits it and the hosting platform supports it.
- Require the same review, validation, merge, and deletion expectations as in-repository contributions.
- Delete the fork branch after integration; keep the fork itself only at the contributor's discretion.

## Protection Baseline

Protect every long-lived, release, support, and environment branch. Configure the hosting platform to:

- Require pull or merge requests and required status checks.
- Block force pushes and branch deletion.
- Restrict who may bypass protections or push during an approved incident.
- Dismiss or refresh approvals after material changes when supported.
- Require successful merge-queue or latest-target validation when concurrent merges are common.
- Apply rules to administrators when the governance model requires uniform enforcement.
- Protect release tags from deletion or retargeting.

Treat bypass access as incident-level privilege. Record the actor, reason, approval, affected commits, and follow-up review whenever it is used.

## Lifecycle And Hygiene

- Close or refresh stale requests rather than allowing branches to drift indefinitely.
- Recreate abandoned work from the current source branch when conflict resolution would be riskier than reapplying the focused change.
- Use feature flags, configuration, or incremental delivery to keep work branches short-lived.
- Record branch owners for release, support, and exceptional long-lived branches.
- Review active long-lived branches and protection rules on a regular schedule.
- Remove branch protections only as part of the documented retirement process, then delete the retired remote branch after confirming that tags and supported history remain reachable.

## Exceptions

Require every exception to state:

- The rule being bypassed.
- The operational reason and affected scope.
- The approving owner.
- The start time and expiration time.
- The validation or review that will occur afterward.
- The reconciliation and cleanup steps.

Never allow an exception to become an undocumented permanent branch type.

## Anti-Patterns

Reject these practices unless a documented external constraint requires them:

- Direct feature development on `main`, `develop`, release, support, or environment branches.
- Permanent personal or team branches.
- Long-lived feature branches used as integration environments.
- A `develop` branch that merely mirrors `main`.
- Moving tags or rebuilding different artifacts for later environments.
- Merging a production hotfix only to `main` and omitting active development or support lines.
- Branch names that encode secrets, customer data, or other sensitive information.
- Keeping merged branches indefinitely for historical purposes; Git commits and requests already preserve history.
