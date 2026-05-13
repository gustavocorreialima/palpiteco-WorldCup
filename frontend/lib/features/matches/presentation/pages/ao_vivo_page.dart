import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/match.dart';

class AoVivoPage extends StatefulWidget {
  const AoVivoPage({super.key});

  @override
  State<AoVivoPage> createState() => _AoVivoPageState();
}

class _AoVivoPageState extends State<AoVivoPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _selectedMatch = 0;

  final _liveMatches = MockMatches.live;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _liveMatches.isEmpty
          ? _EmptyState()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _AoVivoAppBar(),
                SliverToBoxAdapter(child: _FeaturedLiveMatch(match: _liveMatches[_selectedMatch])),
                if (_liveMatches.length > 1) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text('Outros jogos ao vivo', style: AppTextStyles.h3),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i == _selectedMatch) return const SizedBox();
                        return _SmallLiveCard(
                          match: _liveMatches[i],
                          onTap: () => setState(() => _selectedMatch = i),
                        );
                      },
                      childCount: _liveMatches.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================
class _AoVivoAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Text('Ao Vivo', style: AppTextStyles.h2),
          const SizedBox(width: 10),
          const LiveBadge(label: '2 JOGOS', color: AppColors.liveRed),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.liveRed, size: 20),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// FEATURED LIVE MATCH
// ===========================================================================
class _FeaturedLiveMatch extends StatelessWidget {
  final Match match;
  const _FeaturedLiveMatch({required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2E), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.liveRed.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.liveRed.withOpacity(0.15), blurRadius: 30, spreadRadius: -5),
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            // Top accent line
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.liveRed, Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(match.group ?? match.competition.name, style: AppTextStyles.label),
                      const LiveBadge(label: 'AO VIVO', color: AppColors.liveRed),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Teams + Score
                  Row(
                    children: [
                      Expanded(child: _BigTeam(team: match.homeTeam)),
                      _BigScore(match: match),
                      Expanded(child: _BigTeam(team: match.awayTeam, isRight: true)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Possession bar
                  if (match.homePossession != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(match.homePossession! * 100).toStringAsFixed(0)}%', style: AppTextStyles.label.copyWith(color: AppColors.neonBlue)),
                        Text('Posse de bola', style: AppTextStyles.caption),
                        Text('${((1 - match.homePossession!) * 100).toStringAsFixed(0)}%', style: AppTextStyles.label.copyWith(color: AppColors.liveRed)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: match.homePossession!,
                        minHeight: 8,
                        backgroundColor: AppColors.liveRed.withOpacity(0.4),
                        valueColor: const AlwaysStoppedAnimation(AppColors.neonBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Live Events
                  if (match.liveEvents.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lances', style: AppTextStyles.label),
                          const SizedBox(height: 8),
                          ...match.liveEvents.reversed.take(4).map((e) => _EventTile(event: e)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  NeonButton(
                    label: 'Ver estatísticas',
                    onTap: () {},
                    outlined: true,
                    width: double.infinity,
                    color: AppColors.neonBlue,
                    height: 46,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigTeam extends StatelessWidget {
  final Team team;
  final bool isRight;
  const _BigTeam({required this.team, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamFlag(url: team.flagUrl ?? team.logoUrl, size: 64),
        const SizedBox(height: 10),
        Text(
          team.shortName ?? team.name,
          style: AppTextStyles.teamName.copyWith(fontSize: 15),
          textAlign: isRight ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

class _BigScore extends StatelessWidget {
  final Match match;
  const _BigScore({required this.match});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BigDigit(value: match.homeScoreFt ?? 0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–', style: AppTextStyles.scoreVs.copyWith(fontSize: 28)),
              ),
              _BigDigit(value: match.awayScoreFt ?? 0),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
            ),
            child: Text(
              "${match.liveMinute ?? 0}'",
              style: AppTextStyles.labelNeon.copyWith(color: AppColors.neonGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigDigit extends StatelessWidget {
  final int value;
  const _BigDigit({required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value',
      style: AppTextStyles.scoreHuge.copyWith(
        color: AppColors.textPrimary,
        shadows: [Shadow(color: AppColors.neonBlue.withOpacity(0.3), blurRadius: 20)],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final LiveEvent event;
  const _EventTile({required this.event});

  IconData get _icon {
    switch (event.type) {
      case 'goal':        return Icons.sports_soccer_rounded;
      case 'yellow_card': return Icons.square_rounded;
      case 'red_card':    return Icons.square_rounded;
      default:            return Icons.swap_horiz_rounded;
    }
  }

  Color get _color {
    switch (event.type) {
      case 'goal':        return AppColors.neonGreen;
      case 'yellow_card': return AppColors.gold;
      case 'red_card':    return AppColors.liveRed;
      default:            return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 16),
          const SizedBox(width: 8),
          Text(
            "${event.minute}'",
            style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(event.playerName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

// ===========================================================================
// SMALL LIVE CARD
// ===========================================================================
class _SmallLiveCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;
  const _SmallLiveCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                TeamFlag(url: match.homeTeam.flagUrl ?? match.homeTeam.logoUrl, size: 32),
                const SizedBox(width: 8),
                Text(match.homeTeam.shortName ?? match.homeTeam.name, style: AppTextStyles.teamNameSm),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${match.homeScoreFt ?? 0} – ${match.awayScoreFt ?? 0}',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              Text("${match.liveMinute ?? 0}'", style: AppTextStyles.caption.copyWith(color: AppColors.neonGreen, fontWeight: FontWeight.w700)),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(match.awayTeam.shortName ?? match.awayTeam.name, style: AppTextStyles.teamNameSm),
                const SizedBox(width: 8),
                TeamFlag(url: match.awayTeam.flagUrl ?? match.awayTeam.logoUrl, size: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// EMPTY STATE
// ===========================================================================
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.liveRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.live_tv_rounded, color: AppColors.liveRed, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Nenhum jogo ao vivo', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Os próximos jogos começam em breve', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
