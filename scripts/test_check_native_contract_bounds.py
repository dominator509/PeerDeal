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
    "discovery_dart": pathlib.Path(
        "packages/peerdeal_network/lib/src/services/lan_discovery_protocol.dart"
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
    "mobile_readiness": pathlib.Path(
        "apps/peerdeal_mobile/lib/native_readiness/app_native_readiness_loader.dart"
    ),
    "desktop_readiness": pathlib.Path(
        "apps/peerdeal_desktop/lib/native_readiness/app_native_readiness_loader.dart"
    ),
    "android_local_network": pathlib.Path(
        "apps/peerdeal_mobile/android/app/src/main/kotlin/"
        "com/peerdeal/peerdeal_mobile/LocalNetworkHandler.kt"
    ),
    "windows_local_network": pathlib.Path(
        "apps/peerdeal_desktop/windows/runner/windows_local_network.cpp"
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
  static const maxPeerIdentityBytes = 256;
  static const maxTransportSequence = 0x7fffffff;
}
""",
        "discovery_dart": """
class LanDiscoveryProtocol {
  static const multicastAddress = '239.255.42.100';
  static const multicastPort = 40443;
  static const defaultTransportPort = 40442;
  static const _headerBytes = 10;
  static const _version = 1;
  static const _queryKind = 1;
  static const _advertisementKind = 2;
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
        "mobile_readiness": """
class AppNativeReadinessLoader {
  AppNativeReadinessLoader({
    int nativeTransportMaxPayloadBytes =
        NativeBridgePayloadLimits.maxTransportPayloadBytes,
  });

  factory AppNativeReadinessLoader.methodChannel({
    int nativeTransportMaxPayloadBytes =
        NativeBridgePayloadLimits.maxTransportPayloadBytes,
  }) => AppNativeReadinessLoader();
}
""",
        "desktop_readiness": """
class AppNativeReadinessLoader {
  AppNativeReadinessLoader({
    int nativeTransportMaxPayloadBytes =
        NativeBridgePayloadLimits.maxTransportPayloadBytes,
  });

  factory AppNativeReadinessLoader.methodChannel({
    int nativeTransportMaxPayloadBytes =
        NativeBridgePayloadLimits.maxTransportPayloadBytes,
  }) => AppNativeReadinessLoader();
}
""",
        "android_local_network": """
private const val DISCOVERY_ADDRESS = "239.255.42.100"
private const val DISCOVERY_PORT = 40443
private const val DEFAULT_ADVERTISED_PORT = 40442
private const val HEADER_BYTES = 10
private const val MAX_ID_BYTES = 256
private const val VERSION = 1
private const val QUERY_KIND = 1
private const val ADVERTISEMENT_KIND = 2
""",
        "windows_local_network": """
constexpr const char* kDiscoveryAddress = "239.255.42.100";
constexpr unsigned short kDiscoveryPort = 40443;
constexpr unsigned short kDefaultAdvertisedPort = 40442;
constexpr std::size_t kHeaderBytes = 10;
constexpr std::size_t kMaxIdentityBytes = 256;
constexpr uint8_t kVersion = 1;
constexpr uint8_t kQueryKind = 1;
constexpr uint8_t kAdvertisementKind = 2;
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

    def test_rejects_readiness_payload_default_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            mobile_path = root / SOURCE_PATHS["mobile_readiness"]
            mobile_path.write_text(
                mobile_path.read_text(encoding="utf-8").replace(
                    "NativeBridgePayloadLimits.maxTransportPayloadBytes",
                    "60 * 1024",
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(2, len(failures))
            self.assertTrue(
                all(
                    "app_native_readiness_loader.dart" in failure
                    and "nativeTransportMaxPayloadBytes" in failure
                    and "must reference" in failure
                    for failure in failures
                )
            )

    def test_rejects_missing_source(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            (root / SOURCE_PATHS["windows"]).unlink()

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("native contract source is missing", failures[0])

    def test_rejects_discovery_port_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            android_path = root / SOURCE_PATHS["android_local_network"]
            android_path.write_text(
                android_path.read_text(encoding="utf-8").replace(
                    "DISCOVERY_PORT = 40443", "DISCOVERY_PORT = 40444"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("DISCOVERY_PORT=40444", failures[0])
            self.assertIn("multicastPort=40443", failures[0])

    def test_rejects_discovery_address_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            write_contract_sources(root)
            windows_path = root / SOURCE_PATHS["windows_local_network"]
            windows_path.write_text(
                windows_path.read_text(encoding="utf-8").replace(
                    "239.255.42.100", "239.255.42.101"
                ),
                encoding="utf-8",
            )

            failures = check_native_contract_bounds(root)

            self.assertEqual(1, len(failures))
            self.assertIn("kDiscoveryAddress='239.255.42.101'", failures[0])
            self.assertIn("multicastAddress='239.255.42.100'", failures[0])


if __name__ == "__main__":
    runner = unittest.TextTestRunner(stream=sys.stdout)
    unittest.main(testRunner=runner)
