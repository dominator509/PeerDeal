import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import 'setup_flow_models.dart';
import 'setup_flow_orchestrator.dart';

enum SetupFlowDemoMode { buildReady, invalid }

typedef SetupFlowOrchestratorFactory = SetupFlowOrchestrator Function();
typedef SetupFlowIntentFactory = SetupIntent Function(SetupFlowDemoMode mode);

const int _maxSetupMessages = 4;

class SetupFlowRoute extends StatefulWidget {
  const SetupFlowRoute({
    super.key,
    this.initialMode = SetupFlowDemoMode.buildReady,
    Set<SetupFlowDemoMode>? enabledModes,
    required SetupFlowOrchestratorFactory orchestratorFactory,
    SetupFlowIntentFactory? setupIntentFactory,
  }) : _orchestratorFactory = orchestratorFactory,
       _setupIntentFactory = setupIntentFactory ?? _defaultSetupIntentFor,
       _enabledModes =
           enabledModes ??
           const <SetupFlowDemoMode>{
             SetupFlowDemoMode.buildReady,
             SetupFlowDemoMode.invalid,
           };

  final SetupFlowDemoMode initialMode;
  final SetupFlowOrchestratorFactory _orchestratorFactory;
  final SetupFlowIntentFactory _setupIntentFactory;
  final Set<SetupFlowDemoMode> _enabledModes;

  @override
  State<SetupFlowRoute> createState() => _SetupFlowRouteState();
}

class _SetupFlowRouteState extends State<SetupFlowRoute> {
  late SetupFlowDemoMode _mode;
  late Future<SetupFlowOutcome> _outcome;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _outcome = _run(_mode);
  }

  @override
  void didUpdateWidget(SetupFlowRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode ||
        oldWidget._orchestratorFactory != widget._orchestratorFactory ||
        oldWidget._setupIntentFactory != widget._setupIntentFactory ||
        oldWidget._enabledModes != widget._enabledModes) {
      _mode = widget.initialMode;
      _outcome = _run(_mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SetupFlowOutcome>(
      future: _outcome,
      builder: (context, snapshot) {
        return PeerDealAppScaffold(
          title: 'Setup flow',
          subtitle: 'Game File setup compilation',
          actions: <Widget>[
            if (_isModeEnabled(SetupFlowDemoMode.buildReady))
              PeerDealActionButton(
                label: 'Compile build-ready setup',
                onPressed: () => _selectMode(SetupFlowDemoMode.buildReady),
              ),
            if (_isModeEnabled(SetupFlowDemoMode.invalid))
              PeerDealActionButton(
                label: 'Compile invalid setup',
                onPressed: () => _selectMode(SetupFlowDemoMode.invalid),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PeerDealInfoRow(label: 'Mode', value: _mode.name),
              if (!snapshot.hasData)
                const Text('Loading setup')
              else
                _SetupOutcomeView(outcome: snapshot.requireData),
            ],
          ),
        );
      },
    );
  }

  Future<SetupFlowOutcome> _run(SetupFlowDemoMode mode) async {
    if (!_isModeEnabled(mode)) {
      return const SetupFlowOutcome(
        status: SetupFlowStatus.rejected,
        resultCode: 'ERR_SETUP_FLOW_MODE_DISABLED',
        errors: <String>['setup_flow_mode_disabled'],
      );
    }

    try {
      final intent = widget._setupIntentFactory(mode);
      final invalidIntent = _invalidSetupIntentOutcome(intent);
      if (invalidIntent != null) return invalidIntent;

      return _safeSetupOutcome(
        widget._orchestratorFactory().compileSetup(intent: intent),
      );
    } on Object {
      return const SetupFlowOutcome(
        status: SetupFlowStatus.rejected,
        resultCode: 'ERR_SETUP_FLOW_UNAVAILABLE',
        errors: <String>['setup_flow_unavailable'],
      );
    }
  }

  void _selectMode(SetupFlowDemoMode mode) {
    if (!_isModeEnabled(mode)) return;
    setState(() {
      _mode = mode;
      _outcome = _run(mode);
    });
  }

  bool _isModeEnabled(SetupFlowDemoMode mode) {
    return widget._enabledModes.contains(mode);
  }
}

SetupFlowOutcome? _invalidSetupIntentOutcome(SetupIntent intent) {
  final errors = <String>[];
  if (intent.intentId.trim().isEmpty) {
    errors.add('setup_intent_id_missing');
  } else if (intent.intentId.trim() != intent.intentId) {
    errors.add('setup_intent_id_malformed');
  }
  if (intent.hostPseudonymousId.trim().isEmpty) {
    errors.add('setup_host_missing');
  } else if (intent.hostPseudonymousId.trim() != intent.hostPseudonymousId) {
    errors.add('setup_host_malformed');
  }

  if (errors.isEmpty) return null;
  return SetupFlowOutcome(
    status: SetupFlowStatus.rejected,
    resultCode: 'ERR_SETUP_INTENT_INVALID',
    errors: List<String>.unmodifiable(errors),
  );
}

SetupFlowOutcome _safeSetupOutcome(SetupFlowOutcome outcome) {
  if (!_isSafeSetupToken(outcome.resultCode)) {
    return const SetupFlowOutcome(
      status: SetupFlowStatus.rejected,
      resultCode: 'ERR_SETUP_OUTCOME_INVALID',
      errors: <String>['setup_outcome_invalid'],
    );
  }

  return SetupFlowOutcome(
    status: outcome.status,
    resultCode: outcome.resultCode,
    gameFile: outcome.gameFile,
    errors: _safeSetupMessages(
      outcome.errors,
      fallback: 'setup_error_unavailable',
      truncationMessage: 'setup_errors_truncated',
    ),
    warnings: _safeSetupMessages(
      outcome.warnings,
      fallback: 'setup_warning_unavailable',
      truncationMessage: 'setup_warnings_truncated',
    ),
  );
}

List<String> _safeSetupMessages(
  List<String> messages, {
  required String fallback,
  required String truncationMessage,
}) {
  final safeMessages = messages
      .take(_maxSetupMessages)
      .map((message) => _isSafeSetupToken(message) ? message : fallback)
      .toList();
  if (messages.length > _maxSetupMessages) {
    safeMessages.add(truncationMessage);
  }
  return List<String>.unmodifiable(safeMessages);
}

bool _isSafeSetupToken(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 80) {
    return false;
  }
  return value.codeUnits.every(_isSafeSetupTokenCodeUnit);
}

bool _isSafeSetupTokenCodeUnit(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x2D ||
      codeUnit == 0x2E ||
      codeUnit == 0x5F;
}

SetupIntent _defaultSetupIntentFor(SetupFlowDemoMode mode) {
  if (mode == SetupFlowDemoMode.invalid) {
    return const SetupIntent(
      intentId: 'intent_invalid',
      sourceType: SetupSurface.simple,
      hostPseudonymousId: 'host_demo',
    );
  }

  return const SetupIntent(
    intentId: 'intent_open_table',
    sourceType: SetupSurface.simple,
    hostPseudonymousId: 'host_demo',
    modePreference: 'open_table',
    variantPreference: 'holdem_nlhe',
    seatCountPreference: 6,
  );
}

class _SetupOutcomeView extends StatelessWidget {
  const _SetupOutcomeView({required this.outcome});

  final SetupFlowOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PeerDealInfoRow(label: 'Status', value: outcome.status.name),
        Text('Status: ${outcome.status.name}'),
        PeerDealInfoRow(label: 'Result', value: outcome.resultCode),
        Text('Result: ${outcome.resultCode}'),
        if (outcome.gameFile != null)
          Text(
            'Game File: ${_safeGameFileVersion(outcome.gameFile?['game_file_version'])}',
          ),
        for (final error in outcome.errors) Text('Error: $error'),
        for (final warning in outcome.warnings) Text('Warning: $warning'),
      ],
    );
  }
}

String _safeGameFileVersion(Object? value) {
  return value is String && _isSafeSetupToken(value) ? value : 'unavailable';
}
