import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

import 'demo_receipt_artifact_verifier.dart';

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
    return _presentReceiptScan(receipt: receipt, recovery: recovery);
  }

  Future<DemoReceiptSurfaceVm> presentExportArtifact({
    required ReceiptExportArtifact artifact,
    required OpaqueExportDecoder decoder,
    RecoveryResult<Object?>? recovery,
  }) {
    return _presentReceiptScan(
      receipt: _scanFromInspection(decoder.inspect(artifact)),
      recovery: recovery,
    );
  }

  Future<DemoReceiptSurfaceVm> presentVerifiedExportArtifact({
    required ReceiptExportArtifact artifact,
    required DemoReceiptArtifactVerifier verifier,
    RecoveryResult<Object?>? recovery,
  }) async {
    return _presentReceiptScan(
      receipt: _scanFromInspection(await verifier.inspect(artifact)),
      recovery: recovery,
    );
  }

  Future<DemoReceiptSurfaceVm> _presentReceiptScan({
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

  ReceiptScanResult _scanFromInspection(ReceiptExportInspectionResult result) {
    if (!result.isAccepted) {
      return ReceiptScanResult(
        status: result.status,
        message: result.message,
        shareableFields: <String, Object?>{
          if (result.diagnostics.isNotEmpty) 'diagnostics': result.diagnostics,
        },
      );
    }

    return ReceiptScanResult(
      status: result.status,
      message: result.message,
      shareableFields: <String, Object?>{
        'receipt_id': result.payload['receipt_id'],
        'receipt_version': result.payload['receipt_version'],
        'protocol_version': result.payload['protocol_version'],
        'mode_type': result.payload['mode_type'],
      },
    );
  }
}
