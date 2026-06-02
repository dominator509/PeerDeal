import 'package:flutter/widgets.dart';

import '../models/demo_view_models.dart';

class DemoStatusBanner extends StatelessWidget {
  const DemoStatusBanner({super.key, required this.vm});

  final DemoStatusBannerVm vm;

  @override
  Widget build(BuildContext context) {
    if (!vm.visible) {
      return const SizedBox.shrink();
    }

    return Text('${vm.severity}: ${vm.label}');
  }
}
