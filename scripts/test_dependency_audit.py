#!/usr/bin/env python3
from __future__ import annotations

import io
import sys
import unittest
from contextlib import redirect_stdout

from dependency_audit import extract_json_object, print_summary, safe_print, summarize_packages


class EncodedOutput(io.StringIO):
    encoding = "ascii"


class DependencyAuditTest(unittest.TestCase):
    def test_summarizes_outdated_and_constrained_packages(self) -> None:
        packages = [
            {
                "package": "meta",
                "kind": "direct",
                "current": {"version": "1.17.0"},
                "resolvable": {"version": "1.17.0"},
                "latest": {"version": "1.18.2"},
            },
            {
                "package": "flutter_lints",
                "kind": "dev",
                "current": {"version": "4.0.0"},
                "resolvable": {"version": "6.0.0"},
                "latest": {"version": "6.0.0"},
            },
            {
                "package": "stable",
                "kind": "transitive",
                "current": {"version": "1.0.0"},
                "resolvable": {"version": "1.0.0"},
                "latest": {"version": "1.0.0"},
            },
        ]

        outdated_count, constrained_count, direct_summaries = summarize_packages(packages)

        self.assertEqual(2, outdated_count)
        self.assertEqual(1, constrained_count)
        self.assertEqual(
            [
                "- meta: current 1.17.0, resolvable 1.17.0, latest 1.18.2",
                "- flutter_lints: current 4.0.0, resolvable 6.0.0, latest 6.0.0",
            ],
            direct_summaries,
        )

    def test_prints_advisory_warning_without_failing_summary(self) -> None:
        output = io.StringIO()

        with redirect_stdout(output):
            print_summary({"packages": []}, advisory_warning=True)

        self.assertIn("Dependency audit completed.", output.getvalue())
        self.assertIn("advisory metadata warnings", output.getvalue())

    def test_extracts_json_object_from_wrapped_output(self) -> None:
        self.assertEqual('{"packages":[]}', extract_json_object('noise\n{"packages":[]}\nmore'))

    def test_safe_print_replaces_unencodable_characters(self) -> None:
        output = EncodedOutput()

        safe_print("ok \u2603", stream=output)

        self.assertEqual("ok ?\n", output.getvalue())


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
