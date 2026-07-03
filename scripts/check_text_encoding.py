from __future__ import annotations

import argparse
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UTF8_BOM = b"\xef\xbb\xbf"
TEXT_SUFFIXES = {
    ".arb",
    ".dart",
    ".gradle",
    ".json",
    ".md",
    ".properties",
    ".py",
    ".ps1",
    ".sh",
    ".txt",
    ".toml",
    ".xml",
    ".yaml",
    ".yml",
}
TEXT_FILENAMES = {
    ".editorconfig",
    ".gitattributes",
    ".gitignore",
    "AGENTS.md",
    "README.md",
    "analysis_options.yaml",
    "l10n.yaml",
    "pubspec.lock",
    "pubspec.yaml",
}
INVISIBLE_CHARS = {
    "\u00a0": "non-breaking space",
    "\u200b": "zero width space",
    "\u200c": "zero width non-joiner",
    "\u200d": "zero width joiner",
    "\u200e": "left-to-right mark",
    "\u200f": "right-to-left mark",
    "\u202a": "left-to-right embedding",
    "\u202b": "right-to-left embedding",
    "\u202c": "pop directional formatting",
    "\u202d": "left-to-right override",
    "\u202e": "right-to-left override",
    "\u2060": "word joiner",
    "\ufeff": "zero width no-break space / BOM character",
}


@dataclass(frozen=True)
class Finding:
    path: Path
    message: str


def configure_stdio() -> None:
    for stream_name in ("stdout", "stderr"):
        stream = getattr(sys, stream_name, None)
        if hasattr(stream, "reconfigure"):
            getattr(stream, "reconfigure")(encoding="utf-8", errors="replace")


def run_git(args: list[str]) -> list[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def resolve_repo_path(raw: str) -> Path:
    path_text = raw.strip()
    if " -> " in path_text:
        path_text = path_text.split(" -> ", 1)[1].strip()
    return (ROOT / path_text).resolve()


def is_text_candidate(path: Path) -> bool:
    name = path.name
    return path.suffix.lower() in TEXT_SUFFIXES or name in TEXT_FILENAMES


def git_status_files() -> list[Path]:
    result = subprocess.run(
        ["git", "status", "--porcelain=v1", "--untracked-files=all"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    files: list[Path] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        payload = line[3:]
        files.append(resolve_repo_path(payload))
    return files


def iter_target_files(args: argparse.Namespace) -> list[Path]:
    if args.all:
        candidates = [resolve_repo_path(line) for line in run_git(["ls-files"])]
    elif args.diff:
        base, head = args.diff
        candidates = [
            resolve_repo_path(line)
            for line in run_git(
                ["diff", "--name-only", "--diff-filter=ACMRTUXB", base, head]
            )
        ]
    elif args.staged:
        candidates = [
            resolve_repo_path(line)
            for line in run_git(
                ["diff", "--name-only", "--cached", "--diff-filter=ACMRTUXB"]
            )
        ]
    elif args.paths:
        candidates = [(ROOT / raw).resolve() for raw in args.paths]
    else:
        candidates = git_status_files()

    unique_files: dict[Path, None] = {}
    for path in candidates:
        if not path.exists() or not path.is_file():
            continue
        if not is_text_candidate(path):
            continue
        unique_files[path] = None
    return sorted(unique_files)


def check_file(path: Path) -> list[Finding]:
    findings: list[Finding] = []
    rel_path = path.relative_to(ROOT)
    data = path.read_bytes()

    if data.startswith(UTF8_BOM):
        findings.append(Finding(rel_path, "contains UTF-8 BOM"))

    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        findings.append(
            Finding(
                rel_path,
                f"is not valid UTF-8 (byte offset {exc.start})",
            )
        )
        return findings

    if "\r\n" in text or "\r" in text:
        findings.append(Finding(rel_path, "contains CRLF line endings"))

    if "\ufffd" in text:
        findings.append(Finding(rel_path, "contains U+FFFD replacement character"))

    for char, label in INVISIBLE_CHARS.items():
        if char in text:
            findings.append(Finding(rel_path, f"contains {label}"))

    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate UTF-8/LF hygiene for tracked or changed text files."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Optional explicit files to inspect.",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Inspect all tracked text files in the repository.",
    )
    parser.add_argument(
        "--diff",
        nargs=2,
        metavar=("BASE", "HEAD"),
        help="Inspect only files changed between two git revisions.",
    )
    parser.add_argument(
        "--staged",
        action="store_true",
        help="Inspect only staged files.",
    )
    return parser.parse_args()


def main() -> int:
    configure_stdio()
    args = parse_args()
    files = iter_target_files(args)

    if not files:
        print("No target text files to inspect.")
        return 0

    findings: list[Finding] = []
    for path in files:
        findings.extend(check_file(path))

    if not findings:
        print(f"Encoding check passed for {len(files)} file(s).")
        return 0

    print("Encoding check failed:\n")
    for finding in findings:
        print(f"{finding.path}: {finding.message}")

    print(
        "\nFix the listed files before continuing. "
        "If terminal output still looks wrong after this passes, "
        "the remaining issue is console encoding, not source-file encoding."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
