import 'package:flutter/widgets.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

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
typedef JoinFlowInviteContextFactory =
    InviteContext Function(JoinFlowDemoMode mode);

class JoinFlowRoute extends StatefulWidget {
  const JoinFlowRoute({
    super.key,
    this.initialMode = JoinFlowDemoMode.firstJoin,
    Set<JoinFlowDemoMode>? enabledModes,
    required JoinFlowOrchestratorFactory orchestratorFactory,
    JoinFlowInviteContextFactory? inviteContextFactory,
  }) : _orchestratorFactory = orchestratorFactory,
       _inviteContextFactory = inviteContextFactory ?? _defaultInviteContextFor,
       _enabledModes =
           enabledModes ??
           const <JoinFlowDemoMode>{
             JoinFlowDemoMode.firstJoin,
             JoinFlowDemoMode.ackRequired,
             JoinFlowDemoMode.unsupportedProtocol,
             JoinFlowDemoMode.roleDenied,
             JoinFlowDemoMode.rejoin,
           };

  final JoinFlowDemoMode initialMode;
  final JoinFlowOrchestratorFactory _orchestratorFactory;
  final JoinFlowInviteContextFactory _inviteContextFactory;
  final Set<JoinFlowDemoMode> _enabledModes;

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
        return PeerDealAppScaffold(
          title: 'Join flow',
          subtitle: 'Invite, disclosure, role, and rejoin checks',
          actions: <Widget>[
            if (_isModeEnabled(JoinFlowDemoMode.firstJoin))
              PeerDealActionButton(
                label: 'Run first join',
                onPressed: () => _selectMode(JoinFlowDemoMode.firstJoin),
              ),
            if (_isModeEnabled(JoinFlowDemoMode.ackRequired))
              PeerDealActionButton(
                label: 'Run ack required',
                onPressed: () => _selectMode(JoinFlowDemoMode.ackRequired),
              ),
            if (_isModeEnabled(JoinFlowDemoMode.unsupportedProtocol))
              PeerDealActionButton(
                label: 'Run unsupported protocol',
                onPressed: () =>
                    _selectMode(JoinFlowDemoMode.unsupportedProtocol),
              ),
            if (_isModeEnabled(JoinFlowDemoMode.roleDenied))
              PeerDealActionButton(
                label: 'Run role denied',
                onPressed: () => _selectMode(JoinFlowDemoMode.roleDenied),
              ),
            if (_isModeEnabled(JoinFlowDemoMode.rejoin))
              PeerDealActionButton(
                label: 'Run rejoin',
                onPressed: () => _selectMode(JoinFlowDemoMode.rejoin),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PeerDealInfoRow(label: 'Mode', value: _mode.name),
              if (!snapshot.hasData)
                const Text('Loading join')
              else
                _JoinOutcomeView(outcome: snapshot.requireData),
            ],
          ),
        );
      },
    );
  }

  Future<JoinFlowOutcome> _run(JoinFlowDemoMode mode) async {
    if (!_isModeEnabled(mode)) {
      return const JoinFlowOutcome(
        state: JoinFlowState.joinRejected,
        status: JoinDecisionStatus.rejected,
        resultCode: 'ERR_JOIN_FLOW_MODE_DISABLED',
        diagnostics: <ProtocolDiagnostic>[
          ProtocolDiagnostic(
            code: 'ERR_JOIN_FLOW_MODE_DISABLED',
            message: 'Join flow mode is unavailable.',
          ),
        ],
        message: 'Join flow mode is unavailable.',
      );
    }

    try {
      final orchestrator = widget._orchestratorFactory(mode);
      final context = widget._inviteContextFactory(mode);
      final invalidContext = _invalidInviteContextOutcome(mode, context);
      if (invalidContext != null) return invalidContext;

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
    if (!_isModeEnabled(mode)) return;
    setState(() {
      _mode = mode;
      _outcome = _run(mode);
    });
  }

  bool _isModeEnabled(JoinFlowDemoMode mode) {
    return widget._enabledModes.contains(mode);
  }
}

JoinFlowOutcome? _invalidInviteContextOutcome(
  JoinFlowDemoMode mode,
  InviteContext context,
) {
  if (context.inviteCode.trim().isEmpty) {
    return const JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.rejected,
      resultCode: 'ERR_INVITE_CONTEXT_INVALID',
      diagnostics: <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: 'ERR_INVITE_CONTEXT_INVALID',
          message: 'Invite context is invalid.',
        ),
      ],
      message: 'Invite context is invalid.',
    );
  }

  final rejoinToken = context.rejoinToken;
  if (mode == JoinFlowDemoMode.rejoin &&
      (rejoinToken == null || rejoinToken.trim().isEmpty)) {
    return const JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.rejoinRejected,
      resultCode: 'ERR_REJOIN_TOKEN_REQUIRED',
    );
  }

  return null;
}

InviteContext _defaultInviteContextFor(JoinFlowDemoMode mode) {
  return InviteContext(
    inviteCode: 'ABC123',
    requestedRole: RequestedRole.player,
    rejoinToken: mode == JoinFlowDemoMode.rejoin ? 'rj_001' : null,
  );
}

class _JoinOutcomeView extends StatelessWidget {
  const _JoinOutcomeView({required this.outcome});

  final JoinFlowOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PeerDealInfoRow(label: 'State', value: outcome.state.name),
        Text('State: ${outcome.state.name}'),
        PeerDealInfoRow(label: 'Result', value: outcome.resultCode),
        Text('Result: ${outcome.resultCode}'),
        for (final diagnostic in outcome.diagnostics)
          Text('${diagnostic.code}: ${diagnostic.message}'),
      ],
    );
  }
}
