Object? freezeCoreValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = freezeCoreValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(freezeCoreValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(freezeCoreValue));
  }
  return value;
}

Map<String, Object?> freezeCoreObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries) entry.key: freezeCoreValue(entry.value),
  });
}
