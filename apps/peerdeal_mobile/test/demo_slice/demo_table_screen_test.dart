import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_network_confidence_presenter.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/native_bootstrap_candidate_loader.dart';
import 'package:peerdeal_mobile/demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'package:peerdeal_mobile/demo_slice/screens/demo_table_screen.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

void main() {
  testWidgets('scrubs table bootstrap and recovery warnings before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoTableScreen(
          snapshot: DemoScenarioSnapshots.snapshots.values.first,
          networkConfidence: const DemoNetworkConfidenceVm(
            confidence: NetworkConfidence.stable,
            recoveryRecommended: false,
          ),
          bootstrap: const NativeBootstrapCandidateLoadResult(
            discoveryAvailable: true,
            nativeNotes: 'ready',
            candidates: <BootstrapCandidate>[
              BootstrapCandidate(
                peerId: 'peer_1',
                routeClass: NetworkRouteClass.lanDirect,
                reachable: true,
                priority: 0,
              ),
            ],
            warnings: <String>[r'C:\secret\peers.log'],
          ),
          recoveryPersistence:
              const DemoRecoveryPersistenceLoadResult.available(
                persistedEventCount: 1,
                hasSnapshot: false,
                warnings: <String>['token sk-demo-secret'],
              ),
          onOpenChat: null,
          onOpenReceipt: null,
        ),
      ),
    );

    expect(
      find.text(
        'Bootstrap warning: Local network bootstrap warning unavailable.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence warning unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('renders safe table warnings unchanged', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoTableScreen(
          snapshot: DemoScenarioSnapshots.snapshots.values.first,
          networkConfidence: const DemoNetworkConfidenceVm(
            confidence: NetworkConfidence.stable,
            recoveryRecommended: false,
          ),
          bootstrap: const NativeBootstrapCandidateLoadResult.unavailable(
            nativeNotes: 'unavailable',
            warnings: <String>['Local network bootstrap loader unavailable.'],
          ),
          recoveryPersistence:
              const DemoRecoveryPersistenceLoadResult.unavailable(
                warnings: <String>[
                  'Recovery persistence store factory unavailable.',
                ],
              ),
          onOpenChat: null,
          onOpenReceipt: null,
        ),
      ),
    );

    expect(
      find.text(
        'Bootstrap warning: Local network bootstrap loader unavailable.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recovery persistence warning: '
        'Recovery persistence store factory unavailable.',
      ),
      findsOneWidget,
    );
  });
}
