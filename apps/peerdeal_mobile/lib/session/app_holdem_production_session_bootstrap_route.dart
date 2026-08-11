import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../join_flow/join_flow_models.dart';
import '../navigation/app_route_fallback_screen.dart';
import 'app_holdem_production_session_bootstrap.dart';
import 'app_holdem_production_session_factory.dart';

/// Mounts a production Hold'em route from a product-owned resolved invite.
///
/// The bootstrap still owns correlation checks, while its source owns durable
/// state hydration and local identity. This adapter only turns the validated
/// composition into the existing app route surface.
class AppHoldemProductionSessionBootstrapRoute extends StatefulWidget {
  const AppHoldemProductionSessionBootstrapRoute({
    super.key,
    required this.bootstrap,
    required this.invite,
    this.sessionContext,
    this.routeName,
  });

  /// Creates a route builder for production route maps that pass a
  /// [ResolvedInvite] or [JoinFlowSessionContext] through route arguments.
  static WidgetBuilder fromRouteSettings({
    required AppHoldemProductionSessionBootstrap bootstrap,
  }) {
    return (context) {
      final settings = ModalRoute.of(context)?.settings;
      final argument = settings?.arguments;
      final JoinFlowSessionContext? sessionContext =
          argument is JoinFlowSessionContext ? argument : null;
      final ResolvedInvite? invite = argument is ResolvedInvite
          ? argument
          : sessionContext?.invite;
      if (invite == null) {
        return AppRouteFallbackScreen(routeName: settings?.name);
      }
      return AppHoldemProductionSessionBootstrapRoute(
        bootstrap: bootstrap,
        invite: invite,
        sessionContext: sessionContext,
        routeName: settings?.name,
      );
    };
  }

  final AppHoldemProductionSessionBootstrap bootstrap;
  final ResolvedInvite invite;
  final JoinFlowSessionContext? sessionContext;
  final String? routeName;

  @override
  State<AppHoldemProductionSessionBootstrapRoute> createState() =>
      _AppHoldemProductionSessionBootstrapRouteState();
}

class _AppHoldemProductionSessionBootstrapRouteState
    extends State<AppHoldemProductionSessionBootstrapRoute> {
  late Future<AppHoldemProductionSessionComposition> _composition;
  late Completer<void> _sourceCancellation;

  @override
  void initState() {
    super.initState();
    _sourceCancellation = Completer<void>();
    _composition = _loadComposition();
  }

  @override
  void didUpdateWidget(AppHoldemProductionSessionBootstrapRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bootstrap == widget.bootstrap &&
        oldWidget.invite == widget.invite &&
        oldWidget.sessionContext == widget.sessionContext &&
        oldWidget.routeName == widget.routeName) {
      return;
    }
    _cancelSourceLoad();
    _sourceCancellation = Completer<void>();
    _composition = _loadComposition();
  }

  @override
  void dispose() {
    _cancelSourceLoad();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppHoldemProductionSessionComposition>(
      future: _composition,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PeerDealAppScaffold(
            title: 'Opening table',
            subtitle: 'Loading production session',
            child: Text('Loading table'),
          );
        }
        final composition = snapshot.data;
        if (composition == null ||
            (widget.routeName != null &&
                composition.route.path != widget.routeName)) {
          return AppRouteFallbackScreen(routeName: widget.routeName);
        }

        try {
          return composition.route.builder(context);
        } on Object {
          return AppRouteFallbackScreen(routeName: widget.routeName);
        }
      },
    );
  }

  Future<AppHoldemProductionSessionComposition> _loadComposition() {
    final sessionContext = widget.sessionContext;
    if (sessionContext != null) {
      return widget.bootstrap.createForSessionContext(
        sessionContext,
        cancellation: _sourceCancellation.future,
      );
    }
    return widget.bootstrap.createForInvite(
      widget.invite,
      cancellation: _sourceCancellation.future,
    );
  }

  void _cancelSourceLoad() {
    if (!_sourceCancellation.isCompleted) {
      _sourceCancellation.complete();
    }
  }
}
