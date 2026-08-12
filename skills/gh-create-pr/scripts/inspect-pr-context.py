#!/usr/bin/env python3
"""Inspect Git and GitHub state needed to draft or create a pull request."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def run(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        args,
        cwd=repo,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or f"exit code {result.returncode}"
        raise RuntimeError(f"Command failed: {' '.join(args)}\n{detail}")
    return result


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(repo, "git", *args, check=check)


def gh(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return run(repo, "gh", *args, check=check)


def git_output(repo: Path, *args: str) -> str:
    return git(repo, *args).stdout.strip()


def resolve_default_branch(repo: Path) -> tuple[str | None, str]:
    if shutil.which("gh"):
        result = gh(repo, "repo", "view", "--json", "defaultBranchRef", check=False)
        if result.returncode == 0:
            value = json.loads(result.stdout).get("defaultBranchRef") or {}
            name = value.get("name")
            if name:
                return name, "github"

    symbolic = git(repo, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD", check=False)
    if symbolic.returncode == 0 and "/" in symbolic.stdout.strip():
        return symbolic.stdout.strip().split("/", 1)[1], "origin-head"

    for candidate in ("main", "master"):
        if git(repo, "rev-parse", "--verify", "--quiet", candidate, check=False).returncode == 0:
            return candidate, "local-fallback"
    return None, "unresolved"


def resolve_base_ref(repo: Path, base: str) -> str | None:
    for candidate in (f"origin/{base}", base):
        if git(repo, "rev-parse", "--verify", "--quiet", candidate, check=False).returncode == 0:
            return candidate
    return None


def parse_json(value: str, fallback: object) -> object:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return fallback


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="Path to the Git repository (default: current directory)")
    parser.add_argument("--base", help="Target base branch (default: GitHub repository default)")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    try:
        root = Path(git_output(repo, "rev-parse", "--show-toplevel"))
    except (OSError, RuntimeError) as error:
        print(json.dumps({"error": str(error)}, indent=2), file=sys.stderr)
        return 2

    branch_result = git(root, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
    branch = branch_result.stdout.strip() if branch_result.returncode == 0 else None
    default_branch, default_source = resolve_default_branch(root)
    base = args.base or default_branch
    base_ref = resolve_base_ref(root, base) if base else None
    status_lines = [line for line in git_output(root, "status", "--porcelain=v1", "--untracked-files=all").splitlines() if line]

    remotes = []
    for line in git_output(root, "remote", "-v").splitlines():
        fields = line.split()
        if len(fields) >= 3:
            remotes.append({"name": fields[0], "url": fields[1], "operation": fields[2].strip("()")})

    upstream_result = git(root, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}", check=False)
    upstream = upstream_result.stdout.strip() if upstream_result.returncode == 0 else None
    head_sha = git_output(root, "rev-parse", "HEAD")

    diff = {
        "base_ref": base_ref,
        "merge_base": None,
        "ahead": None,
        "behind": None,
        "stat": None,
        "name_status": [],
        "commits": [],
    }
    if base_ref:
        merge_base = git_output(root, "merge-base", base_ref, "HEAD")
        counts = git_output(root, "rev-list", "--left-right", "--count", f"{base_ref}...HEAD").split()
        name_status = git_output(root, "diff", "--name-status", f"{base_ref}...HEAD")
        commits_raw = git_output(
            root,
            "log",
            "--format=%H%x1f%s%x1f%an%x1e",
            f"{base_ref}..HEAD",
        )
        commits = []
        for record in commits_raw.strip("\x1e\n").split("\x1e") if commits_raw else []:
            fields = record.strip().split("\x1f")
            if len(fields) == 3:
                commits.append(dict(zip(("sha", "subject", "author_name"), fields)))
        diff.update(
            merge_base=merge_base,
            behind=int(counts[0]),
            ahead=int(counts[1]),
            stat=git_output(root, "diff", "--stat", f"{base_ref}...HEAD"),
            name_status=name_status.splitlines() if name_status else [],
            commits=commits,
        )

    github = {
        "gh_installed": shutil.which("gh") is not None,
        "authenticated": False,
        "repository": None,
        "default_branch": default_branch,
        "default_branch_source": default_source,
        "existing_prs": [],
    }
    if github["gh_installed"]:
        github["authenticated"] = gh(root, "auth", "status", check=False).returncode == 0
        repo_result = gh(root, "repo", "view", "--json", "nameWithOwner,url", check=False)
        if repo_result.returncode == 0:
            github["repository"] = parse_json(repo_result.stdout, None)
        if branch:
            pr_result = gh(
                root,
                "pr",
                "list",
                "--head",
                branch,
                "--state",
                "all",
                "--json",
                "number,title,state,isDraft,url,baseRefName,headRefName",
                check=False,
            )
            if pr_result.returncode == 0:
                github["existing_prs"] = parse_json(pr_result.stdout, [])

    payload = {
        "repository_root": str(root),
        "branch": branch,
        "detached_head": branch is None,
        "head_sha": head_sha,
        "base_branch": base,
        "worktree_clean": not status_lines,
        "status": status_lines,
        "upstream": upstream,
        "remotes": remotes,
        "diff": diff,
        "github": github,
    }
    print(json.dumps(payload, indent=2, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
