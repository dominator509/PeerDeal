import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class DemoReceiptSurfaceVm {
  const DemoReceiptSurfaceVm({required this.receipt, this.recovery});

  final SafeReceiptScanVm receipt;
  final SafeRecoveryVm? recovery;

  bool get showsRecovery => recovery != null;
}

class DemoReceiptSurfacePresenter {
  const DemoReceiptSurfacePresenter({
    SafeResultProjection projection = const SafeResultProjection(),
  }) : _projection = projection;

  final SafeResultProjection _projection;

  DemoReceiptSurfaceVm present({
    required ReceiptScanResult receipt,
    RecoveryResult<Object?>? recovery,
  }) {
    return DemoReceiptSurfaceVm(
      receipt: _projection.projectReceiptScan(receipt),
      recovery: recovery == null ? null : _projection.projectRecovery(recovery),
    );
  }
}
