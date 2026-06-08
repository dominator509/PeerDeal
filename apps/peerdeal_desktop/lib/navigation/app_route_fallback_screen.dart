import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

class AppRouteFallbackScreen extends StatelessWidget {
  const AppRouteFallbackScreen({super.key, this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final name = routeName;
    return PeerDealAppScaffold(
      title: 'Route unavailable',
      subtitle: 'Rejected navigation request',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PeerDealStatusPill(label: 'Rejected', severity: 'error'),
          const SizedBox(height: 12),
          const Text('State: rejected'),
          const Text('Result: ERR_ROUTE_UNAVAILABLE'),
          if (name != null && name.isNotEmpty) Text('Route: $name'),
        ],
      ),
    );
  }
}
