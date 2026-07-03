from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from pathlib import PurePosixPath


ROOT = Path(__file__).resolve().parents[1]
SCAN_ROOT = ROOT / "lib" / "features"

# 扫描展示层文件，避免把 l10n/generated/services/docs 一起扫进去造成大量误报
TARGET_GLOBS = [
    "**/presentation/**/*.dart",
]

STRING_PATTERNS = [
    re.compile(r"'([^'\\]|\\.)*[\u4e00-\u9fff]([^'\\]|\\.)*'"),
    re.compile(r'"([^"\\]|\\.)*[\u4e00-\u9fff]([^"\\]|\\.)*"'),
]


def configure_stdout() -> None:
    stdout = sys.stdout
    if hasattr(stdout, "reconfigure"):
        getattr(stdout, "reconfigure")(encoding="utf-8", errors="replace")


def strip_comments(source: str) -> str:
    result: list[str] = []
    i = 0
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    escaped = False

    while i < len(source):
        ch = source[i]
        nxt = source[i + 1] if i + 1 < len(source) else ""

        if in_line_comment:
            if ch == "\n":
                in_line_comment = False
                result.append(ch)
            i += 1
            continue

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                if ch == "\n":
                    result.append("\n")
                i += 1
            continue

        if not in_single and not in_double:
            if ch == "/" and nxt == "/":
                in_line_comment = True
                i += 2
                continue
            if ch == "/" and nxt == "*":
                in_block_comment = True
                i += 2
                continue

        result.append(ch)

        if escaped:
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double

        i += 1

    return "".join(result)


def find_matches(file_path: Path) -> list[tuple[int, str]]:
    raw = file_path.read_text(encoding="utf-8")
    text = strip_comments(raw)
    matches: list[tuple[int, str]] = []

    for line_no, line in enumerate(text.splitlines(), start=1):
        for pattern in STRING_PATTERNS:
            if pattern.search(line):
                matches.append((line_no, line.strip()))
                break

    return matches


def is_target_file(file_path: Path) -> bool:
    try:
        rel_path = file_path.relative_to(SCAN_ROOT)
    except ValueError:
        return False

    rel_posix = PurePosixPath(rel_path.as_posix())
    return any(rel_posix.match(pattern) for pattern in TARGET_GLOBS)


def git_diff_files(base: str, head: str) -> list[Path]:
    result = subprocess.run(
        [
            "git",
            "diff",
            "--name-only",
            "--diff-filter=ACMRTUXB",
            base,
            head,
        ],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    files: list[Path] = []
    for raw_line in result.stdout.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        files.append((ROOT / line).resolve())
    return files


def iter_target_files(explicit_files: list[Path] | None = None) -> list[Path]:
    if explicit_files is not None:
        files = {path.resolve() for path in explicit_files}
        return sorted(
            path for path in files if path.is_file() and is_target_file(path)
        )

    files: set[Path] = set()
    for pattern in TARGET_GLOBS:
        files.update(SCAN_ROOT.glob(pattern))
    return sorted(path for path in files if path.is_file())


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "paths",
        nargs="*",
        help="Optional explicit files to scan instead of scanning the full presentation layer.",
    )
    parser.add_argument(
        "--diff",
        nargs=2,
        metavar=("BASE", "HEAD"),
        help="Scan only files changed between two git revisions.",
    )
    return parser.parse_args()


def main() -> int:
    configure_stdout()
    args = parse_args()

    explicit_files: list[Path] | None = None
    if args.diff is not None:
        base, head = args.diff
        explicit_files = git_diff_files(base, head)
    elif args.paths:
        explicit_files = [(ROOT / path).resolve() for path in args.paths]

    findings: list[tuple[Path, int, str]] = []
    for file_path in iter_target_files(explicit_files):
        for line_no, snippet in find_matches(file_path):
            findings.append((file_path.relative_to(ROOT), line_no, snippet))

    if not findings:
        print("No hardcoded Chinese UI string literals found in presentation layer.")
        return 0

    print("Found hardcoded Chinese UI string literals:\n")
    for rel_path, line_no, snippet in findings:
        print(f"{rel_path}:{line_no}: {snippet}")

    print(
        "\nFailing because user-visible Chinese string literals remain in presentation code. "
        "Move them into ARB files and access via context.l10n."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
