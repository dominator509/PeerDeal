import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../transport/app_table_session_transport_provisioner.dart';
import '../transport/app_table_session_transport_source.dart';
import '../transport/app_table_session_transport_source_mount.dart';
import '../transport/native_transport_session_factory.dart';
import 'app_holdem_production_session_snapshot_coordinator.dart';
import 'app_holdem_table_session_runtime.dart';
import 'app_holdem_table_session_transport_publisher.dart';

typedef AppHoldemTableSessionSurfaceBuilder =
    Widget Function(
      BuildContext context,
      AppHoldemTableSessionRouteContext routeContext,
    );

class AppHoldemTableSessionRouteContext {
  const AppHoldemTableSessionRouteContext({
    required this.runtime,
    required this.transport,
    required this.peerId,
    required this.refresh,
    this.snapshotCoordinator,
  });

  final AppHoldemTableSessionRuntime runtime;
  final AppTableSessionTransportProvisionResult transport;
  final String peerId;
  final VoidCallback refresh;
  final AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator;

  AppHoldemProjectionTransportPublisher? createProjectionPublisher({
    required String localPeerId,
  }) {
    final session = transport.session;
    if (session == null) return null;
    return AppHoldemProjectionTransportPublisher(
      sender: session.sender,
      localPeerId: localPeerId,
      remotePeerId: peerId,
    );
  }
}

/// Composes an injected, validated Hold'em runtime with app-owned transport
/// provisioning for a non-demo production route.
class AppHoldemTableSessionRoute extends StatefulWidget {
  const AppHoldemTableSessionRoute({
    super.key,
    required this.runtime,
    required this.peerId,
    required this.surfaceBuilder,
    this.nativeSessionFactory,
    this.snapshotCoordinator,
    this.pollInterval = const Duration(seconds: 1),
    this.timerFactory,
  });

  final AppHoldemTableSessionRuntime runtime;
  final String peerId;
  final AppHoldemTableSessionSurfaceBuilder surfaceBuilder;
  final NativeTransportSessionFactory? nativeSessionFactory;
  final AppHoldemProductionSessionSnapshotCoordinator? snapshotCoordinator;
  final Duration pollInterval;
  final NativeTransportSourceTimerFactory? timerFactory;

  @override
  State<AppHoldemTableSessionRoute> createState() =>
      _AppHoldemTableSessionRouteState();
}

class _AppHoldemTableSessionRouteState
    extends State<AppHoldemTableSessionRoute> {
  late Completer<void> _transportCancellation;
  late Future<AppTableSessionTransportProvisionResult> _transportFuture;
  int _lifecycleGeneration = 0;

  @override
  void initState() {
    super.initState();
    _transportCancellation = Completer<void>();
    _transportFuture = _loadTransport();
  }

  @override
  void didUpdateWidget(AppHoldemTableSessionRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime == widget.runtime &&
        oldWidget.peerId == widget.peerId &&
        oldWidget.nativeSessionFactory == widget.nativeSessionFactory &&
        oldWidget.snapshotCoordinator == widget.snapshotCoordinator &&
        oldWidget.pollInterval == widget.pollInterval &&
        oldWidget.timerFactory == widget.timerFactory) {
      return;
    }
    _lifecycleGeneration += 1;
    _cancelTransportLoad();
    _transportCancellation = Completer<void>();
    _transportFuture = _loadTransport();
  }

  @override
  void dispose() {
    _lifecycleGeneration += 1;
    _cancelTransportLoad();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppTableSessionTransportProvisionResult>(
      future: _transportFuture,
      builder: (context, snapshot) {
        final transport = snapshot.data ?? _unavailableTransport(snapshot);
        return _buildSurface(context, transport);
      },
    );
  }

  Future<AppTableSessionTransportProvisionResult> _loadTransport() {
    final lifecycleGeneration = _lifecycleGeneration;
    final runtime = widget.runtime;
    final coordinator = widget.snapshotCoordinator;
    return AppTableSessionTransportProvisioner(
      runtime: runtime.sessionRuntime,
      holdemRuntime: runtime,
      nativeSessionFactory: widget.nativeSessionFactory,
      pollInterval: widget.pollInterval,
      timerFactory: widget.timerFactory,
      cancellation: _transportCancellation.future,
      onEventAccepted: (_) {
        final acceptedEvent = runtime.sessionRuntime.lastAcceptedEvent;
        unawaited(
          _checkpointAcceptedEvent(
            lifecycleGeneration: lifecycleGeneration,
            runtime: runtime,
            coordinator: coordinator,
            acceptedEvent: acceptedEvent,
          ),
        );
        if (_isCurrentLifecycle(lifecycleGeneration)) setState(() {});
      },
    ).load(peerId: widget.peerId);
  }

  Future<void> _checkpointAcceptedEvent({
    required int lifecycleGeneration,
    required AppHoldemTableSessionRuntime runtime,
    required AppHoldemProductionSessionSnapshotCoordinator? coordinator,
    required EventEnvelope? acceptedEvent,
  }) async {
    if (coordinator == null) return;
    if (acceptedEvent == null) return;
    if (!_isCurrentLifecycle(lifecycleGeneration)) return;

    if (acceptedEvent.eventType == 'SessionClosed' ||
        acceptedEvent.eventType == 'SessionWiped') {
      await coordinator.discardPending();
    } else {
      await coordinator.persist(
        tableState: runtime.coreState,
        handState: runtime.handState,
        eventCursor: runtime.cursor,
        events: <EventEnvelope>[acceptedEvent],
      );
    }
    if (_isCurrentLifecycle(lifecycleGeneration)) setState(() {});
  }

  bool _isCurrentLifecycle(int lifecycleGeneration) {
    return mounted && lifecycleGeneration == _lifecycleGeneration;
  }

  void _cancelTransportLoad() {
    if (!_transportCancellation.isCompleted) {
      _transportCancellation.complete();
    }
  }

  Widget _buildSurface(
    BuildContext context,
    AppTableSessionTransportProvisionResult transport,
  ) {
    final routeContext = AppHoldemTableSessionRouteContext(
      runtime: widget.runtime,
      transport: transport,
      peerId: widget.peerId,
      snapshotCoordinator: widget.snapshotCoordinator,
      refresh: () {
        if (mounted) setState(() {});
      },
    );

    final Widget surface;
    try {
      surface = widget.surfaceBuilder(context, routeContext);
    } on Object {
      return const _AppHoldemTableSessionRouteUnavailable();
    }

    final source = transport.source;
    if (source == null) return surface;
    return AppTableSessionTransportSourceMount(source: source, child: surface);
  }

  AppTableSessionTransportProvisionResult _unavailableTransport(
    AsyncSnapshot<AppTableSessionTransportProvisionResult> snapshot,
  ) {
    if (snapshot.hasError) {
      return const AppTableSessionTransportProvisionResult.unavailable(
        warnings: <String>['Production table transport unavailable.'],
      );
    }
    return const AppTableSessionTransportProvisionResult.unavailable();
  }
}

class _AppHoldemTableSessionRouteUnavailable extends StatelessWidget {
  const _AppHoldemTableSessionRouteUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Production table route unavailable'));
  }
}
