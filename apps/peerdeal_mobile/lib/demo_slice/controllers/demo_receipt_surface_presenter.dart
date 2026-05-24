import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class DemoReceiptSurfaceVm {
  const DemoReceiptSurfaceVm({
    required this.receipt,
    required this.receiptCapturePlan,
    required this.safeSurface,
    this.recovery,
    this.recoveryCapturePlan,
  });

  final SafeReceiptScanVm receipt;
  final CaptureSurfacePlan receiptCapturePlan;
  final SafeSurfaceRenderModel safeSurface;
  final SafeRecoveryVm? recovery;
  final CaptureSurfacePlan? recoveryCapturePlan;

  bool get showsRecovery => recovery != null;
  bool get shouldObscure => safeSurface.shouldObscure;
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
      safeSurface: SafeSurfaceRenderModel.fromCapturePlans([
        receiptCapturePlan,
        recoveryCapturePlan,
      ]),
      recovery: recovery == null ? null : _projection.projectRecovery(recovery),
      recoveryCapturePlan: recoveryCapturePlan,
    );
  }
}
