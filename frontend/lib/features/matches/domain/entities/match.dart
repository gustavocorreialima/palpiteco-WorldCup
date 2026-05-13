enum MatchStatus { scheduled, live, finished, postponed }
enum BetResult   { exact, correct, wrong, pending }

class Competition {
  final String id;
  final String name;
  final String? logoUrl;
  final String? round;
  const Competition({required this.id, required this.name, this.logoUrl, this.round});
}

class Team {
  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  final String? flagUrl;
  const Team({required this.id, required this.name, this.shortName, this.logoUrl, this.flagUrl});
}

class H2HStats {
  final int teamAWins;
  final int draws;
  final int teamBWins;
  final int teamAGoals;
  final int teamBGoals;
  final int lastNMatches;
  const H2HStats({
    required this.teamAWins,
    required this.draws,
    required this.teamBWins,
    required this.teamAGoals,
    required this.teamBGoals,
    this.lastNMatches = 5,
  });
}

class Bet {
  final int homeScore;
  final int awayScore;
  final BetResult result;
  final int? pointsEarned;
  const Bet({required this.homeScore, required this.awayScore, this.result = BetResult.pending, this.pointsEarned});
}

class LiveEvent {
  final int minute;
  final String type;   // goal, yellow_card, red_card, substitution
  final String teamId;
  final String playerName;
  const LiveEvent({required this.minute, required this.type, required this.teamId, required this.playerName});
}

class Match {
  final String id;
  final Competition competition;
  final Team homeTeam;
  final Team awayTeam;
  final MatchStatus status;
  final DateTime kickoffAt;
  final int? homeScoreFt;
  final int? awayScoreFt;
  final int? homeScoreHt;
  final int? awayScoreHt;
  final int? liveMinute;
  final String? venueName;
  final H2HStats? h2hStats;
  final String? round;
  final String? group;
  final List<LiveEvent> liveEvents;
  final double? homePossession;
  final double? awayPossession;

  const Match({
    required this.id,
    required this.competition,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.kickoffAt,
    this.homeScoreFt,
    this.awayScoreFt,
    this.homeScoreHt,
    this.awayScoreHt,
    this.liveMinute,
    this.venueName,
    this.h2hStats,
    this.round,
    this.group,
    this.liveEvents = const [],
    this.homePossession,
    this.awayPossession,
  });

  bool get isLive     => status == MatchStatus.live;
  bool get isFinished => status == MatchStatus.finished;
  bool get isScheduled => status == MatchStatus.scheduled;

  String get scoreDisplay {
    if (isLive || isFinished) {
      return '${homeScoreFt ?? 0} – ${awayScoreFt ?? 0}';
    }
    return 'VS';
  }
}

// Mock data for development
class MockMatches {
  static final brazil = Team(
    id: 'bra', name: 'Brasil', shortName: 'BRA',
    flagUrl: 'https://flagcdn.com/h40/br.png',
    logoUrl: 'https://media.api-sports.io/football/teams/6.png',
  );
  static final argentina = Team(
    id: 'arg', name: 'Argentina', shortName: 'ARG',
    flagUrl: 'https://flagcdn.com/h40/ar.png',
    logoUrl: 'https://media.api-sports.io/football/teams/26.png',
  );
  static final mexico = Team(
    id: 'mex', name: 'México', shortName: 'MEX',
    flagUrl: 'https://flagcdn.com/h40/mx.png',
    logoUrl: 'https://media.api-sports.io/football/teams/16.png',
  );
  static final africa = Team(
    id: 'rsa', name: 'África do Sul', shortName: 'RSA',
    flagUrl: 'https://flagcdn.com/h40/za.png',
    logoUrl: 'https://media.api-sports.io/football/teams/572.png',
  );
  static final portugal = Team(
    id: 'por', name: 'Portugal', shortName: 'POR',
    flagUrl: 'https://flagcdn.com/h40/pt.png',
    logoUrl: 'https://media.api-sports.io/football/teams/27.png',
  );
  static final ghana = Team(
    id: 'gha', name: 'Gana', shortName: 'GHA',
    flagUrl: 'https://flagcdn.com/h40/gh.png',
    logoUrl: 'https://media.api-sports.io/football/teams/54.png',
  );
  static final serbia = Team(
    id: 'srb', name: 'Sérvia', shortName: 'SRB',
    flagUrl: 'https://flagcdn.com/h40/rs.png',
    logoUrl: 'https://media.api-sports.io/football/teams/20.png',
  );
  static final sweden = Team(
    id: 'swe', name: 'Suécia', shortName: 'SWE',
    flagUrl: 'https://flagcdn.com/h40/se.png',
    logoUrl: 'https://media.api-sports.io/football/teams/631.png',
  );

  static final copa = Competition(
    id: 'wc2026', name: 'Copa do Mundo 2026', round: 'Fase de Grupos',
    logoUrl: 'https://media.api-sports.io/football/leagues/1.png',
  );

  static List<Match> all = [
    Match(
      id: '1', competition: copa, homeTeam: brazil, awayTeam: serbia,
      status: MatchStatus.live, kickoffAt: DateTime.now().subtract(const Duration(minutes: 45)),
      homeScoreFt: 2, awayScoreFt: 1, liveMinute: 67,
      homePossession: 0.58, awayPossession: 0.42,
      group: 'Grupo D',
      liveEvents: [
        const LiveEvent(minute: 23, type: 'goal', teamId: 'bra', playerName: 'Vinicius Jr.'),
        const LiveEvent(minute: 39, type: 'goal', teamId: 'srb', playerName: 'Jovic'),
        const LiveEvent(minute: 61, type: 'goal', teamId: 'bra', playerName: 'Rodrygo'),
      ],
      h2hStats: const H2HStats(teamAWins: 4, draws: 2, teamBWins: 1, teamAGoals: 11, teamBGoals: 5),
    ),
    Match(
      id: '2', competition: copa, homeTeam: portugal, awayTeam: ghana,
      status: MatchStatus.live, kickoffAt: DateTime.now().subtract(const Duration(minutes: 20)),
      homeScoreFt: 1, awayScoreFt: 0, liveMinute: 32,
      homePossession: 0.64, awayPossession: 0.36,
      group: 'Grupo H',
    ),
    Match(
      id: '3', competition: copa, homeTeam: mexico, awayTeam: africa,
      status: MatchStatus.scheduled,
      kickoffAt: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
      group: 'Grupo A',
      h2hStats: const H2HStats(teamAWins: 3, draws: 1, teamBWins: 1, teamAGoals: 8, teamBGoals: 4),
    ),
    Match(
      id: '4', competition: copa, homeTeam: sweden, awayTeam: argentina,
      status: MatchStatus.scheduled,
      kickoffAt: DateTime.now().add(const Duration(hours: 5)),
      group: 'Grupo C',
    ),
    Match(
      id: '5', competition: copa, homeTeam: brazil, awayTeam: ghana,
      status: MatchStatus.finished,
      kickoffAt: DateTime.now().subtract(const Duration(days: 2)),
      homeScoreFt: 3, awayScoreFt: 0,
      group: 'Grupo D',
    ),
  ];

  static List<Match> get live      => all.where((m) => m.isLive).toList();
  static List<Match> get scheduled => all.where((m) => m.isScheduled).toList();
  static List<Match> get finished  => all.where((m) => m.isFinished).toList();
}
