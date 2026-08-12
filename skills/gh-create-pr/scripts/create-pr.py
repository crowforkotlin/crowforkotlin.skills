#!/usr/bin/env python3
"""Push a clean Git branch, create a GitHub PR, and verify its metadata."""

from __future__ import annotations

import argparse
import json
import shlex
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


def output(repo: Path, *args: str) -> str:
    return git(repo, *args).stdout.strip()


def print_error(message: str) -> int:
    print(json.dumps({"error": message}, indent=2), file=sys.stderr)
    return 2


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=".", help="Path to the Git repository (default: current directory)")
    parser.add_argument("--repo-slug", help="Target GitHub repository as OWNER/REPO")
    parser.add_argument("--base", required=True, help="Target base branch")
    parser.add_argument("--base-ref", help="Local ref for base comparison (default: origin/BASE, then BASE)")
    parser.add_argument("--remote", default="origin", help="Git remote used by --push (default: origin)")
    parser.add_argument("--head", help="PR head branch or OWNER:branch (default: current branch)")
    parser.add_argument("--title", required=True, help="PR title")
    parser.add_argument("--body", required=True, help="Complete Markdown PR body; stdin is not accepted")
    parser.add_argument("--draft", action="store_true", help="Create a draft PR")
    parser.add_argument("--push", action="store_true", help="Push the current branch without force before creating the PR")
    parser.add_argument("--dry-run", action="store_true", help="Validate local state and print planned commands without network writes")
    args = parser.parse_args()

    if not args.title.strip():
        return print_error("PR title must not be blank.")
    if not args.body.strip():
        return print_error("PR body must not be blank.")

    repo = Path(args.repo).expanduser().resolve()
    try:
        root = Path(output(repo, "rev-parse", "--show-toplevel"))
        branch_result = git(root, "symbolic-ref", "--quiet", "--short", "HEAD", check=False)
        if branch_result.returncode != 0:
            return print_error("Cannot create a PR from detached HEAD.")
        branch = branch_result.stdout.strip()
        if branch == args.base:
            return print_error(f"Current branch '{branch}' is the base branch.")

        status = output(root, "status", "--porcelain=v1", "--untracked-files=all")
        if status:
            return print_error("Working tree is not clean; commit or remove local changes before creating the PR.")

        base_ref = args.base_ref
        if base_ref and git(root, "rev-parse", "--verify", "--quiet", base_ref, check=False).returncode != 0:
            return print_error(f"Cannot resolve local base ref '{base_ref}'.")
        for candidate in (() if base_ref else (f"origin/{args.base}", args.base)):
            if git(root, "rev-parse", "--verify", "--quiet", candidate, check=False).returncode == 0:
                base_ref = candidate
                break
        if base_ref is None:
            return print_error(f"Cannot resolve base branch '{args.base}' locally.")
        ahead = int(output(root, "rev-list", "--count", f"{base_ref}..HEAD"))
        if ahead == 0:
            return print_error(f"Current branch has no commits ahead of '{base_ref}'.")

        head = args.head or branch
        repo_slug = args.repo_slug
        if not repo_slug and not args.dry_run:
            if not shutil.which("gh"):
                return print_error("GitHub CLI 'gh' is required.")
            repo_slug = json.loads(gh(root, "repo", "view", "--json", "nameWithOwner").stdout)["nameWithOwner"]
        if not repo_slug:
            return print_error("--repo-slug is required for dry-run when repository discovery is unavailable.")

        head_branch = head.split(":", 1)[-1]
        head_owner = head.split(":", 1)[0] if ":" in head else None
        if args.push and head_branch != branch:
            return print_error(
                f"--push would publish local branch '{branch}', but PR head is '{head_branch}'."
            )
        if args.push and git(root, "remote", "get-url", args.remote, check=False).returncode != 0:
            return print_error(f"Push remote '{args.remote}' does not exist.")

        push_command = ["git", "push", "--set-upstream", args.remote, branch]
        create_command = [
            "gh",
            "pr",
            "create",
            "--repo",
            repo_slug,
            "--base",
            args.base,
            "--head",
            head,
            "--title",
            args.title,
            "--body",
            args.body,
        ]
        if args.draft:
            create_command.append("--draft")

        if args.dry_run:
            print(
                json.dumps(
                    {
                        "dry_run": True,
                        "repository_root": str(root),
                        "base": args.base,
                        "head": head,
                        "commits_ahead": ahead,
                        "push": shlex.join(push_command) if args.push else None,
                        "create": shlex.join(create_command),
                    },
                    indent=2,
                )
            )
            return 0

        if not shutil.which("gh"):
            return print_error("GitHub CLI 'gh' is required.")
        if gh(root, "auth", "status", check=False).returncode != 0:
            return print_error("GitHub CLI is not authenticated; run 'gh auth login'.")

        current_repo_slug = json.loads(gh(root, "repo", "view", "--json", "nameWithOwner").stdout)["nameWithOwner"]
        if ":" not in head and current_repo_slug != repo_slug:
            return print_error(
                "Cross-repository PRs require --head OWNER:BRANCH so the source repository is explicit."
            )

        expected_owner = head_owner or repo_slug.split("/", 1)[0]
        existing_result = gh(
            root,
            "pr",
            "list",
            "--repo",
            repo_slug,
            "--head",
            head_branch,
            "--base",
            args.base,
            "--state",
            "open",
            "--json",
            "number,title,url,baseRefName,headRefName,headRepositoryOwner",
        )
        existing = json.loads(existing_result.stdout)
        existing = [
            pr for pr in existing
            if (pr.get("headRepositoryOwner") or {}).get("login") == expected_owner
        ]
        if existing:
            return print_error(f"An open PR already exists for this head: {existing[0]['url']}")

        if args.push:
            run(root, *push_command)

        created = run(root, *create_command).stdout.strip().splitlines()
        if not created:
            return print_error("GitHub CLI did not return a PR URL.")
        url = created[-1].strip()
        view = gh(
            root,
            "pr",
            "view",
            url,
            "--json",
            "number,title,body,state,isDraft,url,baseRefName,headRefName,headRepositoryOwner,commits,statusCheckRollup",
        )
        pr = json.loads(view.stdout)
        expected_head = head_branch
        mismatches = []
        if pr.get("title") != args.title:
            mismatches.append("title")
        if pr.get("body") != args.body:
            mismatches.append("body")
        if pr.get("baseRefName") != args.base:
            mismatches.append("base")
        if pr.get("headRefName") != expected_head:
            mismatches.append("head")
        if (pr.get("headRepositoryOwner") or {}).get("login") != expected_owner:
            mismatches.append("head owner")
        if bool(pr.get("isDraft")) != args.draft:
            mismatches.append("draft")
        if mismatches:
            return print_error(f"Created PR metadata verification failed: {', '.join(mismatches)}. URL: {url}")

        print(json.dumps(pr, indent=2))
        return 0
    except (OSError, RuntimeError, ValueError, KeyError, json.JSONDecodeError) as error:
        return print_error(str(error))


if __name__ == "__main__":
    raise SystemExit(main())
