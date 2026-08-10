import 'package:flutter/widgets.dart';

import '../transport/app_table_session_transport_provisioner.dart';
import '../transport/app_table_session_transport_source.dart';
import '../transport/app_table_session_transport_source_mount.dart';
import '../transport/native_transport_session_factory.dart';
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
  });

  final AppHoldemTableSessionRuntime runtime;
  final AppTableSessionTransportProvisionResult transport;
  final String peerId;
  final VoidCallback refresh;

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
    this.pollInterval = const Duration(seconds: 1),
    this.timerFactory,
  });

  final AppHoldemTableSessionRuntime runtime;
  final String peerId;
  final AppHoldemTableSessionSurfaceBuilder surfaceBuilder;
  final NativeTransportSessionFactory? nativeSessionFactory;
  final Duration pollInterval;
  final NativeTransportSourceTimerFactory? timerFactory;

  @override
  State<AppHoldemTableSessionRoute> createState() =>
      _AppHoldemTableSessionRouteState();
}

class _AppHoldemTableSessionRouteState
    extends State<AppHoldemTableSessionRoute> {
  late Future<AppTableSessionTransportProvisionResult> _transportFuture;

  @override
  void initState() {
    super.initState();
    _transportFuture = _loadTransport();
  }

  @override
  void didUpdateWidget(AppHoldemTableSessionRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.runtime == widget.runtime &&
        oldWidget.peerId == widget.peerId &&
        oldWidget.nativeSessionFactory == widget.nativeSessionFactory &&
        oldWidget.pollInterval == widget.pollInterval &&
        oldWidget.timerFactory == widget.timerFactory) {
      return;
    }
    _transportFuture = _loadTransport();
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
    return AppTableSessionTransportProvisioner(
      runtime: widget.runtime.sessionRuntime,
      holdemRuntime: widget.runtime,
      nativeSessionFactory: widget.nativeSessionFactory,
      pollInterval: widget.pollInterval,
      timerFactory: widget.timerFactory,
      onEventAccepted: (_) {
        if (mounted) setState(() {});
      },
    ).load(peerId: widget.peerId);
  }

  Widget _buildSurface(
    BuildContext context,
    AppTableSessionTransportProvisionResult transport,
  ) {
    final routeContext = AppHoldemTableSessionRouteContext(
      runtime: widget.runtime,
      transport: transport,
      peerId: widget.peerId,
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
