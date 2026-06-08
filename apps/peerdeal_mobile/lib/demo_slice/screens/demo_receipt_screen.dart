import 'package:flutter/widgets.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

import '../../safe_surface/safe_surface.dart';
import '../controllers/demo_receipt_artifact_verifier.dart';
import '../controllers/demo_receipt_surface_presenter.dart';
import '../controllers/native_receipt_export_artifact_factory.dart';
import '../models/demo_scenario_snapshot.dart';

class DemoReceiptRoute extends StatefulWidget {
  const DemoReceiptRoute({
    super.key,
    required this.snapshot,
    required this.presenter,
    this.exportArtifact,
    this.receipt,
    this.exportArtifactFactory,
    this.artifactVerifier,
    this.recovery,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoReceiptSurfacePresenter presenter;
  final ReceiptExportArtifact? exportArtifact;
  final PeerDealReceipt? receipt;
  final ReceiptExportArtifactBuilder? exportArtifactFactory;
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
        oldWidget.receipt != widget.receipt ||
        oldWidget.exportArtifactFactory != widget.exportArtifactFactory ||
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

  Future<DemoReceiptSurfaceVm> _present() async {
    try {
      return await _presentUnsafe();
    } on Object {
      return _failedClosedSurface();
    }
  }

  Future<DemoReceiptSurfaceVm> _presentUnsafe() async {
    final artifact = widget.exportArtifact;
    if (artifact != null) {
      return _presentArtifact(artifact);
    }

    final exportFactory = widget.exportArtifactFactory;
    final receipt = widget.receipt;
    if (exportFactory != null && receipt != null) {
      return _presentArtifact(await exportFactory(receipt));
    }

    return widget.presenter.present(
      receipt: _receiptScanResult(widget.snapshot),
      recovery: widget.recovery,
    );
  }

  Future<DemoReceiptSurfaceVm> _presentArtifact(
    ReceiptExportArtifact artifact,
  ) {
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

  DemoReceiptSurfaceVm _failedClosedSurface() {
    const plan = CaptureSurfacePlan(
      surface: CaptureSurface.receiptDetail,
      decision: CapturePolicyDecision(
        action: CapturePolicyAction.obscureOnly,
        isSensitive: true,
        reason: 'receipt_presentation_failed',
        warning: 'Receipt presentation failed closed.',
      ),
      nativeNotes: 'unavailable',
    );

    return DemoReceiptSurfaceVm(
      receipt: const SafeReceiptScanVm(
        status: 'rejected',
        message: 'Receipt presentation failed closed.',
        shareableFields: <String, Object?>{},
      ),
      receiptCapturePlan: plan,
      safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
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
