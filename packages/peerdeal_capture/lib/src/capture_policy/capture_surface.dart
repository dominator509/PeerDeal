enum CaptureSurface {
  lobby,
  table,
  privateLedger,
  receiptDetail,
  receiptImportExportPreview,
  verificationDrillDown,
  restore,
  statsHistory,
}

extension CaptureSurfaceSensitivity on CaptureSurface {
  bool get isAlwaysSensitive => switch (this) {
    CaptureSurface.privateLedger ||
    CaptureSurface.receiptDetail ||
    CaptureSurface.receiptImportExportPreview ||
    CaptureSurface.verificationDrillDown ||
    CaptureSurface.restore ||
    CaptureSurface.statsHistory => true,
    CaptureSurface.lobby || CaptureSurface.table => false,
  };
}
