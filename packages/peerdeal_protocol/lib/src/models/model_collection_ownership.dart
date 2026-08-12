Object? freezeProtocolValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = freezeProtocolValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(freezeProtocolValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(freezeProtocolValue));
  }
  return value;
}

Map<String, Object?> freezeProtocolObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries)
      entry.key: freezeProtocolValue(entry.value),
  });
}
