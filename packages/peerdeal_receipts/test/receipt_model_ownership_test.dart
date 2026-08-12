import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void expectUnmodifiable(void Function() mutation) {
  expect(mutation, throwsUnsupportedError);
}

void main() {
  test('receipt scan and export models own nested maps and diagnostics', () {
    final shareableFields = <String, Object?>{
      'nested': <String, Object?>{'values': <Object?>['before']},
    };
    final scan = ReceiptScanResult(
      status: 'ok',
      message: 'Ready',
      shareableFields: shareableFields,
    );
    final payload = <String, Object?>{
      'nested': <String, Object?>{'value': true},
    };
    final diagnostics = <String>['diagnostic'];
    final inspection = ReceiptExportInspectionResult(
      status: 'ok',
      message: 'Accepted',
      payload: payload,
      diagnostics: diagnostics,
    );
    final metadata = <String, Object?>{
      'nested': <String, Object?>{'value': <Object?>['before']},
    };
    final artifact = ReceiptExportArtifact(
      artifactType: 'file',
      encodedBody: 'body',
      minimalMetadata: metadata,
    );

    shareableFields['later'] = true;
    payload['later'] = true;
    diagnostics.add('later_diagnostic');
    metadata['later'] = true;

    expect(scan.shareableFields.containsKey('later'), isFalse);
    expect(inspection.payload.containsKey('later'), isFalse);
    expect(inspection.diagnostics, ['diagnostic']);
    expect(artifact.minimalMetadata.containsKey('later'), isFalse);
    expectUnmodifiable(
      () => ((scan.shareableFields['nested'] as Map)['values'] as List)
          .add('blocked'),
    );
    expectUnmodifiable(() => inspection.diagnostics.add('blocked'));
    expectUnmodifiable(
      () => ((artifact.minimalMetadata['nested'] as Map)['value'] as List)
          .add('blocked'),
    );
  });

  test('receipt key providers own retained key collections', () {
    final signingKeys = <ReceiptSigningKey>[
      const ReceiptSigningKey(keyId: 'retained', secret: 'secret'),
    ];
    final encryptionKeys = <ReceiptEncryptionKey>[
      const ReceiptEncryptionKey(keyId: 'retained', secret: 'secret'),
    ];
    final keyRing = ReceiptKeyRingSnapshot(
      verificationSigningKeys: signingKeys,
      decryptionKeys: encryptionKeys,
    );
    final staticProvider = StaticReceiptSigningKeyProvider(
      activeKey: const ReceiptSigningKey(keyId: 'active', secret: 'secret'),
      verificationKeys: signingKeys,
    );

    signingKeys.clear();
    encryptionKeys.clear();

    expect(keyRing.verificationSigningKeys, hasLength(1));
    expect(keyRing.decryptionKeys, hasLength(1));
    expect(staticProvider.verificationKeys, hasLength(1));
    expectUnmodifiable(() => keyRing.verificationSigningKeys.clear());
    expectUnmodifiable(() => keyRing.decryptionKeys.clear());
    expectUnmodifiable(() => staticProvider.verificationKeys.clear());
  });
}
