class RankingEntry {
  final String id;
  final String displayName;
  final String avatarInitials;
  final String avatarColor;
  final int points;
  final double accuracy;
  final int streak;
  final int rank;
  final String? level;
  final int? rankVariation;

  const RankingEntry({
    required this.id,
    required this.displayName,
    required this.avatarInitials,
    required this.avatarColor,
    required this.points,
    required this.accuracy,
    required this.streak,
    required this.rank,
    this.level,
    this.rankVariation,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> j, int position) => RankingEntry(
    id:             j['id'] as String,
    displayName:    j['displayName'] as String? ?? j['display_name'] as String? ?? '',
    avatarInitials: j['avatarInitials'] as String? ?? j['avatar_initials'] as String? ?? 'U',
    avatarColor:    j['avatarColor'] as String? ?? j['avatar_color'] as String? ?? '#2563FF',
    points:         (j['points'] as num?)?.toInt() ?? 0,
    accuracy:       (j['accuracy'] as num?)?.toDouble() ?? 0,
    streak:         (j['streak'] as num?)?.toInt() ?? 0,
    rank:           (j['rank'] as num?)?.toInt() ?? position,
    level:          j['level'] as String?,
    rankVariation:  (j['rankVariation'] as num?)?.toInt(),
  );
}
