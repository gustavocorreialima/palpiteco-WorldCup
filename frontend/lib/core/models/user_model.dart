class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String avatarInitials;
  final String avatarColor;
  final int points;
  final double accuracy;
  final int streak;
  final int? rank;
  final String? level;
  final int xp;
  final int betsTotal;
  final int betsCorrect;
  final int betsExact;
  final int? rankVariation;
  final List<String> badges;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.avatarInitials,
    required this.avatarColor,
    required this.points,
    required this.accuracy,
    required this.streak,
    this.rank,
    this.level,
    required this.xp,
    required this.betsTotal,
    required this.betsCorrect,
    required this.betsExact,
    this.rankVariation,
    required this.badges,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:             j['id'] as String,
    username:       j['username'] as String? ?? '',
    displayName:    j['displayName'] as String? ?? j['display_name'] as String? ?? '',
    email:          j['email'] as String? ?? '',
    avatarInitials: j['avatarInitials'] as String? ?? j['avatar_initials'] as String? ?? 'U',
    avatarColor:    j['avatarColor'] as String? ?? j['avatar_color'] as String? ?? '#2563FF',
    points:         (j['points'] as num?)?.toInt() ?? 0,
    accuracy:       (j['accuracy'] as num?)?.toDouble() ?? 0,
    streak:         (j['streak'] as num?)?.toInt() ?? 0,
    rank:           (j['rank'] as num?)?.toInt(),
    level:          j['level'] as String?,
    xp:             (j['xp'] as num?)?.toInt() ?? 0,
    betsTotal:      (j['betsTotal'] as num?)?.toInt() ?? 0,
    betsCorrect:    (j['betsCorrect'] as num?)?.toInt() ?? 0,
    betsExact:      (j['betsExact'] as num?)?.toInt() ?? 0,
    rankVariation:  (j['rankVariation'] as num?)?.toInt(),
    badges:         (j['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
  );

  int get betsWrong => betsTotal - betsCorrect;
  double get accuracyPct => betsTotal > 0 ? (betsCorrect / betsTotal * 100) : 0;
}
