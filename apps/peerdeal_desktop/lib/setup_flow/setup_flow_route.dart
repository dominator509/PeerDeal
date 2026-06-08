import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import 'setup_flow_models.dart';
import 'setup_flow_orchestrator.dart';

enum SetupFlowDemoMode { buildReady, invalid }

typedef SetupFlowOrchestratorFactory = SetupFlowOrchestrator Function();
typedef SetupFlowIntentFactory = SetupIntent Function(SetupFlowDemoMode mode);

class SetupFlowRoute extends StatefulWidget {
  const SetupFlowRoute({
    super.key,
    this.initialMode = SetupFlowDemoMode.buildReady,
    required SetupFlowOrchestratorFactory orchestratorFactory,
    SetupFlowIntentFactory? setupIntentFactory,
  }) : _orchestratorFactory = orchestratorFactory,
       _setupIntentFactory = setupIntentFactory ?? _defaultSetupIntentFor;

  final SetupFlowDemoMode initialMode;
  final SetupFlowOrchestratorFactory _orchestratorFactory;
  final SetupFlowIntentFactory _setupIntentFactory;

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
  Widget build(BuildContext context) {
    return FutureBuilder<SetupFlowOutcome>(
      future: _outcome,
      builder: (context, snapshot) {
        return PeerDealAppScaffold(
          title: 'Setup flow',
          subtitle: 'Game File setup compilation',
          actions: <Widget>[
            PeerDealActionButton(
              label: 'Compile build-ready setup',
              onPressed: () => _selectMode(SetupFlowDemoMode.buildReady),
            ),
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
    try {
      return widget._orchestratorFactory().compileSetup(
        intent: widget._setupIntentFactory(mode),
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
    setState(() {
      _mode = mode;
      _outcome = _run(mode);
    });
  }
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
          Text('Game File: ${outcome.gameFile?['game_file_version']}'),
        for (final error in outcome.errors) Text('Error: $error'),
        for (final warning in outcome.warnings) Text('Warning: $warning'),
      ],
    );
  }
}
