bool isNewerVersion(String latest, String current) {
  final a = _Version.tryParse(latest);
  final b = _Version.tryParse(current);
  if (a == null || b == null) return latest != current;
  return a.compareTo(b) > 0;
}

class _Version implements Comparable<_Version> {
  const _Version(this.core, this.suffix);

  final List<int> core;
  final String suffix;

  static final _pattern = RegExp(r'^[vV]?(\d+(?:\.\d+)*)([^+]*)(?:\+.*)?$');

  static _Version? tryParse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    final core = match.group(1)!.split('.').map(int.parse).toList();
    return _Version(core, match.group(2)!);
  }

  @override
  int compareTo(_Version other) {
    final length = core.length > other.core.length
        ? core.length
        : other.core.length;
    for (var i = 0; i < length; i++) {
      final a = i < core.length ? core[i] : 0;
      final b = i < other.core.length ? other.core[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    if (suffix.isEmpty && other.suffix.isEmpty) return 0;
    if (suffix.isEmpty) return 1;
    if (other.suffix.isEmpty) return -1;
    return suffix.compareTo(other.suffix);
  }
}
