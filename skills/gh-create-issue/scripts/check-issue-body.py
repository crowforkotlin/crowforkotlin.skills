#!/usr/bin/env python3
"""Check a GitHub issue body and title against the gh-create-issue rules.

Usage:
    python3 check-issue-body.py --body issue.md --title 'fix(loader): bound the cache'
    python3 check-issue-body.py --body issue.md            # body checks only

Exits 0 when every check passes, 1 when any check fails, 2 on bad arguments.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_HEADINGS = ["## Impact", "## Location", "## Reproduction", "## Expected"]
OPTIONAL_HEADINGS = ["## Scope", "## Notes"]
SEVERITY_LINE = re.compile(r"^Severity: (critical|high|medium|low)\b.*$", re.S)
TITLE_PATTERN = re.compile(r"^[a-z]+(?:\([a-z0-9][a-z0-9./-]*\))?: \S.*$")
PLACEHOLDERS = [
    "<cli>",
    "<repo>",
    "<path>",
    "<command>",
    "<owner>",
    "<number>",
    "<title>",
    "TODO",
    "TBD",
    "FIXME",
    "your-repo",
    "example.com",
]
BANNED_WORDS = [
    "simply",
    "obviously",
    "clearly",
    "seamless",
    "holistic",
    "leverage",
    "utilize",
    "robust",
    "various",
    "proper",
    "properly",
    "as needed",
    "etc.",
    "and so on",
    "it would be nice",
    "should work",
]
NON_ASCII = re.compile(r"[^\x00-\x7F]")
FENCE = re.compile(r"^```(?P<lang>[a-zA-Z0-9_+-]*)\s*$", re.M)


def read_body(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_severity(body: str, errors: list[str]) -> None:
    first = body.splitlines()[0] if body.splitlines() else ""
    if not SEVERITY_LINE.match(first):
        errors.append(
            "line 1 must be 'Severity: critical|high|medium|low' optionally "
            f"followed by a parenthesized reason; got: {first!r}"
        )


def check_headings(body: str, errors: list[str]) -> None:
    found = [line.strip() for line in body.splitlines() if line.startswith("## ")]
    missing = [heading for heading in REQUIRED_HEADINGS if heading not in found]
    if missing:
        errors.append("missing required heading(s): " + ", ".join(missing))
    unknown = [heading for heading in found if heading not in REQUIRED_HEADINGS + OPTIONAL_HEADINGS]
    if unknown:
        errors.append("unexpected heading(s): " + ", ".join(unknown))
    order = [heading for heading in found if heading in REQUIRED_HEADINGS]
    expected_order = [heading for heading in REQUIRED_HEADINGS if heading in order]
    if order != expected_order:
        errors.append("required headings are out of order: " + " -> ".join(order))


def check_sections(body: str, errors: list[str]) -> None:
    sections: dict[str, str] = {}
    current = ""
    for line in body.splitlines():
        if line.startswith("## "):
            current = line.strip()
            sections[current] = ""
        elif current:
            sections[current] += line + "\n"
    for heading, content in sections.items():
        if not content.strip():
            errors.append(f"section {heading} is empty")
    for heading in ["## Impact", "## Location", "## Expected"]:
        content = sections.get(heading, "")
        if content.strip() and len(content.split()) < 8:
            errors.append(f"section {heading} is too short to be checkable")


def check_commands(body: str, errors: list[str]) -> None:
    opening = True
    languages: list[str] = []
    for line in body.splitlines():
        if not line.startswith("```"):
            continue
        if opening:
            language = line[3:].strip()
            if not language:
                errors.append("fenced block without a language tag; use bash or text")
            languages.append(language)
        opening = not opening
    if opening is False:
        errors.append("a fenced block is never closed")
    if "bash" not in languages:
        errors.append("the body must contain at least one ```bash block")
    reproduction = body.split("## Reproduction", 1)
    if len(reproduction) == 2:
        section = reproduction[1].split("\n## ", 1)[0]
        if "```bash" not in section:
            errors.append("## Reproduction must contain a ```bash block")
        if "```text" not in section:
            errors.append("## Reproduction must contain a ```text block with the observed output")


def check_placeholders(body: str, errors: list[str]) -> None:
    for placeholder in PLACEHOLDERS:
        if placeholder in body:
            errors.append(f"placeholder text found: {placeholder}")


def check_ascii(body: str, errors: list[str]) -> None:
    for number, line in enumerate(body.splitlines(), start=1):
        match = NON_ASCII.search(line)
        if match:
            errors.append(f"non-English character {match.group()!r} on line {number}")
            return


def check_banned(body: str, errors: list[str]) -> None:
    lowered = body.lower()
    for word in BANNED_WORDS:
        pattern = r"\b" + re.escape(word) + r"\b" if word.isalpha() else re.escape(word)
        match = re.search(pattern, lowered)
        if match:
            errors.append(f"banned wording found: {match.group()!r}")


def check_title(title: str, errors: list[str]) -> None:
    if len(title) > 72:
        errors.append(f"title is {len(title)} characters; keep it at or below 72")
    if not TITLE_PATTERN.match(title):
        errors.append("title must look like 'fix(scope): summary' or 'docs: summary'")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--body", required=True, type=Path, help="path to the issue body file")
    parser.add_argument("--title", help="issue title to check")
    arguments = parser.parse_args(argv)

    if not arguments.body.is_file():
        print(f"error: body file not found: {arguments.body}", file=sys.stderr)
        return 2

    body = read_body(arguments.body)
    errors: list[str] = []
    check_severity(body, errors)
    check_headings(body, errors)
    check_sections(body, errors)
    check_commands(body, errors)
    check_placeholders(body, errors)
    check_ascii(body, errors)
    check_banned(body, errors)
    if arguments.title is not None:
        check_title(arguments.title, errors)

    if errors:
        print(f"{len(errors)} problem(s) in {arguments.body}:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(f"OK: {arguments.body}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
