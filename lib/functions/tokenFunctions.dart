Iterable<String> _tokensOfEntry(dynamic entry) {
  if (entry is String) return entry.isEmpty ? const [] : [entry];
  if (entry is Map) {
    return entry.values.whereType<String>().where((t) => t.isNotEmpty);
  }
  return const [];
}

/// Stores this device's token under [deviceKey]. Entries of the user's other
/// devices are kept; an older entry of the same device (same key, or the same
/// token under a legacy key or as a plain string) is replaced. A null token
/// leaves the list unchanged.
List<dynamic> upsertDeviceToken(
    List<dynamic> tokens, String deviceKey, String? token) {
  if (token == null || token.isEmpty) return tokens;
  final List<dynamic> result = tokens.where((entry) {
    if (entry is Map && entry.containsKey(deviceKey)) return false;
    return !_tokensOfEntry(entry).contains(token);
  }).toList();
  result.add({deviceKey: token});
  return result;
}

/// Removes every entry holding [token] (used at logout).
List<dynamic> removeDeviceToken(List<dynamic> tokens, String? token) {
  if (token == null || token.isEmpty) return tokens;
  return tokens
      .where((entry) => !_tokensOfEntry(entry).contains(token))
      .toList();
}
