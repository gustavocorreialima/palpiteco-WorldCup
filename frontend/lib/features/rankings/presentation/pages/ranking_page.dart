import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/ranking_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/widgets/glass_card.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  List<RankingEntry> _global = [];
  List<RankingEntry> _round  = [];
  bool _loading = true;
  String? _error;

  UserModel? get _me => sl<AuthService>().user;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = sl<ApiService>();
      final results = await Future.wait([
        api.getGlobalRanking(),
        api.getRoundRanking(),
      ]);
      setState(() {
        _global = results[0].asMap().entries
            .map((e) => RankingEntry.fromJson(e.value as Map<String, dynamic>, e.key + 1))
            .toList();
        _round = results[1].asMap().entries
            .map((e) => RankingEntry.fromJson(e.value as Map<String, dynamic>, e.key + 1))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'Não foi possível carregar o ranking.'; _loading = false; });
    }
  }

  RankingEntry? _findMe(List<RankingEntry> list) {
    if (_me == null) return null;
    try { return list.firstWhere((e) => e.id == _me!.id); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final meGlobal = _findMe(_global);
    final meRound  = _findMe(_round);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _RankingAppBar(me: _me, meGlobal: meGlobal),
            _RankingTypeTabs(controller: _tabCtrl),
            Expanded(
              child: _loading
                  ? _LoadingState()
                  : _error != null
                      ? _ErrorState(error: _error!, onRetry: _load)
                      : TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _LeaderboardTab(entries: _global, currentUserId: _me?.id),
                            _LeaderboardTab(entries: _round,  currentUserId: _me?.id),
                          ],
                        ),
            ),
            if (!_loading && meGlobal != null)
              _UserRankBar(entry: meGlobal),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================
class _RankingAppBar extends StatelessWidget {
  final UserModel? me;
  final RankingEntry? meGlobal;
  const _RankingAppBar({this.me, this.meGlobal});

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
          if (meGlobal != null)
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
                  Text(
                    '${meGlobal!.rank}° lugar',
                    style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w700),
                  ),
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
  final List<RankingEntry> entries;
  final String? currentUserId;
  const _LeaderboardTab({required this.entries, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('Nenhum dado ainda', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _PodiumRow(entries: entries.take(3).toList());
        final entry = entries[i - 1];
        if (i <= 3) return const SizedBox.shrink();
        return _PlayerRow(
          entry: entry,
          isCurrentUser: entry.id == currentUserId,
        );
      },
    );
  }
}

// ===========================================================================
// PODIUM TOP 3
// ===========================================================================
class _PodiumRow extends StatelessWidget {
  final List<RankingEntry> entries;
  const _PodiumRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _PodiumCard(position: 2, entry: entries[1], height: 130)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumCard(position: 1, entry: entries[0], height: 160)),
          const SizedBox(width: 8),
          Expanded(child: _PodiumCard(position: 3, entry: entries[2], height: 110)),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int position;
  final RankingEntry entry;
  final double height;
  const _PodiumCard({required this.position, required this.entry, required this.height});

  Color get _medalColor {
    switch (position) {
      case 1:  return AppColors.gold;
      case 2:  return const Color(0xFFB8B8C8);
      default: return const Color(0xFFCD7F32);
    }
  }

  Color get _glowColor {
    switch (position) {
      case 1:  return AppColors.gold;
      case 2:  return AppColors.neonBlue;
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
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
          if (position == 1)
            Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
          const SizedBox(height: 4),
          // Avatar
          Container(
            width: position == 1 ? 52 : 44,
            height: position == 1 ? 52 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _parseColor(entry.avatarColor).withOpacity(0.25),
              border: Border.all(color: _medalColor, width: 2.5),
              boxShadow: [BoxShadow(color: _glowColor.withOpacity(0.4), blurRadius: 12)],
            ),
            child: Center(
              child: Text(
                entry.avatarInitials,
                style: AppTextStyles.h3.copyWith(color: _parseColor(entry.avatarColor)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.displayName.split(' ').first,
            style: AppTextStyles.teamNameSm.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('${entry.points}', style: AppTextStyles.labelNeon.copyWith(color: _medalColor)),
          const SizedBox(height: 2),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _medalColor.withOpacity(0.2),
              border: Border.all(color: _medalColor, width: 1),
            ),
            child: Center(
              child: Text('$position°', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: _medalColor)),
            ),
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return AppColors.neonBlue;
  }
}

// ===========================================================================
// PLAYER ROW
// ===========================================================================
class _PlayerRow extends StatelessWidget {
  final RankingEntry entry;
  final bool isCurrentUser;
  const _PlayerRow({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final avatarColor = _parseColor(entry.avatarColor);
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
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}°',
              style: AppTextStyles.rankPosition.copyWith(
                fontSize: 15,
                color: isCurrentUser ? AppColors.neonBlue : AppColors.textSecondary,
              ),
            ),
          ),
          _PositionChange(change: entry.rankVariation),
          const SizedBox(width: 10),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withOpacity(0.15),
              border: Border.all(
                color: isCurrentUser ? AppColors.neonBlue : avatarColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                entry.avatarInitials,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: avatarColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                    Text('${entry.accuracy.toStringAsFixed(0)}% acertos',
                        style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    if (entry.streak > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 11),
                      Text('${entry.streak}', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.gold)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
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
    if (change == null || change == 0) return const SizedBox(width: 14);
    final isUp = change! > 0;
    return Icon(
      isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      color: isUp ? AppColors.neonGreen : AppColors.liveRed,
      size: 14,
    );
  }
}

// ===========================================================================
// USER RANK BAR — barra fixa inferior com posição do usuário logado
// ===========================================================================
class _UserRankBar extends StatelessWidget {
  final RankingEntry entry;
  const _UserRankBar({required this.entry});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final avatarColor = _parseColor(entry.avatarColor);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPad),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.neonBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.neonBlue, AppColors.purple]),
              boxShadow: AppColors.glowBlue(intensity: 0.4),
            ),
            child: Center(
              child: Text('${entry.rank}°', style: AppTextStyles.buttonSm.copyWith(color: Colors.white, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarColor.withOpacity(0.15),
              border: Border.all(color: AppColors.neonBlue, width: 2),
            ),
            child: Center(
              child: Text(entry.avatarInitials, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, color: avatarColor)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(entry.displayName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text('Você', style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontSize: 9)),
                    ),
                  ],
                ),
                Text('${entry.accuracy.toStringAsFixed(0)}% de acertos', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.points}', style: AppTextStyles.rankPoints),
              Text('pts', style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// LOADING / ERROR STATES
// ===========================================================================
class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 8,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ShimmerBox(width: double.infinity, height: 64, borderRadius: AppRadius.md),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(error, style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            NeonButton(label: 'Tentar novamente', onTap: onRetry, height: 48, width: 200),
          ],
        ),
      ),
    );
  }
}
