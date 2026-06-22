class ContestEntry {
  final String name;
  final String email;
  final String? nickname;
  final int timeSeconds;

  const ContestEntry({
    required this.name,
    required this.email,
    this.nickname,
    required this.timeSeconds,
  });

  String get displayName {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    return name;
  }

  String get formattedTime {
    final m = timeSeconds ~/ 60;
    final s = timeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
