import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class DemoReceiptSurfaceVm {
  const DemoReceiptSurfaceVm({
    required this.receipt,
    required this.receiptCapturePlan,
    this.recovery,
    this.recoveryCapturePlan,
  });

  final SafeReceiptScanVm receipt;
  final CaptureSurfacePlan receiptCapturePlan;
  final SafeRecoveryVm? recovery;
  final CaptureSurfacePlan? recoveryCapturePlan;

  bool get showsRecovery => recovery != null;
  bool get shouldObscure =>
      receiptCapturePlan.shouldObscure ||
      (recoveryCapturePlan?.shouldObscure ?? false);
}

class DemoReceiptSurfacePresenter {
  DemoReceiptSurfacePresenter({
    SafeResultProjection projection = const SafeResultProjection(),
    CaptureSurfaceCoordinator? captureCoordinator,
  }) : _projection = projection,
       _captureCoordinator =
           captureCoordinator ??
           CaptureSurfaceCoordinator(
             bridge: MethodChannelCaptureProtectionBridge(),
           );

  final SafeResultProjection _projection;
  final CaptureSurfaceCoordinator _captureCoordinator;

  Future<DemoReceiptSurfaceVm> present({
    required ReceiptScanResult receipt,
    RecoveryResult<Object?>? recovery,
  }) async {
    final receiptCapturePlan = await _captureCoordinator.resolve(
      CaptureSurface.receiptDetail,
    );
    final recoveryCapturePlan = recovery == null
        ? null
        : await _captureCoordinator.resolve(CaptureSurface.restore);

    return DemoReceiptSurfaceVm(
      receipt: _projection.projectReceiptScan(receipt),
      receiptCapturePlan: receiptCapturePlan,
      recovery: recovery == null ? null : _projection.projectRecovery(recovery),
      recoveryCapturePlan: recoveryCapturePlan,
    );
  }
}
