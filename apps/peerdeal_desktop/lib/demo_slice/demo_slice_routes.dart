class DemoSliceRoutes {
  static const home = '/demo';
  static const table = '/demo/table';
  static const chat = '/demo/chat';
  static const receipt = '/demo/receipt';
  static const join = '/demo/join';
  static const setup = '/demo/setup';

  static const homeRoute = DemoSliceRouteDefinition(
    path: home,
    label: 'Home',
    surface: 'Demo home',
  );
  static const tableRoute = DemoSliceRouteDefinition(
    path: table,
    label: 'Table',
    surface: 'Table',
  );
  static const chatRoute = DemoSliceRouteDefinition(
    path: chat,
    label: 'Chat',
    surface: 'Chat',
  );
  static const receiptRoute = DemoSliceRouteDefinition(
    path: receipt,
    label: 'Receipt',
    surface: 'Receipt',
  );
  static const joinRoute = DemoSliceRouteDefinition(
    path: join,
    label: 'Join',
    surface: 'Join flow',
  );
  static const setupRoute = DemoSliceRouteDefinition(
    path: setup,
    label: 'Setup',
    surface: 'Setup flow',
  );

  static const mountedRoutes = <DemoSliceRouteDefinition>[
    homeRoute,
    tableRoute,
    chatRoute,
    receiptRoute,
    joinRoute,
    setupRoute,
  ];

  static const primaryNavigation = <DemoSliceRouteDefinition>[
    tableRoute,
    chatRoute,
    receiptRoute,
    joinRoute,
    setupRoute,
  ];

  static DemoSliceRouteDefinition? tryByPath(String path) {
    for (final route in mountedRoutes) {
      if (route.path == path) return route;
    }
    return null;
  }
}

class DemoSliceRouteDefinition {
  const DemoSliceRouteDefinition({
    required this.path,
    required this.label,
    required this.surface,
  });

  final String path;
  final String label;
  final String surface;
}
