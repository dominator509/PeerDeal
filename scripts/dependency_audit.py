"""Print a concise dependency audit without changing package state."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys


def version(package: dict, key: str) -> str | None:
    value = package.get(key, {})
    if not isinstance(value, dict):
        return None
    package_version = value.get("version")
    return package_version if isinstance(package_version, str) else None


def summarize_packages(packages: list[dict]) -> tuple[int, int, list[str]]:
    outdated = [
        package
        for package in packages
        if version(package, "current") != version(package, "latest")
    ]
    constrained = [
        package
        for package in packages
        if version(package, "resolvable") != version(package, "latest")
    ]
    direct_rows = [
        package for package in packages if package.get("kind") in {"direct", "dev"}
    ]
    direct_summaries = [
        (
            f"- {package['package']}: current {version(package, 'current') or '-'}, "
            f"resolvable {version(package, 'resolvable') or '-'}, "
            f"latest {version(package, 'latest') or '-'}"
        )
        for package in direct_rows
    ]
    return len(outdated), len(constrained), direct_summaries


def print_summary(payload: dict, advisory_warning: bool) -> None:
    packages = payload.get("packages", [])
    if not isinstance(packages, list):
        packages = []

    outdated_count, constrained_count, direct_summaries = summarize_packages(packages)

    print("Dependency audit completed.")
    print(f"Outdated packages reported: {outdated_count}")
    print(f"Packages constrained below latest: {constrained_count}")

    if direct_summaries:
        print("")
        print("Direct and dev dependency status:")
        for summary in direct_summaries:
            print(summary)

    if advisory_warning:
        print("")
        print("Pub emitted advisory metadata warnings; version data was still parsed.")


def main() -> int:
    if shutil.which("flutter") is None:
        print("Flutter is not available on PATH; cannot run dependency audit.")
        return 1

    result = subprocess.run(
        "flutter pub outdated --json",
        cwd=".",
        capture_output=True,
        shell=True,
        text=True,
    )

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        return result.returncode or 1

    print_summary(payload, advisory_warning=bool(result.stderr))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
