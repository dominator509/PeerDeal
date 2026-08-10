import 'package:flutter/widgets.dart';

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
    this.routeName,
  });

  /// Creates a route builder for production route maps that pass a
  /// [ResolvedInvite] through [RouteSettings.arguments].
  static WidgetBuilder fromRouteSettings({
    required AppHoldemProductionSessionBootstrap bootstrap,
  }) {
    return (context) {
      final settings = ModalRoute.of(context)?.settings;
      final invite = settings?.arguments;
      if (invite is! ResolvedInvite) {
        return AppRouteFallbackScreen(routeName: settings?.name);
      }
      return AppHoldemProductionSessionBootstrapRoute(
        bootstrap: bootstrap,
        invite: invite,
        routeName: settings?.name,
      );
    };
  }

  final AppHoldemProductionSessionBootstrap bootstrap;
  final ResolvedInvite invite;
  final String? routeName;

  @override
  State<AppHoldemProductionSessionBootstrapRoute> createState() =>
      _AppHoldemProductionSessionBootstrapRouteState();
}

class _AppHoldemProductionSessionBootstrapRouteState
    extends State<AppHoldemProductionSessionBootstrapRoute> {
  late Future<AppHoldemProductionSessionComposition> _composition;

  @override
  void initState() {
    super.initState();
    _composition = _loadComposition();
  }

  @override
  void didUpdateWidget(AppHoldemProductionSessionBootstrapRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bootstrap == widget.bootstrap &&
        oldWidget.invite == widget.invite &&
        oldWidget.routeName == widget.routeName) {
      return;
    }
    _composition = _loadComposition();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppHoldemProductionSessionComposition>(
      future: _composition,
      builder: (context, snapshot) {
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
    return widget.bootstrap.createForInvite(widget.invite);
  }
}
