Object? freezeReceiptValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = freezeReceiptValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(freezeReceiptValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(freezeReceiptValue));
  }
  return value;
}

Map<String, Object?> freezeReceiptObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries)
      entry.key: freezeReceiptValue(entry.value),
  });
}
