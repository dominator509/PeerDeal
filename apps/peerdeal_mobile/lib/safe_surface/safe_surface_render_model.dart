import 'capture_surface_coordinator.dart';

class SafeSurfaceRenderModel {
  const SafeSurfaceRenderModel({
    required this.shouldObscure,
    required this.shouldRequestNativeBlocking,
    required this.warnings,
    required this.nativeNotes,
  });

  final bool shouldObscure;
  final bool shouldRequestNativeBlocking;
  final List<String> warnings;
  final List<String> nativeNotes;

  factory SafeSurfaceRenderModel.fromCapturePlans(
    Iterable<CaptureSurfacePlan?> plans,
  ) {
    final activePlans = plans.nonNulls.toList(growable: false);
    return SafeSurfaceRenderModel(
      shouldObscure: activePlans.any((plan) => plan.shouldObscure),
      shouldRequestNativeBlocking: activePlans.any(
        (plan) => plan.shouldRequestNativeBlocking,
      ),
      warnings: List<String>.unmodifiable(
        _uniqueNonEmpty(activePlans.map((plan) => plan.warning)),
      ),
      nativeNotes: List<String>.unmodifiable(
        _uniqueNonEmpty(activePlans.map((plan) => plan.nativeNotes)),
      ),
    );
  }

  static Iterable<String> _uniqueNonEmpty(Iterable<String?> values) sync* {
    final seen = <String>{};
    for (final value in values) {
      if (value == null || value.isEmpty || !seen.add(value)) {
        continue;
      }
      yield value;
    }
  }
}
