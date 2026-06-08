import 'package:flutter/widgets.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'join_flow_models.dart';
import 'join_flow_orchestrator.dart';

enum JoinFlowDemoMode {
  firstJoin,
  ackRequired,
  unsupportedProtocol,
  roleDenied,
  rejoin,
}

typedef JoinFlowOrchestratorFactory =
    JoinFlowOrchestrator Function(JoinFlowDemoMode mode);

class JoinFlowRoute extends StatefulWidget {
  const JoinFlowRoute({
    super.key,
    this.initialMode = JoinFlowDemoMode.firstJoin,
    required JoinFlowOrchestratorFactory orchestratorFactory,
  }) : _orchestratorFactory = orchestratorFactory;

  final JoinFlowDemoMode initialMode;
  final JoinFlowOrchestratorFactory _orchestratorFactory;

  @override
  State<JoinFlowRoute> createState() => _JoinFlowRouteState();
}

class _JoinFlowRouteState extends State<JoinFlowRoute> {
  late JoinFlowDemoMode _mode;
  late Future<JoinFlowOutcome> _outcome;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _outcome = _run(_mode);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JoinFlowOutcome>(
      future: _outcome,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Join flow'),
              const SizedBox(height: 16),
              if (!snapshot.hasData)
                const Text('Loading join')
              else
                _JoinOutcomeView(outcome: snapshot.requireData),
              _JoinModeAction(
                label: 'Run first join',
                onTap: () => _selectMode(JoinFlowDemoMode.firstJoin),
              ),
              _JoinModeAction(
                label: 'Run ack required',
                onTap: () => _selectMode(JoinFlowDemoMode.ackRequired),
              ),
              _JoinModeAction(
                label: 'Run unsupported protocol',
                onTap: () => _selectMode(JoinFlowDemoMode.unsupportedProtocol),
              ),
              _JoinModeAction(
                label: 'Run role denied',
                onTap: () => _selectMode(JoinFlowDemoMode.roleDenied),
              ),
              _JoinModeAction(
                label: 'Run rejoin',
                onTap: () => _selectMode(JoinFlowDemoMode.rejoin),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<JoinFlowOutcome> _run(JoinFlowDemoMode mode) async {
    try {
      final orchestrator = widget._orchestratorFactory(mode);
      final context = InviteContext(
        inviteCode: 'ABC123',
        requestedRole: RequestedRole.player,
        rejoinToken: mode == JoinFlowDemoMode.rejoin ? 'rj_001' : null,
      );
      return mode == JoinFlowDemoMode.rejoin
          ? await orchestrator.runRejoin(context)
          : await orchestrator.runFirstJoin(context);
    } on Object {
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejected,
        resultCode: 'ERR_JOIN_FLOW_UNAVAILABLE',
        diagnostics: <ProtocolDiagnostic>[
          ProtocolDiagnostic(
            code: 'ERR_JOIN_FLOW_UNAVAILABLE',
            message: 'Join flow is unavailable.',
          ),
        ],
        message: 'Join flow is unavailable.',
      );
    }
  }

  void _selectMode(JoinFlowDemoMode mode) {
    setState(() {
      _mode = mode;
      _outcome = _run(mode);
    });
  }
}

class _JoinOutcomeView extends StatelessWidget {
  const _JoinOutcomeView({required this.outcome});

  final JoinFlowOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('State: ${outcome.state.name}'),
        Text('Result: ${outcome.resultCode}'),
        for (final diagnostic in outcome.diagnostics)
          Text('${diagnostic.code}: ${diagnostic.message}'),
      ],
    );
  }
}

class _JoinModeAction extends StatelessWidget {
  const _JoinModeAction({required this.label, required this.onTap});

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
