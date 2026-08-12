import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../../safe_surface/safe_surface.dart';
import '../controllers/demo_receipt_artifact_verifier.dart';
import '../controllers/demo_receipt_surface_presenter.dart';
import '../controllers/native_receipt_export_artifact_factory.dart';
import '../models/demo_scenario_snapshot.dart';

const int _maxReceiptShareableFields = 4;
const int _maxReceiptRecoveryDiagnostics = 4;

class DemoReceiptRoute extends StatefulWidget {
  const DemoReceiptRoute({
    super.key,
    required this.snapshot,
    required this.presenter,
    this.exportArtifact,
    this.receipt,
    this.exportArtifactFactory,
    this.cancellableExportArtifactFactory,
    this.artifactVerifier,
    this.recovery,
  });

  final DemoScenarioSnapshot snapshot;
  final DemoReceiptSurfacePresenter presenter;
  final ReceiptExportArtifact? exportArtifact;
  final PeerDealReceipt? receipt;
  final ReceiptExportArtifactBuilder? exportArtifactFactory;
  final CancellableReceiptExportArtifactBuilder?
  cancellableExportArtifactFactory;
  final DemoReceiptArtifactVerifier? artifactVerifier;
  final RecoveryResult<Object?>? recovery;

  @override
  State<DemoReceiptRoute> createState() => _DemoReceiptRouteState();
}

class _DemoReceiptRouteState extends State<DemoReceiptRoute> {
  late Future<DemoReceiptSurfaceVm> _surface;
  late Completer<void> _presentationCancellation;

  @override
  void initState() {
    super.initState();
    _presentationCancellation = Completer<void>();
    _surface = _present(cancellation: _presentationCancellation.future);
  }

  @override
  void didUpdateWidget(DemoReceiptRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot ||
        oldWidget.presenter != widget.presenter ||
        oldWidget.exportArtifact != widget.exportArtifact ||
        oldWidget.receipt != widget.receipt ||
        oldWidget.exportArtifactFactory != widget.exportArtifactFactory ||
        oldWidget.cancellableExportArtifactFactory !=
            widget.cancellableExportArtifactFactory ||
        oldWidget.artifactVerifier != widget.artifactVerifier ||
        oldWidget.recovery != widget.recovery) {
      _cancelPresentation();
      _presentationCancellation = Completer<void>();
      _surface = _present(cancellation: _presentationCancellation.future);
    }
  }

  @override
  void dispose() {
    _cancelPresentation();
    unawaited(widget.presenter.releaseCaptureProtection());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DemoReceiptSurfaceVm>(
      future: _surface,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const PeerDealAppScaffold(
            title: 'Receipt review',
            subtitle: 'Safe receipt and recovery projection',
            child: Text('Loading receipt'),
          );
        }

        return DemoReceiptScreen(surface: snapshot.requireData);
      },
    );
  }

  void _cancelPresentation() {
    if (!_presentationCancellation.isCompleted) {
      _presentationCancellation.complete();
    }
  }

  Future<DemoReceiptSurfaceVm> _present({Future<void>? cancellation}) async {
    try {
      return await _presentUnsafe(cancellation: cancellation);
    } on Object {
      return _failedClosedSurface();
    }
  }

  Future<DemoReceiptSurfaceVm> _presentUnsafe({
    Future<void>? cancellation,
  }) async {
    final artifact = widget.exportArtifact;
    final exportFactory = widget.exportArtifactFactory;
    final cancellableExportFactory = widget.cancellableExportArtifactFactory;
    final hasExportFactory =
        exportFactory != null || cancellableExportFactory != null;
    if (artifact != null && hasExportFactory) {
      return widget.presenter.present(
        receipt: ReceiptScanResult(
          status: 'rejected',
          message: 'Receipt export source configuration is invalid.',
        ),
        recovery: widget.recovery,
        cancellation: cancellation,
      );
    }

    if (artifact != null) {
      return _presentArtifact(artifact, cancellation: cancellation);
    }

    final receipt = widget.receipt;
    if (!hasExportFactory && receipt != null) {
      return widget.presenter.present(
        receipt: ReceiptScanResult(
          status: 'rejected',
          message: 'Receipt export path is unavailable.',
        ),
        recovery: widget.recovery,
        cancellation: cancellation,
      );
    }

    if (hasExportFactory && receipt == null) {
      return widget.presenter.present(
        receipt: ReceiptScanResult(
          status: 'rejected',
          message: 'Receipt export input is unavailable.',
        ),
        recovery: widget.recovery,
        cancellation: cancellation,
      );
    }

    if (hasExportFactory && receipt != null) {
      if (exportFactory != null && cancellableExportFactory != null) {
        return widget.presenter.present(
          receipt: ReceiptScanResult(
            status: 'rejected',
            message: 'Receipt export source configuration is invalid.',
          ),
          recovery: widget.recovery,
          cancellation: cancellation,
        );
      }
      return _presentArtifact(
        cancellableExportFactory != null
            ? await cancellableExportFactory(
                receipt,
                cancellation: cancellation,
              )
            : await exportFactory!(receipt),
        cancellation: cancellation,
      );
    }

    return widget.presenter.present(
      receipt: _receiptScanResult(widget.snapshot),
      recovery: widget.recovery,
      cancellation: cancellation,
    );
  }

  Future<DemoReceiptSurfaceVm> _presentArtifact(
    ReceiptExportArtifact artifact, {
    Future<void>? cancellation,
  }) {
    if (artifact.artifactType == 'unavailable') {
      return widget.presenter.present(
        receipt: ReceiptScanResult(
          status: 'rejected',
          message: 'Receipt artifact is unavailable.',
        ),
        recovery: widget.recovery,
        cancellation: cancellation,
      );
    }

    final verifier = widget.artifactVerifier;
    if (verifier == null) {
      return widget.presenter.present(
        receipt: ReceiptScanResult(
          status: 'rejected',
          message: 'Receipt artifact verifier is unavailable.',
        ),
        recovery: widget.recovery,
        cancellation: cancellation,
      );
    }

    return widget.presenter.presentVerifiedExportArtifact(
      artifact: artifact,
      verifier: verifier,
      recovery: widget.recovery,
      cancellation: cancellation,
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
    return PeerDealAppScaffold(
      title: 'Receipt review',
      subtitle: 'Safe receipt and recovery projection',
      child: SafeSurface(
        model: surface.safeSurface,
        obscuredChild: const Text('Receipt content hidden'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _safeReceiptToken(surface.receipt.status, fallback: 'rejected'),
            ),
            Text(_safeReceiptMessage(surface.receipt.message)),
            for (final field in surface.receipt.shareableFields.entries.take(
              _maxReceiptShareableFields,
            ))
              Text(
                '${_safeReceiptToken(field.key, fallback: 'field_unavailable')}: '
                '${_safeReceiptValue(field.value)}',
              ),
            if (surface.receipt.shareableFields.length >
                _maxReceiptShareableFields)
              const Text('receipt_fields_truncated: unavailable'),
            if (surface.recovery case final recovery?) ...[
              Text(_safeReceiptToken(recovery.recommendedAction)),
              for (final diagnostic in recovery.diagnosticsJson.take(
                _maxReceiptRecoveryDiagnostics,
              ))
                Text(
                  '${_safeReceiptToken(diagnostic['code'], fallback: 'ERR_RECEIPT_DIAGNOSTIC_UNAVAILABLE')}: ${_safeReceiptMessage(diagnostic['message'])}',
                ),
              if (recovery.diagnosticsJson.length >
                  _maxReceiptRecoveryDiagnostics)
                const Text(
                  'ERR_RECEIPT_DIAGNOSTICS_TRUNCATED: Receipt detail unavailable.',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _safeReceiptToken(Object? value, {String fallback = 'unavailable'}) {
  if (value is! String ||
      value.trim() != value ||
      value.isEmpty ||
      value.length > 80) {
    return fallback;
  }
  final isSafe = value.codeUnits.every(
    (codeUnit) =>
        (codeUnit >= 0x30 && codeUnit <= 0x39) ||
        (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
        (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
        codeUnit == 0x2D ||
        codeUnit == 0x2E ||
        codeUnit == 0x5F,
  );
  return isSafe ? value : fallback;
}

String _safeReceiptMessage(Object? value) {
  if (value is! String ||
      value.trim() != value ||
      value.isEmpty ||
      value.length > 160) {
    return 'Receipt detail unavailable.';
  }
  final lower = value.toLowerCase();
  if (lower.contains('secret') || lower.contains('token')) {
    return 'Receipt detail unavailable.';
  }
  final isSafe = value.codeUnits.every(
    (codeUnit) => codeUnit >= 0x20 && codeUnit != 0x5C && codeUnit != 0x7F,
  );
  return isSafe ? value : 'Receipt detail unavailable.';
}

String _safeReceiptValue(Object? value) {
  if (value == '<redacted>') return '<redacted>';
  return _safeReceiptToken(value);
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
