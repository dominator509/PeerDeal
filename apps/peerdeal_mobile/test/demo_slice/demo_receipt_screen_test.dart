import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_mobile/demo_slice/screens/demo_receipt_screen.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';

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
