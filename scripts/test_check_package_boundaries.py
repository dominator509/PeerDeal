#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import sys
import tempfile
import unittest

from check_package_boundaries import check_boundaries


def write_file(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_package(root: pathlib.Path, name: str, dependencies: list[str] | None = None) -> pathlib.Path:
    package_root = root / "packages" / name
    dependency_lines = "".join(f"  {dependency}:\n    path: ../{dependency}\n" for dependency in dependencies or [])
    write_file(
        package_root / "pubspec.yaml",
        f"name: {name}\n\n"
        "environment:\n"
        "  sdk: '^3.11.5'\n\n"
        "dependencies:\n"
        f"{dependency_lines}",
    )
    return package_root


class BoundaryCheckTest(unittest.TestCase):
    def test_allows_declared_package_map_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            core_root = write_package(root, "peerdeal_core", ["peerdeal_protocol"])
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_protocol/peerdeal_protocol.dart';\n",
            )

            self.assertEqual([], check_boundaries(root))

    def test_rejects_undeclared_peerdeal_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            core_root = write_package(root, "peerdeal_core")
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_protocol/peerdeal_protocol.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertEqual(1, len(failures))
            self.assertIn("without declaring it in pubspec.yaml", failures[0])

    def test_rejects_package_map_violation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            write_package(root, "peerdeal_network")
            core_root = write_package(root, "peerdeal_core", ["peerdeal_network"])
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_network/peerdeal_network.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertTrue(any("per package map" in failure for failure in failures))

    def test_rejects_src_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            core_root = write_package(root, "peerdeal_core", ["peerdeal_protocol"])
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_protocol/src/internal.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertTrue(any("imports another package's src" in failure for failure in failures))


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
