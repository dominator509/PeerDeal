import 'package:flutter/widgets.dart';

import 'demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'demo_slice/controllers/demo_slice_controller.dart';
import 'demo_slice/demo_slice_routes.dart';
import 'demo_slice/models/demo_scenario_snapshot.dart';
import 'demo_slice/models/demo_view_models.dart';
import 'demo_slice/screens/demo_chat_screen.dart';
import 'demo_slice/screens/demo_home_screen.dart';
import 'demo_slice/screens/demo_receipt_screen.dart';
import 'demo_slice/screens/demo_table_screen.dart';

void main() {
  runApp(const PeerDealMobileApp());
}

class PeerDealMobileApp extends StatelessWidget {
  const PeerDealMobileApp({super.key, DemoReceiptSurfacePresenter? presenter})
    : _receiptPresenter = presenter;

  final DemoReceiptSurfacePresenter? _receiptPresenter;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'PeerDeal Mobile',
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
        Navigator.defaultRouteName: _buildHome,
        DemoSliceRoutes.home: _buildHome,
        DemoSliceRoutes.table: (context) => DemoTableScreen(
          snapshot: _demoTableSnapshot,
          onOpenChat: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
          onOpenReceipt: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
        ),
        DemoSliceRoutes.chat: (context) => DemoChatScreen(
          snapshot: _demoChatSnapshot,
          onOpenTable: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.table),
        ),
        DemoSliceRoutes.receipt: (_) => DemoReceiptRoute(
          snapshot: _demoReceiptSnapshot,
          presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
        ),
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return DemoHomeScreen(
      controller: DemoSliceController(),
      onOpenTable: () => Navigator.of(context).pushNamed(DemoSliceRoutes.table),
      onOpenChat: () => Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
      onOpenReceipt: () =>
          Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
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

const _demoTableSnapshot = DemoScenarioSnapshot(
  scenarioId: 'open_table_live_turn',
  mode: 'open_table',
  variant: 'holdem_nlhe',
  networkConfidence: 'stable',
  statusBanner: DemoStatusBannerVm(visible: false, label: '', severity: 'none'),
  chat: DemoChatSummaryVm(unreadCount: 3, disappearingEnabled: true),
  receipt: DemoReceiptSummaryVm(
    verificationState: 'verified',
    retentionMode: 'manual_wipe_allowed',
    bindingMode: 'session_bound',
  ),
);

const _demoChatSnapshot = DemoScenarioSnapshot(
  scenarioId: 'chat_heavy_table',
  mode: 'open_table',
  variant: 'holdem_nlhe',
  networkConfidence: 'stable',
  statusBanner: DemoStatusBannerVm(visible: false, label: '', severity: 'none'),
  chat: DemoChatSummaryVm(unreadCount: 19, disappearingEnabled: true),
  receipt: DemoReceiptSummaryVm(
    verificationState: 'partial',
    retentionMode: 'manual_wipe_allowed',
    bindingMode: 'session_bound',
  ),
);
