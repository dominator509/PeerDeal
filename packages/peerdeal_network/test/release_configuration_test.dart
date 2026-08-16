import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () async {
    expect(
      () => const BasicSessionPathSelector(
        maxCandidates: 0,
      ).selectPath(candidates: const [], preferLan: true, relayAllowed: true),
      throwsArgumentError,
    );

    await expectLater(
      const BasicBootstrapCandidateProvider(maxPeerIds: 0).resolveCandidates(
        BootstrapResolutionRequest(
          sessionId: 'session_1',
          tableId: 'table_1',
          preferLan: true,
          relayAllowed: true,
          peerIds: const [],
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () =>
          const DefaultConfidenceClassifier(maxSnapshots: 0).classify(const []),
      throwsArgumentError,
    );
    expect(
      () =>
          const DefaultPrimaryPeerElectionService(
            confidenceClassifier: DefaultConfidenceClassifier(),
            maxSnapshots: 0,
          ).elect(
            snapshots: const [],
            baselineEventIndex: 0,
            expectedAnchorHash: 'anchor',
          ),
      throwsArgumentError,
    );
  });
}
