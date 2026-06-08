import 'package:flutter/widgets.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import 'setup_flow_models.dart';
import 'setup_flow_orchestrator.dart';

enum SetupFlowDemoMode { buildReady, invalid }

typedef SetupFlowOrchestratorFactory = SetupFlowOrchestrator Function();

class SetupFlowRoute extends StatefulWidget {
  const SetupFlowRoute({
    super.key,
    this.initialMode = SetupFlowDemoMode.buildReady,
    required SetupFlowOrchestratorFactory orchestratorFactory,
  }) : _orchestratorFactory = orchestratorFactory;

  final SetupFlowDemoMode initialMode;
  final SetupFlowOrchestratorFactory _orchestratorFactory;

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
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Setup flow'),
              const SizedBox(height: 16),
              if (!snapshot.hasData)
                const Text('Loading setup')
              else
                _SetupOutcomeView(outcome: snapshot.requireData),
              _SetupModeAction(
                label: 'Compile build-ready setup',
                onTap: () => _selectMode(SetupFlowDemoMode.buildReady),
              ),
              _SetupModeAction(
                label: 'Compile invalid setup',
                onTap: () => _selectMode(SetupFlowDemoMode.invalid),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<SetupFlowOutcome> _run(SetupFlowDemoMode mode) async {
    try {
      return widget._orchestratorFactory().compileSetup(
        intent: _intentFor(mode),
      );
    } on Object {
      return const SetupFlowOutcome(
        status: SetupFlowStatus.rejected,
        resultCode: 'ERR_SETUP_FLOW_UNAVAILABLE',
        errors: <String>['setup_flow_unavailable'],
      );
    }
  }

  SetupIntent _intentFor(SetupFlowDemoMode mode) {
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

  void _selectMode(SetupFlowDemoMode mode) {
    setState(() {
      _mode = mode;
      _outcome = _run(mode);
    });
  }
}

class _SetupOutcomeView extends StatelessWidget {
  const _SetupOutcomeView({required this.outcome});

  final SetupFlowOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Status: ${outcome.status.name}'),
        Text('Result: ${outcome.resultCode}'),
        if (outcome.gameFile != null)
          Text('Game File: ${outcome.gameFile?['game_file_version']}'),
        for (final error in outcome.errors) Text('Error: $error'),
        for (final warning in outcome.warnings) Text('Warning: $warning'),
      ],
    );
  }
}

class _SetupModeAction extends StatelessWidget {
  const _SetupModeAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}
