#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import sys
import tempfile
import unittest

from check_source_text import check_source_text


def write_file(path: pathlib.Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_bytes(path: pathlib.Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)


class SourceTextCheckTest(unittest.TestCase):
    def test_allows_clean_source_text(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / "lib" / "sample.dart", "const label = 'Clean';\n")

            self.assertEqual([], check_source_text(root))

    def test_rejects_mojibake_marker(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / "lib" / "sample.dart", "const label = 'A\u00c2B';\n")

            failures = check_source_text(root)

            self.assertEqual(1, len(failures))
            self.assertIn("likely mojibake marker", failures[0])

    def test_rejects_bom(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / "pubspec.yaml", "\ufeffname: sample\n")

            failures = check_source_text(root)

            self.assertEqual(1, len(failures))
            self.assertIn("byte order mark", failures[0])

    def test_rejects_em_dash(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / "README.md", "Title \u2014 Overview\n")

            failures = check_source_text(root)

            self.assertEqual(1, len(failures))
            self.assertIn("em dash", failures[0])

    def test_rejects_replacement_character(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / "fixture.json", '{"label": "bad\ufffdtext"}\n')

            failures = check_source_text(root)

            self.assertEqual(1, len(failures))
            self.assertIn("unicode replacement character", failures[0])

    def test_ignores_generated_tooling_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_file(root / ".dart_tool" / "cache.dart", "bad\ufffdtext\n")
            write_file(root / "build" / "cache.json", '{"label": "A\u00c2B"}\n')

            self.assertEqual([], check_source_text(root))

    def test_rejects_invalid_utf8_text_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_bytes(root / "lib" / "bad.dart", b"\xff\xfe")

            failures = check_source_text(root)

            self.assertEqual(1, len(failures))
            self.assertIn("invalid utf-8 text", failures[0])


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
