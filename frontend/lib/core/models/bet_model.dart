class BetModel {
  final String id;
  final String matchId;
  final int predictedHome;
  final int predictedAway;
  final int? points;
  final String status; // pending | won | lost
  final bool isExact;
  final bool isCorrectOutcome;
  final String? submittedAt;

  const BetModel({
    required this.id,
    required this.matchId,
    required this.predictedHome,
    required this.predictedAway,
    this.points,
    required this.status,
    required this.isExact,
    required this.isCorrectOutcome,
    this.submittedAt,
  });

  factory BetModel.fromJson(Map<String, dynamic> j) => BetModel(
    id:               j['id'] as String,
    matchId:          j['matchId'] as String,
    predictedHome:    (j['predictedHome'] as num).toInt(),
    predictedAway:    (j['predictedAway'] as num).toInt(),
    points:           (j['points'] as num?)?.toInt(),
    status:           j['status'] as String? ?? 'pending',
    isExact:          j['isExact'] as bool? ?? false,
    isCorrectOutcome: j['isCorrectOutcome'] as bool? ?? false,
    submittedAt:      j['submittedAt'] as String?,
  );

  bool get isPending => status == 'pending';
  bool get isWon     => status == 'won';
  bool get isLost    => status == 'lost';
}
