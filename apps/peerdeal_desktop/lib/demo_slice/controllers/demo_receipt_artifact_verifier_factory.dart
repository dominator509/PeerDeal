import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import 'demo_receipt_artifact_verifier.dart';
import 'native_receipt_key_ring_loader.dart';

class DemoReceiptArtifactVerifierFactory {
  const DemoReceiptArtifactVerifierFactory({
    required SecureKeyStorageBridge bridge,
    this.namespace = NativeReceiptKeyRingLoader.defaultNamespace,
  }) : _bridge = bridge;

  factory DemoReceiptArtifactVerifierFactory.methodChannel({
    String namespace = NativeReceiptKeyRingLoader.defaultNamespace,
  }) {
    return DemoReceiptArtifactVerifierFactory(
      bridge: MethodChannelSecureKeyStorageBridge(),
      namespace: namespace,
    );
  }

  final SecureKeyStorageBridge _bridge;
  final String namespace;

  DemoReceiptArtifactVerifier create() {
    return DemoReceiptArtifactVerifier(
      keyRingLoader: NativeReceiptKeyRingLoader(
        bridge: _bridge,
        namespace: namespace,
      ),
    );
  }
}
