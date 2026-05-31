import 'package:flutter/widgets.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

import '../../safe_surface/safe_surface.dart';
import '../controllers/demo_receipt_artifact_verifier.dart';
import '../controllers/demo_receipt_surface_presenter.dart';
import '../models/demo_scenario_snapshot.dart';

class DemoReceiptRoute extends StatefulWidget {
  const DemoReceiptRoute({
    super.key,
    required this.snapshot,
    required this.presenter,
    this.exportArtifact,
    this.artifactVerifier,
    this.recovery,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoReceiptSurfacePresenter presenter;
  final ReceiptExportArtifact? exportArtifact;
  final DemoReceiptArtifactVerifier? artifactVerifier;
  final RecoveryResult<Object?>? recovery;

  @override
  State<DemoReceiptRoute> createState() => _DemoReceiptRouteState();
}

class _DemoReceiptRouteState extends State<DemoReceiptRoute> {
  late Future<DemoReceiptSurfaceVm> _surface;

  @override
  void initState() {
    super.initState();
    _surface = _present();
  }

  @override
  void didUpdateWidget(DemoReceiptRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot ||
        oldWidget.presenter != widget.presenter ||
        oldWidget.exportArtifact != widget.exportArtifact ||
        oldWidget.artifactVerifier != widget.artifactVerifier ||
        oldWidget.recovery != widget.recovery) {
      _surface = _present();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DemoReceiptSurfaceVm>(
      future: _surface,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Loading receipt');
        }

        return DemoReceiptScreen(surface: snapshot.requireData);
      },
    );
  }

  Future<DemoReceiptSurfaceVm> _present() {
    final artifact = widget.exportArtifact;
    if (artifact != null) {
      final verifier = widget.artifactVerifier;
      if (verifier == null) {
        return widget.presenter.present(
          receipt: const ReceiptScanResult(
            status: 'rejected',
            message: 'Receipt artifact verifier is unavailable.',
          ),
          recovery: widget.recovery,
        );
      }

      return widget.presenter.presentVerifiedExportArtifact(
        artifact: artifact,
        verifier: verifier,
        recovery: widget.recovery,
      );
    }

    return widget.presenter.present(
      receipt: _receiptScanResult(widget.snapshot),
      recovery: widget.recovery,
    );
  }
}

class DemoReceiptScreen extends StatelessWidget {
  const DemoReceiptScreen({super.key, required this.surface});

  final DemoReceiptSurfaceVm surface;

  @override
  Widget build(BuildContext context) {
    return SafeSurface(
      model: surface.safeSurface,
      obscuredChild: const Text('Receipt content hidden'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(surface.receipt.status),
          Text(surface.receipt.message),
          for (final field in surface.receipt.shareableFields.entries)
            Text('${field.key}: ${field.value}'),
          if (surface.recovery case final recovery?) ...[
            Text(recovery.recommendedAction),
            for (final diagnostic in recovery.diagnosticsJson)
              Text('${diagnostic['code']}: ${diagnostic['message']}'),
          ],
        ],
      ),
    );
  }
}

ReceiptScanResult _receiptScanResult(DemoScenarioSnapshot snapshot) {
  return ReceiptScanResult(
    status: snapshot.receipt.verificationState,
    message: 'Receipt resolved for ${snapshot.scenarioId}.',
    shareableFields: {
      'verification_state': snapshot.receipt.verificationState,
      'retention_mode': snapshot.receipt.retentionMode,
      'binding_mode': snapshot.receipt.bindingMode,
    },
  );
}
