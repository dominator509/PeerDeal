import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_desktop/demo_slice/screens/demo_receipt_screen.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

void main() {
  testWidgets('renders receipt details when surface is not obscured', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptScreen(surface: _surface(shouldObscure: false)),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
    expect(find.text('receipt_token: <redacted>'), findsOneWidget);
    expect(find.text('Receipt content hidden'), findsNothing);
  });

  testWidgets('wraps sensitive receipt details with SafeSurface obscuring', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptScreen(surface: _surface(shouldObscure: true)),
      ),
    );

    expect(find.text('receipt_token: <redacted>'), findsNothing);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes receipt fixture through presenter into safe screen', (
    tester,
  ) async {
    final bridge = _RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: presenter,
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(bridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.text('retention_mode: strict_ephemeral'), findsNothing);
  });

  testWidgets('routes recovery fixture through presenter into safe screen', (
    tester,
  ) async {
    final bridge = _RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('recovery_pause_transfer.json'),
          presenter: presenter,
          recovery: _recoveryResult(),
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(bridge.requestCount, 2);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.textContaining('ERR_FINAL_EVENT_HASH_MISMATCH'), findsNothing);
    expect(find.textContaining('expected_hash'), findsNothing);
    expect(find.textContaining('actual_hash'), findsNothing);
    expect(find.textContaining('<redacted>'), findsNothing);
  });
}

DemoReceiptSurfaceVm _surface({required bool shouldObscure}) {
  final plan = CaptureSurfacePlan(
    surface: CaptureSurface.receiptDetail,
    decision: CapturePolicyDecision(
      action: shouldObscure
          ? CapturePolicyAction.obscureOnly
          : CapturePolicyAction.allow,
      isSensitive: shouldObscure,
      reason: 'test',
    ),
    nativeNotes: 'test-native',
  );

  return DemoReceiptSurfaceVm(
    receipt: const SafeReceiptScanVm(
      status: 'ok',
      message: 'Receipt resolved.',
      shareableFields: {'receipt_token': '<redacted>'},
    ),
    receiptCapturePlan: plan,
    safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
  );
}

DemoScenarioSnapshot _fixtureSnapshot(String fixtureName) {
  final workspaceLocal = File('tools/demo_slice_fixtures/$fixtureName');
  final appLocal = File('../../tools/demo_slice_fixtures/$fixtureName');
  final file = workspaceLocal.existsSync() ? workspaceLocal : appLocal;
  return DemoScenarioSnapshot.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, Object?>,
  );
}

RecoveryResult<Object?> _recoveryResult() {
  return const RecoveryResult<Object?>(
    isSuccess: false,
    reconciliation: ReconciliationResult(
      canResume: false,
      requiresRecovery: true,
      recommendedAction: 'safe_close',
    ),
    conflicts: [
      SyncConflict(
        code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
        message: 'Final event hash does not match expected recovery baseline.',
        severity: SyncConflictSeverity.fatal,
        expected: 'expected_hash',
        actual: 'actual_hash',
      ),
    ],
    safeCloseRecommended: true,
  );
}

class _RecordingCaptureProtectionBridge implements CaptureProtectionBridge {
  int requestCount = 0;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    requestCount += 1;
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'screen-protection-supported',
      warning: 'best-effort',
    );
  }
}
