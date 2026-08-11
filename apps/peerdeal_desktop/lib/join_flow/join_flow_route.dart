import 'dart:async';

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
typedef JoinFlowReadyHandler =
    void Function(BuildContext context, ResolvedInvite resolvedInvite);
typedef JoinFlowSessionReadyHandler =
    void Function(BuildContext context, JoinFlowSessionContext sessionContext);

const int _maxJoinDiagnostics = 4;

class JoinFlowRoute extends StatefulWidget {
  const JoinFlowRoute({
    super.key,
    this.initialMode = JoinFlowDemoMode.firstJoin,
    Set<JoinFlowDemoMode>? enabledModes,
    required JoinFlowOrchestratorFactory orchestratorFactory,
    JoinFlowInviteContextFactory? inviteContextFactory,
    this.onJoinReady,
    this.onSessionReady,
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
  final JoinFlowReadyHandler? onJoinReady;
  final JoinFlowSessionReadyHandler? onSessionReady;

  @override
  State<JoinFlowRoute> createState() => _JoinFlowRouteState();
}

class _JoinFlowRouteState extends State<JoinFlowRoute> {
  late JoinFlowDemoMode _mode;
  late Future<JoinFlowOutcome> _outcome;
  Completer<void>? _cancellation;
  int _outcomeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _outcome = _startOutcome(_mode);
    _observeOutcome(_outcome);
  }

  @override
  void didUpdateWidget(JoinFlowRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode ||
        oldWidget._orchestratorFactory != widget._orchestratorFactory ||
        oldWidget._inviteContextFactory != widget._inviteContextFactory ||
        oldWidget._enabledModes != widget._enabledModes) {
      _mode = widget.initialMode;
      _outcome = _startOutcome(_mode);
      _observeOutcome(_outcome);
    } else if (oldWidget.onJoinReady != widget.onJoinReady ||
        oldWidget.onSessionReady != widget.onSessionReady) {
      _observeOutcome(_outcome);
    }
  }

  @override
  void dispose() {
    _cancelActiveRun();
    _outcomeGeneration += 1;
    super.dispose();
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

  Future<JoinFlowOutcome> _run(
    JoinFlowDemoMode mode, {
    required Future<void> cancellation,
  }) async {
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
          ? await orchestrator.runRejoin(context, cancellation: cancellation)
          : await orchestrator.runFirstJoin(
              context,
              cancellation: cancellation,
            );
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
    final outcome = _startOutcome(mode);
    setState(() {
      _mode = mode;
      _outcome = outcome;
    });
    _observeOutcome(outcome);
  }

  Future<JoinFlowOutcome> _startOutcome(JoinFlowDemoMode mode) {
    _cancelActiveRun();
    final cancellation = Completer<void>();
    _cancellation = cancellation;
    return _run(mode, cancellation: cancellation.future);
  }

  void _cancelActiveRun() {
    final cancellation = _cancellation;
    if (cancellation != null && !cancellation.isCompleted) {
      cancellation.complete();
    }
  }

  bool _isModeEnabled(JoinFlowDemoMode mode) {
    return widget._enabledModes.contains(mode);
  }

  void _observeOutcome(Future<JoinFlowOutcome> outcome) {
    final generation = ++_outcomeGeneration;
    outcome.then((rawOutcome) {
      if (!mounted || generation != _outcomeGeneration) return;

      final safeOutcome = _safeJoinOutcome(rawOutcome);
      final resolvedInvite = safeOutcome.resolvedInvite;
      final sessionContext = safeOutcome.sessionContext;
      final handler = widget.onJoinReady;
      final sessionHandler = widget.onSessionReady;
      if ((handler == null || resolvedInvite == null) &&
          (sessionHandler == null || sessionContext == null)) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _outcomeGeneration) return;
        if (sessionHandler != null && sessionContext != null) {
          try {
            sessionHandler(context, sessionContext);
          } on Object {
            // Product navigation is optional; a failed handoff must not
            // expose raw callback errors through the join surface.
          }
        }
        if (handler != null && resolvedInvite != null) {
          try {
            handler(context, resolvedInvite);
          } on Object {
            // Product navigation is optional; a failed handoff must not
            // expose raw callback errors through the join surface.
          }
        }
      });
    });
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
    diagnostics: _safeJoinDiagnostics(outcome.diagnostics),
    message: _isSafeJoinMessage(outcome.message) ? outcome.message : null,
    resolvedInvite: _safeResolvedInvite(outcome),
    sessionContext: _safeSessionContext(outcome),
  );
}

JoinFlowSessionContext? _safeSessionContext(JoinFlowOutcome outcome) {
  final invite = _safeResolvedInvite(outcome);
  final context = outcome.sessionContext;
  if (invite == null || context == null) return null;
  if (context.invite.inviteId != invite.inviteId ||
      context.invite.tableId != invite.tableId ||
      context.invite.sessionId != invite.sessionId ||
      !_isSafeJoinIdentity(context.remotePeerId) ||
      context.localSeat < 1) {
    return null;
  }
  return JoinFlowSessionContext(
    invite: invite,
    remotePeerId: context.remotePeerId,
    localSeat: context.localSeat,
  );
}

ResolvedInvite? _safeResolvedInvite(JoinFlowOutcome outcome) {
  final isAccepted =
      (outcome.state == JoinFlowState.joined &&
          outcome.status == JoinDecisionStatus.okJoined) ||
      (outcome.state == JoinFlowState.rejoined &&
          outcome.status == JoinDecisionStatus.okRejoined);
  final invite = outcome.resolvedInvite;
  if (!isAccepted || invite == null) return null;
  if (!_isSafeJoinIdentity(invite.inviteId) ||
      !_isSafeJoinIdentity(invite.tableId) ||
      !_isSafeJoinIdentity(invite.sessionId) ||
      !_isSafeJoinIdentity(invite.modeType) ||
      !_isSafeJoinIdentity(invite.protocolVersion)) {
    return null;
  }
  return invite;
}

bool _isSafeJoinIdentity(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 160) {
    return false;
  }
  return value.codeUnits.every(
    (codeUnit) => codeUnit > 0x20 && codeUnit != 0x7F,
  );
}

List<ProtocolDiagnostic> _safeJoinDiagnostics(
  List<ProtocolDiagnostic> diagnostics,
) {
  final safeDiagnostics = diagnostics
      .take(_maxJoinDiagnostics)
      .map(_safeJoinDiagnostic)
      .toList(growable: false);
  if (diagnostics.length <= _maxJoinDiagnostics) {
    return safeDiagnostics;
  }

  return <ProtocolDiagnostic>[
    ...safeDiagnostics,
    const ProtocolDiagnostic(
      code: 'ERR_JOIN_DIAGNOSTICS_TRUNCATED',
      message: 'Join diagnostics were truncated.',
    ),
  ];
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
