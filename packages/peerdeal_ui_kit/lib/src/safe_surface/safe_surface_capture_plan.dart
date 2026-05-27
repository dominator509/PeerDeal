abstract interface class SafeSurfaceCapturePlan {
  bool get shouldObscure;
  bool get shouldRequestNativeBlocking;
  String? get warning;
  String get nativeNotes;
}
