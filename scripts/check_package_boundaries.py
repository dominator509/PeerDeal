#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import re
import sys

DEFAULT_ROOT = pathlib.Path(__file__).resolve().parents[1]
PACKAGE_IMPORT = re.compile(r"(?:import|export)\s+['\"]package:([^/'\"]+)(/[^'\"]*)?['\"]")
PEERDEAL_PACKAGE = re.compile(r"peerdeal_[a-z_]+")
ILLEGAL_SRC_IMPORT = re.compile(r"package:[^\s'\"]+/src/")
ALLOWED_PACKAGE_IMPORTS = {
    "peerdeal_core": {"peerdeal_protocol"},
    "peerdeal_variants": {"peerdeal_protocol", "peerdeal_core"},
    "peerdeal_modes": {"peerdeal_protocol", "peerdeal_core"},
}
FORBIDDEN_IMPORT_PATTERNS = [
    # Core must not import apps or platform/native packages.
    ('packages/peerdeal_core/lib', [
        'package:peerdeal_native_bridges/',
        'package:flutter/',
    ]),
]
APP_PACKAGE_NAMES = {"peerdeal_desktop", "peerdeal_mobile"}


def normalize_path(path: pathlib.Path) -> str:
    return path.as_posix()


def iter_dart_files(base: pathlib.Path):
    if not base.exists():
        return []
    return [p for p in base.rglob('*.dart') if p.is_file()]


def find_package_roots(root: pathlib.Path) -> dict[str, pathlib.Path]:
    packages: dict[str, pathlib.Path] = {}
    for package_parent in [root / "apps", root / "packages"]:
        if not package_parent.exists():
            continue
        for pubspec in package_parent.glob("*/pubspec.yaml"):
            text = pubspec.read_text(encoding="utf-8")
            match = re.search(r"^name:\s*([a-zA-Z0-9_]+)\s*$", text, re.MULTILINE)
            if match:
                packages[match.group(1)] = pubspec.parent
    return packages


def package_for_path(path: pathlib.Path, packages: dict[str, pathlib.Path]) -> str | None:
    for package_name, package_root in packages.items():
        try:
            path.relative_to(package_root)
        except ValueError:
            continue
        return package_name
    return None


def declared_peerdeal_dependencies(package_root: pathlib.Path) -> set[str]:
    pubspec = package_root / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    return set(PEERDEAL_PACKAGE.findall(text))


def workspace_package_paths(root: pathlib.Path) -> set[str]:
    pubspec = root / "pubspec.yaml"
    if not pubspec.exists():
        return set()

    paths: set[str] = set()
    in_workspace = False
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if re.match(r"^workspace:\s*$", line):
            in_workspace = True
            continue
        if in_workspace and line and not line.startswith(" "):
            break
        if in_workspace:
            match = re.match(r"^\s+-\s+(.+?)\s*$", line)
            if match:
                paths.add(match.group(1).replace("\\", "/"))
    return paths


def package_map_paths(root: pathlib.Path) -> set[str]:
    package_map = root / "docs" / "PACKAGE_MAP.md"
    if not package_map.exists():
        return set()

    paths: set[str] = set()
    current_parent: str | None = None
    for line in package_map.read_text(encoding="utf-8").splitlines():
        parent_match = re.match(r"^/(apps|packages)\s*$", line)
        if parent_match:
            current_parent = parent_match.group(1)
            continue
        if line.startswith("##"):
            current_parent = None
            continue
        child_match = re.match(r"^\s{2}(peerdeal_[a-z_]+)\s*$", line)
        if current_parent and child_match:
            paths.add(f"{current_parent}/{child_match.group(1)}")
    return paths


def actual_package_paths(root: pathlib.Path) -> set[str]:
    return {
        normalize_path(path.relative_to(root))
        for package_root in find_package_roots(root).values()
        for path in [package_root]
    }


def compare_path_sets(label: str, expected: set[str], actual: set[str]) -> list[str]:
    failures: list[str] = []
    for missing in sorted(expected - actual):
        failures.append(f"{label}: missing {missing}.")
    for extra in sorted(actual - expected):
        failures.append(f"{label}: unexpected {extra}.")
    return failures


def package_documentation_failures(package_roots: dict[str, pathlib.Path]) -> list[str]:
    failures: list[str] = []
    for package_name, package_root in sorted(package_roots.items()):
        for required_file in ["AGENTS.md", "README.md"]:
            if not (package_root / required_file).exists():
                failures.append(f"{package_name}: missing package-local {required_file}.")
    return failures


def check_boundaries(root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    package_roots = find_package_roots(root)
    declared_dependencies = {
        package_name: declared_peerdeal_dependencies(package_root)
        for package_name, package_root in package_roots.items()
    }
    actual_paths = actual_package_paths(root)
    workspace_paths = workspace_package_paths(root)
    map_paths = package_map_paths(root)

    failures.extend(compare_path_sets("workspace package list", actual_paths, workspace_paths))
    failures.extend(compare_path_sets("docs/PACKAGE_MAP.md", actual_paths, map_paths))
    failures.extend(package_documentation_failures(package_roots))

    for dart_file in iter_dart_files(root):
        text = dart_file.read_text(encoding='utf-8')
        if ILLEGAL_SRC_IMPORT.search(text):
            failures.append(f'{dart_file}: imports another package\'s src/ directly.')

        current_package = package_for_path(dart_file, package_roots)
        if current_package is None:
            continue

        for imported_package, imported_path in PACKAGE_IMPORT.findall(text):
            if not imported_package.startswith("peerdeal_"):
                continue
            if imported_package == current_package:
                continue

            if imported_package not in package_roots:
                failures.append(f'{dart_file}: imports unknown PeerDeal package {imported_package}.')
                continue

            if current_package not in APP_PACKAGE_NAMES and imported_package in APP_PACKAGE_NAMES:
                failures.append(
                    f'{dart_file}: reusable packages may not import app package {imported_package}.'
                )

            if imported_package not in declared_dependencies[current_package]:
                failures.append(
                    f'{dart_file}: imports {imported_package} without declaring it in pubspec.yaml.'
                )

            allowed_imports = ALLOWED_PACKAGE_IMPORTS.get(current_package)
            if allowed_imports is not None and imported_package not in allowed_imports:
                failures.append(
                    f'{dart_file}: {current_package} may not import {imported_package} per package map.'
                )

    for rel_dir, forbidden_patterns in FORBIDDEN_IMPORT_PATTERNS:
        base = root / rel_dir
        for dart_file in iter_dart_files(base):
            text = dart_file.read_text(encoding='utf-8')
            for pattern in forbidden_patterns:
                if pattern in text:
                    failures.append(f'{dart_file}: forbidden import pattern {pattern}')

    return failures


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    root = pathlib.Path(args[0]).resolve() if args else DEFAULT_ROOT
    failures = check_boundaries(root)

    if failures:
        print('Boundary check failed:')
        for failure in failures:
            print(f' - {failure}')
        return 1

    print('Boundary check passed.')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
