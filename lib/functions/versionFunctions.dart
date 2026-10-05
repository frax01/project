/// True if [installed] is older than [latest] (both "major.minor.patch").
/// Used for the "update the app" dialog: it must not appear for a build that
/// is newer than the one published (TestFlight, store review). An empty
/// [latest] never blocks, and a build suffix ("3.0.7+307") is ignored.
bool isVersionOlder(String installed, String latest) {
  if (latest.trim().isEmpty) return false;
  final List<int> a = _parts(installed);
  final List<int> b = _parts(latest);
  final int length = a.length > b.length ? a.length : b.length;
  for (int i = 0; i < length; i++) {
    final int x = i < a.length ? a[i] : 0;
    final int y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}

List<int> _parts(String version) => version
    .split('+')
    .first
    .trim()
    .split('.')
    .map((p) => int.tryParse(p) ?? 0)
    .toList();
