---
name: git-branch-governance
description: Design, audit, and document Git branch conventions covering workflow selection, branch roles and naming, merge targets, releases, hotfixes, protection rules, cleanup, and exceptions. Use when creating or reviewing repository branching policies, CONTRIBUTING guidance, branch protection settings, release workflows, or when deciding between feature branches, release branches, trunk-oriented workflows, and Git Flow.
---

# Git Branch Governance

Create a branching policy that is explicit enough to follow and enforce. Prefer the least complex topology that satisfies the repository's release and support requirements.

## Workflow

1. Inspect the repository before proposing a policy.
   - Read existing contribution, release, deployment, and ownership documentation.
   - Inspect the default branch, active long-lived branches, tags, CI rules, and repository-host settings when available.
   - Preserve explicit project conventions unless the user asks to replace or migrate them.
2. Establish the operating constraints.
   - Determine release cadence, deployment frequency, number of maintained versions, validation environments, team size, compliance needs, and whether urgent production fixes require a separate path.
   - State assumptions when repository evidence does not answer a material question.
3. Select one topology from the decision table below. Do not introduce `develop`, release branches, or environment branches by habit.
4. Read [branch-rules.md](references/branch-rules.md) before drafting or reviewing a policy. Apply every invariant and only the topology-specific rules for the selected model.
5. Define a complete contract for every allowed branch type: purpose, source, merge target, owner, lifetime, protection level, and deletion rule.
6. Map the contract to enforceable controls: pull or merge request requirements, status checks, approvals, merge strategy, branch protection, tag protection, and cleanup automation.
7. Validate the result with the review checklist. Resolve contradictions rather than listing incompatible alternatives.
8. Use [policy-template.md](references/policy-template.md) when the user requests a ready-to-adopt policy document. Replace every placeholder and remove every inapplicable section.

## Topology Decision

| Topology | Select when | Branch shape |
| --- | --- | --- |
| Feature-branch workflow | The team integrates frequently, maintains one current line, and releases from the default branch | Protected `main` plus short-lived work branches; keep branches very short-lived for trunk-oriented delivery |
| Release-assisted workflow | The team stabilizes scheduled releases or maintains multiple supported versions | Protected `main`, short-lived work branches, and temporary `release/*` or maintained `support/*` branches |
| Git Flow | The product has distinct integration and production histories, scheduled releases, and an explicit need for parallel release and hotfix coordination | Protected `main` and `develop`, with `feature/*`, `release/*`, and `hotfix/*` branches |

Default to the feature-branch workflow when the evidence does not require additional long-lived branches. Treat repository hosting products as enforcement surfaces, not as reasons to choose a topology.

Treat a fork-based workflow as an access and contribution overlay, not a separate release topology. Let external or untrusted contributors create work branches in personal forks and open pull or merge requests to the selected upstream target; apply the same naming, validation, review, and lifecycle rules after the request enters the upstream repository.

## Policy Quality Rules

- Use normative terms consistently: `MUST`, `MUST NOT`, `SHOULD`, `SHOULD NOT`, and `MAY`.
- Distinguish mandatory repository controls from recommendations and examples.
- Name exact source and target branches. Avoid vague instructions such as "merge upstream" or "merge to the release branch."
- Specify how release and hotfix changes return to every affected active line; never leave reconciliation implicit.
- Prefer immutable artifacts promoted through environments over branches named after environments. Document an environment-branch exception only when the deployment system requires it.
- Keep branch names independent of individual users and temporary team structures.
- Do not claim that a hosting control exists unless it was observed or the response clearly labels it as a proposed setting.
- Keep the policy platform-neutral unless the user requests GitHub- or GitLab-specific configuration.

## Review Checklist

Confirm all of the following before delivering the result:

- Exactly one default integration path is clear for ordinary work.
- Each branch type has one unambiguous source, target, and lifecycle.
- Production releases resolve to an immutable tag or commit.
- Protected branches reject direct pushes, force pushes, and accidental deletion unless a documented exception applies.
- Required checks and reviews run before merge, including for administrators when governance requires it.
- Release fixes and production hotfixes propagate to all affected newer lines.
- Work branches remain short-lived and are deleted after integration.
- The chosen merge strategy matches the required history and is stated once.
- Naming examples conform to the declared naming grammar.
- The policy includes an exception owner and a time-bounded exception process.

## Output Expectations

For a design request, return the selected topology, concise rationale, branch contract, merge and protection rules, release and hotfix paths, and migration notes when existing practice differs.

For an audit, report concrete conflicts and missing controls first, then provide corrected language or settings. Reference repository evidence when available.

For an implementation request, edit only the requested repository documentation or configuration. Do not change remote branch protections, delete branches, rewrite history, or push changes unless the user explicitly authorizes those operations.
