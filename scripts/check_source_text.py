#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parents[1]
CHECKED_SUFFIXES = {
    ".dart",
    ".json",
    ".md",
    ".yaml",
    ".yml",
}
SKIPPED_PARTS = {
    ".dart_tool",
    ".git",
    "build",
}
FORBIDDEN_TEXT = {
    "\u00c2": "likely mojibake marker",
    "\ufffd": "unicode replacement character",
}


def should_check(path: pathlib.Path) -> bool:
    return path.suffix in CHECKED_SUFFIXES and not any(
        part in SKIPPED_PARTS for part in path.parts
    )


def check_source_text(root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or not should_check(path):
            continue

        relative_path = path.relative_to(root).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as error:
            failures.append(f"{relative_path}: invalid utf-8 text: {error}.")
            continue

        for line_number, line in enumerate(text.splitlines(), start=1):
            for marker, label in FORBIDDEN_TEXT.items():
                if marker in line:
                    failures.append(
                        f"{relative_path}:{line_number}: contains {label}."
                    )

    return failures


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    root = pathlib.Path(args[0]).resolve() if args else DEFAULT_ROOT
    failures = check_source_text(root)

    if failures:
        print("Source text check failed:")
        for failure in failures:
            print(f" - {failure}")
        return 1

    print("Source text check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
