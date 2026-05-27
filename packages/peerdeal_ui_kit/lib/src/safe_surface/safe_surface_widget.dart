import 'package:flutter/widgets.dart';

import 'safe_surface_render_model.dart';

class SafeSurface extends StatelessWidget {
  const SafeSurface({
    super.key,
    required this.model,
    required this.child,
    this.obscuredChild = const SizedBox.shrink(),
  });

  final SafeSurfaceRenderModel model;
  final Widget child;
  final Widget obscuredChild;

  @override
  Widget build(BuildContext context) {
    if (!model.shouldObscure) {
      return child;
    }

    return Semantics(
      container: true,
      label: 'Sensitive content hidden',
      child: ExcludeSemantics(child: obscuredChild),
    );
  }
}
