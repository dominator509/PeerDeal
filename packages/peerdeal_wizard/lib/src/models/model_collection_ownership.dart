Object? freezeWizardValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = freezeWizardValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(freezeWizardValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(freezeWizardValue));
  }
  return value;
}

Map<String, Object?> freezeWizardObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries)
      entry.key: freezeWizardValue(entry.value),
  });
}
