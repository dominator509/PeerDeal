#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
ILLEGAL_SRC_IMPORT = re.compile(r"package:[^\s'\"]+/src/")
FORBIDDEN_IMPORT_PATTERNS = [
    # Core must not import apps or platform/native packages.
    ('packages/peerdeal_core/lib', [
        'package:peerdeal_native_bridges/',
        'package:flutter/',
    ]),
]

def iter_dart_files(base: pathlib.Path):
    if not base.exists():
        return []
    return [p for p in base.rglob('*.dart') if p.is_file()]

def main() -> int:
    failures: list[str] = []

    for dart_file in iter_dart_files(ROOT):
        text = dart_file.read_text(encoding='utf-8')
        if ILLEGAL_SRC_IMPORT.search(text):
            failures.append(f'{dart_file}: imports another package\'s src/ directly.')

    for rel_dir, forbidden_patterns in FORBIDDEN_IMPORT_PATTERNS:
        base = ROOT / rel_dir
        for dart_file in iter_dart_files(base):
            text = dart_file.read_text(encoding='utf-8')
            for pattern in forbidden_patterns:
                if pattern in text:
                    failures.append(f'{dart_file}: forbidden import pattern {pattern}')

    if failures:
        print('Boundary check failed:')
        for failure in failures:
            print(f' - {failure}')
        return 1

    print('Boundary check passed.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
