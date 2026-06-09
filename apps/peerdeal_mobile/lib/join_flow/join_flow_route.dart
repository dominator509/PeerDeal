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
                _JoinOutcomeView(
                  outcome: _safeJoinOutcome(snapshot.requireData),
                ),
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
      final context = widget._inviteContextFactory(mode);
      final invalidContext = _invalidInviteContextOutcome(mode, context);
      if (invalidContext != null) return invalidContext;

      final orchestrator = widget._orchestratorFactory(mode);
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
  if (context.inviteCode.trim().isEmpty ||
      context.inviteCode.trim() != context.inviteCode) {
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
      (rejoinToken == null ||
          rejoinToken.trim().isEmpty ||
          rejoinToken.trim() != rejoinToken)) {
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

JoinFlowOutcome _safeJoinOutcome(JoinFlowOutcome outcome) {
  if (!_isSafeJoinToken(outcome.resultCode)) {
    return const JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.rejected,
      resultCode: 'ERR_JOIN_OUTCOME_INVALID',
      diagnostics: <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: 'ERR_JOIN_OUTCOME_INVALID',
          message: 'Join outcome is invalid.',
        ),
      ],
      message: 'Join outcome is invalid.',
    );
  }

  return JoinFlowOutcome(
    state: outcome.state,
    status: outcome.status,
    resultCode: outcome.resultCode,
    diagnostics: outcome.diagnostics
        .map(_safeJoinDiagnostic)
        .toList(growable: false),
    message: _isSafeJoinMessage(outcome.message) ? outcome.message : null,
  );
}

ProtocolDiagnostic _safeJoinDiagnostic(ProtocolDiagnostic diagnostic) {
  return ProtocolDiagnostic(
    code: _isSafeJoinToken(diagnostic.code)
        ? diagnostic.code
        : 'ERR_JOIN_DIAGNOSTIC_UNAVAILABLE',
    message: _isSafeJoinMessage(diagnostic.message)
        ? diagnostic.message
        : 'Join diagnostic unavailable.',
  );
}

bool _isSafeJoinToken(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 80) {
    return false;
  }
  return value.codeUnits.every(_isSafeJoinTokenCodeUnit);
}

bool _isSafeJoinTokenCodeUnit(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x2D ||
      codeUnit == 0x2E ||
      codeUnit == 0x5F;
}

bool _isSafeJoinMessage(String? value) {
  if (value == null) return true;
  if (value.trim() != value || value.isEmpty || value.length > 160) {
    return false;
  }
  final lower = value.toLowerCase();
  if (lower.contains('secret') || lower.contains('token')) return false;
  return value.codeUnits.every(
    (codeUnit) => codeUnit >= 0x20 && codeUnit != 0x5C && codeUnit != 0x7F,
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
