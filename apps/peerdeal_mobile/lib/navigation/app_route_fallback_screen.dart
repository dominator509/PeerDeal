import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

class AppRouteFallbackScreen extends StatelessWidget {
  const AppRouteFallbackScreen({super.key, this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final name = _safeRouteName(routeName);
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

  static String? _safeRouteName(String? routeName) {
    final value = routeName;
    if (value == null) {
      return null;
    }
    final publicPath = value.split(RegExp(r'[?#]')).first;
    final normalized = publicPath
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    if (lower.contains('secret') ||
        lower.contains('token') ||
        lower.contains('password') ||
        normalized.contains('\\')) {
      return null;
    }
    const maxLength = 80;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }
}
