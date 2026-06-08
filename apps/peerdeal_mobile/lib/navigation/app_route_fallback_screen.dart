import 'package:flutter/widgets.dart';

class AppRouteFallbackScreen extends StatelessWidget {
  const AppRouteFallbackScreen({super.key, this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final name = routeName;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Route unavailable'),
          const SizedBox(height: 16),
          const Text('State: rejected'),
          const Text('Result: ERR_ROUTE_UNAVAILABLE'),
          if (name != null && name.isNotEmpty) Text('Route: $name'),
        ],
      ),
    );
  }
}
