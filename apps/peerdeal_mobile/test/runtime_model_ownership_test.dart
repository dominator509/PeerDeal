import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_route.dart';
import 'package:peerdeal_mobile/main.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_route.dart';

void main() {
  test('runtime snapshots route, mode, and readiness collections', () {
    final joinModes = <JoinFlowDemoMode>{JoinFlowDemoMode.firstJoin};
    final setupModes = <SetupFlowDemoMode>{SetupFlowDemoMode.buildReady};
    final enabledRoutes = <String>{'/home'};
    final productionRoutes = <String, WidgetBuilder>{
      '/table-live': (_) => const SizedBox.shrink(),
    };
    final productionNavigation = <PeerDealAppNavigationEntry>[
      const PeerDealAppNavigationEntry(
        label: 'Live table',
        path: '/table-live',
      ),
    ];
    final requiredRoutes = <String>{'/table-live'};

    final runtime = PeerDealMobileRuntime(
      joinFlowEnabledModes: joinModes,
      setupFlowEnabledModes: setupModes,
      enabledDemoRoutePaths: enabledRoutes,
      productionRoutes: productionRoutes,
      productionNavigation: productionNavigation,
      nativeReadinessRequiredRoutePaths: requiredRoutes,
    );

    joinModes.clear();
    setupModes.clear();
    enabledRoutes.clear();
    productionRoutes.clear();
    productionNavigation.clear();
    requiredRoutes.clear();

    expect(runtime.joinFlowEnabledModes, contains(JoinFlowDemoMode.firstJoin));
    expect(
      runtime.setupFlowEnabledModes,
      contains(SetupFlowDemoMode.buildReady),
    );
    expect(runtime.enabledDemoRoutePaths, contains('/home'));
    expect(runtime.productionRoutes, contains('/table-live'));
    expect(runtime.productionNavigation, hasLength(1));
    expect(runtime.nativeReadinessRequiredRoutePaths, contains('/table-live'));

    expect(
      () => runtime.joinFlowEnabledModes!.add(JoinFlowDemoMode.rejoin),
      throwsUnsupportedError,
    );
    expect(
      () => runtime.setupFlowEnabledModes!.add(SetupFlowDemoMode.invalid),
      throwsUnsupportedError,
    );
    expect(
      () => runtime.enabledDemoRoutePaths!.add('/chat'),
      throwsUnsupportedError,
    );
    expect(() => runtime.productionRoutes!.clear(), throwsUnsupportedError);
    expect(
      () => runtime.productionNavigation!.add(
        const PeerDealAppNavigationEntry(label: 'Chat', path: '/chat'),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => runtime.nativeReadinessRequiredRoutePaths!.add('/chat'),
      throwsUnsupportedError,
    );
  });

  test('withOverrides snapshots mutable collection overrides', () {
    final enabledRoutes = <String>{'/table-live'};
    final requiredRoutes = <String>{'/table-live'};

    final runtime = PeerDealMobileRuntime().withOverrides(
      enabledDemoRoutePaths: enabledRoutes,
      nativeReadinessRequiredRoutePaths: requiredRoutes,
    );

    enabledRoutes.clear();
    requiredRoutes.clear();

    expect(runtime.enabledDemoRoutePaths, contains('/table-live'));
    expect(runtime.nativeReadinessRequiredRoutePaths, contains('/table-live'));
  });
}
