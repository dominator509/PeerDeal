import 'package:flutter/widgets.dart';

import 'demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'demo_slice/controllers/demo_slice_controller.dart';
import 'demo_slice/demo_slice_routes.dart';
import 'demo_slice/models/demo_scenario_snapshot.dart';
import 'demo_slice/models/demo_view_models.dart';
import 'demo_slice/screens/demo_receipt_screen.dart';

void main() {
  runApp(const PeerDealDesktopApp());
}

class PeerDealDesktopApp extends StatelessWidget {
  const PeerDealDesktopApp({super.key, DemoReceiptSurfacePresenter? presenter})
    : _receiptPresenter = presenter;

  final DemoReceiptSurfacePresenter? _receiptPresenter;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'PeerDeal Desktop',
      color: const Color(0xFF1B5E20),
      initialRoute: DemoSliceRoutes.home,
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
        );
      },
      routes: <String, WidgetBuilder>{
        Navigator.defaultRouteName: (_) =>
            _DemoHomeRoute(controller: DemoSliceController()),
        DemoSliceRoutes.home: (_) =>
            _DemoHomeRoute(controller: DemoSliceController()),
        DemoSliceRoutes.table: (_) => const _DemoTextRoute(
          title: 'Demo table',
          body: 'Scenario table shell mounted.',
        ),
        DemoSliceRoutes.chat: (_) => const _DemoTextRoute(
          title: 'Demo chat',
          body: 'Scenario chat shell mounted.',
        ),
        DemoSliceRoutes.receipt: (_) => DemoReceiptRoute(
          snapshot: _demoReceiptSnapshot,
          presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
        ),
      },
    );
  }
}

class _DemoHomeRoute extends StatelessWidget {
  const _DemoHomeRoute({required this.controller});

  final DemoSliceController controller;

  @override
  Widget build(BuildContext context) {
    final scenarios = controller.scenarios;
    return _RouteFrame(
      title: 'PeerDeal demo',
      children: <Widget>[
        Text('Active scenario: ${controller.activeScenario.title}'),
        for (final scenario in scenarios) Text(scenario.title),
        _RouteLink(label: 'Table', routeName: DemoSliceRoutes.table),
        _RouteLink(label: 'Chat', routeName: DemoSliceRoutes.chat),
        _RouteLink(label: 'Receipt', routeName: DemoSliceRoutes.receipt),
      ],
    );
  }
}

class _DemoTextRoute extends StatelessWidget {
  const _DemoTextRoute({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _RouteFrame(
      title: title,
      children: <Widget>[
        Text(body),
        _RouteLink(label: 'Home', routeName: DemoSliceRoutes.home),
      ],
    );
  }
}

class _RouteFrame extends StatelessWidget {
  const _RouteFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _RouteLink extends StatelessWidget {
  const _RouteLink({required this.label, required this.routeName});

  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label),
      ),
    );
  }
}

const _demoReceiptSnapshot = DemoScenarioSnapshot(
  scenarioId: 'verification_receipt_review',
  mode: 'open_table',
  variant: 'holdem_nlhe',
  networkConfidence: 'stable',
  statusBanner: DemoStatusBannerVm(visible: false, label: '', severity: 'none'),
  chat: DemoChatSummaryVm(unreadCount: 0, disappearingEnabled: false),
  receipt: DemoReceiptSummaryVm(
    verificationState: 'verified',
    retentionMode: 'strict_ephemeral',
    bindingMode: 'user_bound',
  ),
);
