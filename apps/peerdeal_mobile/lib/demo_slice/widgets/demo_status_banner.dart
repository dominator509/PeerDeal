import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../models/demo_view_models.dart';

class DemoStatusBanner extends StatelessWidget {
  const DemoStatusBanner({super.key, required this.vm});

  final DemoStatusBannerVm vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.visible) {
      return const SizedBox.shrink();
    }

    return PeerDealStatusPill(
      label: '${vm.severity}: ${vm.label}',
      severity: vm.severity,
    );
  }
}
