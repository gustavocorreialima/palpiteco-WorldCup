import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _RankingAppBar(),
            _RankingTypeTabs(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _LeaderboardTab(players: _mockPlayers, currentUserId: 'joao'),
                  _LeaderboardTab(players: _mockPlayers.take(5).toList(), currentUserId: 'joao'),
                  _LeaderboardTab(players: _mockPlayers.take(8).toList(), currentUserId: 'joao'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock data
class _Player {
  final String id;
  final String name;
  final int points;
  final double accuracy;
  final int streak;
  final String? avatarUrl;
  final int? positionChange;
  const _Player({
    required this.id, required this.name, required this.points,
    required this.accuracy, required this.streak,
    this.avatarUrl, this.positionChange,
  });
}

final _mockPlayers = [
  const _Player(id: 'carlos', name: 'Carlos',   points: 1580, accuracy: 0.78, streak: 7,  positionChange: 0),
  const _Player(id: 'joao',   name: 'João',     points: 1480, accuracy: 0.72, streak: 5,  positionChange: 1),
  const _Player(id: 'marina', name: 'Marina',   points: 1380, accuracy: 0.69, streak: 3,  positionChange: -1),
  const _Player(id: 'pedro',  name: 'Pedro',    points: 1240, accuracy: 0.65, streak: 2,  positionChange: 2),
  const _Player(id: 'lucas',  name: 'Lucas',    points: 1180, accuracy: 0.61, streak: 0,  positionChange: 0),
  const _Player(id: 'ana',    name: 'Ana',      points: 1120, accuracy: 0.59, streak: 1,  positionChange: -2),
  const _Player(id: 'rafael', name: 'Rafael',   points: 980,  accuracy: 0.55, streak: 0,  positionChange: 0),
  const _Player(id: 'juliana',name: 'Juliana',  points: 920,  accuracy: 0.52, streak: 0,  positionChange: 1),
];

// ===========================================================================
// APP BAR
// ===========================================================================
class _RankingAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ranking', style: AppTextStyles.h2),
              Text('Copa do Mundo 2026', style: AppTextStyles.caption),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                const SizedBox(width: 4),
                Text('2° de 48', style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TABS
// ===========================================================================
class _RankingTypeTabs extends StatelessWidget {
  final TabController controller;
  const _RankingTypeTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.neonBlue, Color(0xFF3B82F6)]),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: AppColors.glowBlue(intensity: 0.3),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.buttonSm,
        tabs: const [
          Tab(text: 'Geral'),
          Tab(text: 'Grupo'),
          Tab(text: 'Rodada'),
        ],
      ),
    );
  }
}

// ===========================================================================
// LEADERBOARD TAB
// ===========================================================================
class _LeaderboardTab extends StatelessWidget {
  final List<_Player> players;
  final String currentUserId;
  const _LeaderboardTab({required this.players, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: players.length + 1, // +1 for top3 podium
      itemBuilder: (context, i) {
        if (i == 0) return _PodiumRow(players: players.take(3).toList());
        final player = players[i - 1];
        if (i <= 3) return const SizedBox(); // top3 shown in podium
        return _PlayerRow(
          position: i,
          player: player,
          isCurrentUser: player.id == currentUserId,
        );
      },
    );
  }
}

// ===========================================================================
// PODIUM TOP 3
// ===========================================================================
class _PodiumRow extends StatelessWidget {
  final List<_Player> players;
  const _PodiumRow({required this.players});

  @override
  Widget build(BuildContext context) {
    if (players.length < 3) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          Expanded(child: _PodiumCard(position: 2, player: players[1], height: 130)),
          const SizedBox(width: 8),
          // 1st
          Expanded(child: _PodiumCard(position: 1, player: players[0], height: 160)),
          const SizedBox(width: 8),
          // 3rd
          Expanded(child: _PodiumCard(position: 3, player: players[2], height: 110)),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int position;
  final _Player player;
  final double height;
  const _PodiumCard({required this.position, required this.player, required this.height});

  Color get _medalColor {
    switch (position) {
      case 1: return AppColors.gold;
      case 2: return const Color(0xFFB8B8C8);
      default: return const Color(0xFFCD7F32);
    }
  }

  Color get _glowColor {
    switch (position) {
      case 1: return AppColors.gold;
      case 2: return AppColors.neonBlue;
      default: return const Color(0xFFCD7F32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_glowColor.withOpacity(0.15), AppColors.card],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _glowColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: _glowColor.withOpacity(0.2), blurRadius: 20, spreadRadius: -4),
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Crown for 1st
          if (position == 1)
            Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
          const SizedBox(height: 4),

          // Avatar
          Container(
            width: position == 1 ? 52 : 44,
            height: position == 1 ? 52 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgSecondary,
              border: Border.all(color: _medalColor, width: 2.5),
              boxShadow: [BoxShadow(color: _glowColor.withOpacity(0.4), blurRadius: 12)],
            ),
            child: Center(
              child: Text(
                player.name[0].toUpperCase(),
                style: AppTextStyles.h3.copyWith(color: _medalColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(player.name, style: AppTextStyles.teamNameSm.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${player.points}', style: AppTextStyles.labelNeon.copyWith(color: _medalColor)),
          const SizedBox(height: 2),

          // Medal
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _medalColor.withOpacity(0.2),
              border: Border.all(color: _medalColor, width: 1),
            ),
            child: Center(
              child: Text('$position°', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, color: _medalColor)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PLAYER ROW
// ===========================================================================
class _PlayerRow extends StatelessWidget {
  final int position;
  final _Player player;
  final bool isCurrentUser;
  const _PlayerRow({required this.position, required this.player, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.neonBlue.withOpacity(0.1) : AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isCurrentUser ? AppColors.neonBlue.withOpacity(0.5) : AppColors.cardBorder,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 28,
            child: Text(
              '$position°',
              style: AppTextStyles.rankPosition.copyWith(
                fontSize: 15,
                color: isCurrentUser ? AppColors.neonBlue : AppColors.textSecondary,
              ),
            ),
          ),

          // Position change
          _PositionChange(change: player.positionChange),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgSecondary,
              border: Border.all(
                color: isCurrentUser ? AppColors.neonBlue : AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                player.name[0].toUpperCase(),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? AppColors.neonBlue : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + accuracy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(player.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text('Você', style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${(player.accuracy * 100).toStringAsFixed(0)}% acertos', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    if (player.streak > 0) ...[
                      const SizedBox(width: 8),
                      Text('🔥 ${player.streak}', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.gold)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.points}',
                style: AppTextStyles.rankPoints.copyWith(
                  color: isCurrentUser ? AppColors.neonBlue : AppColors.textPrimary,
                ),
              ),
              Text('pts', style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PositionChange extends StatelessWidget {
  final int? change;
  const _PositionChange({this.change});

  @override
  Widget build(BuildContext context) {
    if (change == null || change == 0) {
      return const SizedBox(width: 14);
    }
    final isUp = change! > 0;
    return Icon(
      isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      color: isUp ? AppColors.neonGreen : AppColors.liveRed,
      size: 14,
    );
  }
}
