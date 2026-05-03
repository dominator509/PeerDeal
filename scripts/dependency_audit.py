"""Print a concise dependency audit without changing package state."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys


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

    packages = payload.get("packages", [])
    outdated = [
        package
        for package in packages
        if package.get("current", {}).get("version")
        != package.get("latest", {}).get("version")
    ]
    constrained = [
        package
        for package in packages
        if package.get("resolvable", {}).get("version")
        != package.get("latest", {}).get("version")
    ]

    print("Dependency audit completed.")
    print(f"Outdated packages reported: {len(outdated)}")
    print(f"Packages constrained below latest: {len(constrained)}")

    direct_rows = [
        package for package in packages if package.get("kind") in {"direct", "dev"}
    ]
    if direct_rows:
        print("")
        print("Direct and dev dependency status:")
        for package in direct_rows:
            name = package["package"]
            current = package.get("current", {}).get("version", "-")
            resolvable = package.get("resolvable", {}).get("version", "-")
            latest = package.get("latest", {}).get("version", "-")
            print(f"- {name}: current {current}, resolvable {resolvable}, latest {latest}")

    if result.stderr:
        print("")
        print("Pub emitted advisory metadata warnings; version data was still parsed.")

    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
