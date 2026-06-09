import 'safe_surface_capture_plan.dart';

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
    Iterable<SafeSurfaceCapturePlan?> plans,
  ) {
    final activePlans = plans.nonNulls.toList(growable: false);
    return SafeSurfaceRenderModel(
      shouldObscure: activePlans.any((plan) => plan.shouldObscure),
      shouldRequestNativeBlocking: activePlans.any(
        (plan) => plan.shouldRequestNativeBlocking,
      ),
      warnings: List<String>.unmodifiable(
        _uniqueNonEmpty(
          activePlans.map(
            (plan) => _safeRenderText(
              plan.warning,
              fallback: 'Capture warning unavailable.',
            ),
          ),
        ),
      ),
      nativeNotes: List<String>.unmodifiable(
        _uniqueNonEmpty(
          activePlans.map(
            (plan) => _safeRenderText(plan.nativeNotes, fallback: null),
          ),
        ),
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

  static String? _safeRenderText(String? value, {required String? fallback}) {
    final normalized = value
        ?.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final lower = normalized.toLowerCase();
    if (lower.contains('secret') ||
        lower.contains('token') ||
        lower.contains('password') ||
        normalized.contains('\\')) {
      return fallback;
    }
    const maxLength = 96;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }
}
