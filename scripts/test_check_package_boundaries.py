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
    write_file(package_root / "AGENTS.md", f"# {name} agent rules\n")
    write_file(package_root / "README.md", f"# {name}\n")
    return package_root


def write_app(root: pathlib.Path, name: str, dependencies: list[str] | None = None) -> pathlib.Path:
    app_root = root / "apps" / name
    dependency_lines = "".join(f"  {dependency}:\n    path: ../../packages/{dependency}\n" for dependency in dependencies or [])
    write_file(
        app_root / "pubspec.yaml",
        f"name: {name}\n\n"
        "environment:\n"
        "  sdk: '^3.11.5'\n\n"
        "dependencies:\n"
        f"{dependency_lines}",
    )
    write_file(app_root / "AGENTS.md", f"# {name} agent rules\n")
    write_file(app_root / "README.md", f"# {name}\n")
    return app_root


def write_workspace_metadata(root: pathlib.Path, package_paths: list[str]) -> None:
    workspace_entries = "\n".join(f"  - {package_path}" for package_path in package_paths)
    app_entries = "\n".join(
        f"  {pathlib.PurePosixPath(package_path).name}"
        for package_path in package_paths
        if package_path.startswith("apps/")
    )
    package_entries = "\n".join(
        f"  {pathlib.PurePosixPath(package_path).name}"
        for package_path in package_paths
        if package_path.startswith("packages/")
    )

    write_file(
        root / "pubspec.yaml",
        "name: fixture_workspace\n\n"
        "environment:\n"
        "  sdk: '^3.11.5'\n\n"
        "workspace:\n"
        f"{workspace_entries}\n",
    )
    write_file(
        root / "docs" / "PACKAGE_MAP.md",
        "# PeerDeal Package Map\n\n"
        "/apps\n"
        f"{app_entries}\n\n"
        "/packages\n"
        f"{package_entries}\n",
    )


class BoundaryCheckTest(unittest.TestCase):
    def test_allows_declared_package_map_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            core_root = write_package(root, "peerdeal_core", ["peerdeal_protocol"])
            write_workspace_metadata(
                root,
                ["packages/peerdeal_protocol", "packages/peerdeal_core"],
            )
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
            write_workspace_metadata(
                root,
                ["packages/peerdeal_protocol", "packages/peerdeal_core"],
            )
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
            write_workspace_metadata(
                root,
                [
                    "packages/peerdeal_protocol",
                    "packages/peerdeal_network",
                    "packages/peerdeal_core",
                ],
            )
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_network/peerdeal_network.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertTrue(any("per package map" in failure for failure in failures))

    def test_rejects_package_importing_app_package(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_mobile")
            package_root = write_package(root, "peerdeal_network", ["peerdeal_mobile"])
            write_workspace_metadata(
                root,
                ["apps/peerdeal_mobile", "packages/peerdeal_network"],
            )
            write_file(
                package_root / "lib" / "peerdeal_network.dart",
                "import 'package:peerdeal_mobile/main.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertTrue(any("may not import app package peerdeal_mobile" in failure for failure in failures))

    def test_rejects_src_import(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_protocol")
            core_root = write_package(root, "peerdeal_core", ["peerdeal_protocol"])
            write_workspace_metadata(
                root,
                ["packages/peerdeal_protocol", "packages/peerdeal_core"],
            )
            write_file(
                core_root / "lib" / "peerdeal_core.dart",
                "import 'package:peerdeal_protocol/src/internal.dart';\n",
            )

            failures = check_boundaries(root)

            self.assertTrue(any("imports another package's src" in failure for failure in failures))

    def test_rejects_workspace_package_list_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_core")
            write_workspace_metadata(root, [])

            failures = check_boundaries(root)

            self.assertTrue(any("workspace package list: missing packages/peerdeal_core" in failure for failure in failures))

    def test_rejects_package_map_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_core")
            write_file(
                root / "pubspec.yaml",
                "name: fixture_workspace\n\n"
                "workspace:\n"
                "  - packages/peerdeal_core\n",
            )
            write_file(root / "docs" / "PACKAGE_MAP.md", "# PeerDeal Package Map\n\n/packages\n")

            failures = check_boundaries(root)

            self.assertTrue(any("docs/PACKAGE_MAP.md: missing packages/peerdeal_core" in failure for failure in failures))

    def test_rejects_duplicate_package_names(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_core")
            duplicate_root = root / "packages" / "peerdeal_core_copy"
            write_file(
                duplicate_root / "pubspec.yaml",
                "name: peerdeal_core\n\n"
                "environment:\n"
                "  sdk: '^3.11.5'\n",
            )
            write_file(duplicate_root / "AGENTS.md", "# duplicate agent rules\n")
            write_file(duplicate_root / "README.md", "# duplicate\n")
            write_workspace_metadata(
                root,
                ["packages/peerdeal_core", "packages/peerdeal_core_copy"],
            )

            failures = check_boundaries(root)

            self.assertTrue(any("duplicate package name peerdeal_core" in failure for failure in failures))

    def test_rejects_pubspec_without_package_name(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            package_root = root / "packages" / "peerdeal_core"
            write_file(
                package_root / "pubspec.yaml",
                "environment:\n"
                "  sdk: '^3.11.5'\n",
            )
            write_file(package_root / "AGENTS.md", "# peerdeal_core agent rules\n")
            write_file(package_root / "README.md", "# peerdeal_core\n")
            write_workspace_metadata(root, ["packages/peerdeal_core"])

            failures = check_boundaries(root)

            self.assertTrue(any("pubspec.yaml is missing a package name" in failure for failure in failures))

    def test_rejects_app_package_outside_apps_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_package(root, "peerdeal_mobile")
            write_workspace_metadata(root, ["packages/peerdeal_mobile"])

            failures = check_boundaries(root)

            self.assertTrue(any("package peerdeal_mobile must live at apps/peerdeal_mobile" in failure for failure in failures))

    def test_rejects_package_folder_name_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            package_root = root / "packages" / "peerdeal_core_renamed"
            write_file(
                package_root / "pubspec.yaml",
                "name: peerdeal_core\n\n"
                "environment:\n"
                "  sdk: '^3.11.5'\n",
            )
            write_file(package_root / "AGENTS.md", "# peerdeal_core agent rules\n")
            write_file(package_root / "README.md", "# peerdeal_core\n")
            write_workspace_metadata(root, ["packages/peerdeal_core_renamed"])

            failures = check_boundaries(root)

            self.assertTrue(any("package peerdeal_core must live at packages/peerdeal_core" in failure for failure in failures))

    def test_allows_app_package_in_apps_folder(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_app(root, "peerdeal_mobile")
            write_workspace_metadata(root, ["apps/peerdeal_mobile"])

            self.assertEqual([], check_boundaries(root))

    def test_rejects_missing_package_local_docs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            package_root = write_package(root, "peerdeal_core")
            write_workspace_metadata(root, ["packages/peerdeal_core"])
            (package_root / "AGENTS.md").unlink()

            failures = check_boundaries(root)

            self.assertTrue(any("peerdeal_core: missing package-local AGENTS.md" in failure for failure in failures))


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
