import 'package:peerdeal_crypto/peerdeal_crypto.dart';
import 'package:test/test.dart';

void expectUnmodifiable(void Function() mutation) {
  expect(mutation, throwsUnsupportedError);
}

void main() {
  test('DealProofBundle owns normalized and raw proof maps', () {
    final normalizedFields = <String, Object?>{
      'nested': <String, Object?>{
        'values': <Object?>['before'],
      },
    };
    final rawPayload = <String, Object?>{
      'raw': <String, Object?>{'value': true},
    };
    final bundle = DealProofBundle(
      providerId: 'provider',
      providerVersion: '1.0.0',
      proofReference: 'proof',
      normalizedFields: normalizedFields,
      rawPayload: rawPayload,
    );

    normalizedFields['later'] = true;
    rawPayload['later'] = true;

    expect(bundle.normalizedFields.containsKey('later'), isFalse);
    expect(bundle.rawPayload?.containsKey('later'), isFalse);
    expectUnmodifiable(
      () => ((bundle.normalizedFields['nested'] as Map)['values'] as List).add(
        'blocked',
      ),
    );
    expectUnmodifiable(() => bundle.rawPayload?['later'] = true);
  });

  test('VerificationPayload owns evidence and warning lists', () {
    final passed = <String>['replay_integrity'];
    final failed = <String>['settlement_integrity'];
    final warnings = <String>['warning'];
    final payload = VerificationPayload(
      verificationLayersPassed: passed,
      verificationLayersFailed: failed,
      warnings: warnings,
    );

    passed.add('later_pass');
    failed.add('later_failure');
    warnings.add('later_warning');

    expect(payload.verificationLayersPassed, ['replay_integrity']);
    expect(payload.verificationLayersFailed, ['settlement_integrity']);
    expect(payload.warnings, ['warning']);
    expectUnmodifiable(() => payload.verificationLayersPassed.add('blocked'));
    expectUnmodifiable(() => payload.warnings.add('blocked'));
  });

  test('VerificationResult owns the layer collection', () {
    final layers = <VerificationLayerResult>[
      VerificationLayerResult(layerId: 'replay_integrity', passed: true),
    ];
    final result = VerificationResult(
      state: VerificationState.verified,
      reasonCode: VerificationReasonCode.okVerifiedSession,
      layers: layers,
      summary: const VerificationSummary(
        headline: 'Verified',
        detail: 'Verified',
      ),
      payload: VerificationPayload(
        verificationLayersPassed: const <String>['replay_integrity'],
        verificationLayersFailed: const <String>[],
      ),
    );

    layers.clear();

    expect(result.layers, hasLength(1));
    expectUnmodifiable(() => result.layers.clear());
  });
}
