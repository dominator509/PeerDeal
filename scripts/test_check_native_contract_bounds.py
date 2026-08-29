#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import sys
import tempfile
import unittest

from check_native_contract_bounds import check_native_contract_bounds


SOURCE_PATHS = {
    "dart": pathlib.Path(
        "packages/peerdeal_native_bridges/lib/src/native_bridge_payload_limits.dart"
    ),
    "network": pathlib.Path(
        "packages/peerdeal_network/lib/src/models/network_input_limits.dart"
    ),
    "android": pathlib.Path(
        "apps/peerdeal_mobile/android/app/src/main/kotlin/"
        "com/peerdeal/peerdeal_mobile/NativeTransportHandler.kt"
    ),
    "windows": pathlib.Path(
        "apps/peerdeal_desktop/windows/runner/windows_native_transport.cpp"
    ),
    "mobile_app": pathlib.Path(
        "apps/peerdeal_mobile/lib/transport/native_transport_session_factory.dart"
    ),
    "desktop_app": pathlib.Path(
        "apps/peerdeal_desktop/lib/transport/native_transport_session_factory.dart"
    ),
}


def write_contract_sources(root: pathlib.Path) -> None:
    sources = {
        "dart": """
class NativeBridgePayloadLimits {
  static const maxTransportFrames = 64;
  static const maxTransportPayloadBytes = 60 * 1024;
  static const maxTransportIdentityBytes = 256;
  static const maxTransportSequence = 0x7fffffff;
}
""",
        "network": """
class NetworkInputLimits {
  static const maxTransportSequence = 0x7fffffff;
}
""",
        "android": """
private const val MAX_PAYLOAD_BYTES = 60 * 1024
private const val MAX_ID_BYTES = 256
private const val MAX_BATCH_SIZE = 64
private val sequenceLimit = Int.MAX_VALUE
""",
        "windows": """
constexpr std::size_t kMaxPayloadBytes = 60 * 1024;
constexpr std::size_t kMaxIdBytes = 256;
constexpr std::size_t kMaxBatchSize = 64;
auto sequence_limit = std::numeric_limits<int32_t>::max();
""",
        "mobile_app": """
class NativeTransportSessionFactory {
  NativeTransportSessionFactory({
    int maxPayloadBytes = NativeBridgePayloadLimits.maxTransportPayloadBytes,
  });
}
""",
        "desktop_app": """
class NativeTransportSessionFactory {
  NativeTransportSessionFactory({
    int maxPayloadBytes = NativeBridgePayloadLimits.maxTransportPayloadBytes,
  });
}
""",
    }
    for platform, path in SOURCE_PATHS.items():
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(sources[platform], encoding="utf-8")


class NativeContractBoundsCheckTest(unittest.TestCase):
    def test_accepts_matching_transport_contract_sources(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)

            self.assertEqual([], check_native_contract_bounds(root))

    def test_rejects_platform_limit_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            android_path = root / SOURCE_PATHS["android"]
            android_path.write_text(
                android_path.read_text(encoding="utf-8").replace(
                    "60 * 1024", "64 * 1024"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("MAX_PAYLOAD_BYTES=65536", failures[0])
            self.assertIn("Dart maxTransportPayloadBytes=61440", failures[0])

    def test_rejects_missing_sequence_guard(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            windows_path = root / SOURCE_PATHS["windows"]
            windows_path.write_text(
                windows_path.read_text(encoding="utf-8").replace(
                    "std::numeric_limits<int32_t>::max()", "INT_MAX"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("signed 32-bit sequence guard", failures[0])

    def test_rejects_dart_sequence_limit_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            dart_path = root / SOURCE_PATHS["dart"]
            dart_path.write_text(
                dart_path.read_text(encoding="utf-8").replace(
                    "0x7fffffff", "0x7ffffffe"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("maxTransportSequence=2147483646", failures[0])
            self.assertIn("signed 32-bit ceiling 2147483647", failures[0])

    def test_rejects_network_sequence_limit_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            network_path = root / SOURCE_PATHS["network"]
            network_path.write_text(
                network_path.read_text(encoding="utf-8").replace(
                    "0x7fffffff", "0x7ffffffe"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("network_input_limits.dart", failures[0])
            self.assertIn("maxTransportSequence=2147483646", failures[0])
            self.assertIn("signed 32-bit ceiling 2147483647", failures[0])

    def test_rejects_app_payload_default_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            mobile_path = root / SOURCE_PATHS["mobile_app"]
            mobile_path.write_text(
                mobile_path.read_text(encoding="utf-8").replace(
                    "NativeBridgePayloadLimits.maxTransportPayloadBytes",
                    "60 * 1024",
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("native_transport_session_factory.dart", failures[0])
            self.assertIn("must reference", failures[0])

    def test_rejects_missing_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            (root / SOURCE_PATHS["windows"]).unlink()

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("native contract source is missing", failures[0])


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
