import 'dart:io';

import 'package:peerdeal_crypto/peerdeal_crypto.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test(
    'loads every verification request fixture through the typed decoder',
    () {
      final fixtureFiles = Directory('test/fixtures')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('_request.json'))
          .toList(growable: false);

      expect(fixtureFiles, hasLength(3));
      for (final file in fixtureFiles) {
        final request = loadVerificationRequestFixture(
          file.uri.pathSegments.last,
        );
        expect(request.tableId, isNotEmpty, reason: file.path);
        expect(request.sessionId, isNotEmpty, reason: file.path);
      }
    },
  );

  test('fixture verification outcomes remain fail-closed and typed', () {
    const engine = DefaultVerificationEngine(
      proofVerifier: _AcceptingProofVerifier(),
    );

    final verified = engine.verify(
      loadVerificationRequestFixture('verified_hand_request.json'),
    );
    final partial = engine.verify(
      loadVerificationRequestFixture('partial_session_request.json'),
    );
    final wiped = engine.verify(
      loadVerificationRequestFixture('wiped_request.json'),
    );

    expect(verified.state, VerificationState.verified);
    expect(verified.reasonCode, VerificationReasonCode.okVerifiedHand);
    expect(partial.state, VerificationState.partial);
    expect(wiped.state, VerificationState.wiped);
  });
}

class _AcceptingProofVerifier implements DealProofVerifier {
  const _AcceptingProofVerifier();

  @override
  bool verify(DealProofBundle proofBundle) => true;
}
