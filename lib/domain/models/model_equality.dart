/// Value equality helpers for the domain models.
///
/// The models are plain Dart (no code generation), so they compare collections
/// element by element instead of by identity. These helpers are internal to the
/// domain layer and are not exported from `models.dart`.
library;

/// Element-wise equality for two nullable lists.
bool listsEqual<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Element-wise equality for two nullable sets.
bool setsEqual<T>(Set<T>? a, Set<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  return a.containsAll(b);
}

/// Key/value equality for two nullable maps.
bool mapsEqual<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final MapEntry<K, V> entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

/// Order-independent hash for a nullable list.
int listsHash<T>(List<T>? list) => list == null ? 0 : Object.hashAll(list);

/// Order-independent hash for a nullable set.
int setsHash<T>(Set<T>? set) => set == null ? 0 : Object.hashAllUnordered(set);

/// Order-independent hash for a nullable map.
int mapsHash<K, V>(Map<K, V>? map) =>
    map == null ? 0 : Object.hashAllUnordered(map.entries);
