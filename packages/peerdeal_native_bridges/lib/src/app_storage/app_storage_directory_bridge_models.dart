class AppStorageDirectorySnapshot {
  const AppStorageDirectorySnapshot({
    required this.available,
    required this.directoryPath,
    this.warning,
  });

  const AppStorageDirectorySnapshot.unavailable({this.warning})
    : available = false,
      directoryPath = null;

  final bool available;
  final String? directoryPath;
  final String? warning;
}
