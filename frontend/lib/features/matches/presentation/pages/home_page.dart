import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/match.dart';
import '../widgets/match_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _HomeAppBar(),
            SliverToBoxAdapter(child: _HeroRankCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: _LiveMatchesHeader(),
              ),
            ),
            _LiveMatchesList(),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Próximos Jogos',
                action: 'Ver todos',
                onAction: () {},
              ),
            ),
            _UpcomingMatchesList(),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Destaques',
                action: 'Ver todos',
                onAction: () {},
              ),
            ),
            _HighlightsRow(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================
class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Row(
        children: [
          RichText(
            text: const TextSpan(children: [
              TextSpan(text: 'Bolão ', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              TextSpan(text: '2026', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neonGreen)),
            ]),
          ),
          const SizedBox(width: 8),
          const LiveBadge(label: '2 ao vivo', color: AppColors.liveRed),
        ],
      ),
      actions: [
        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 20),
            ),
            Positioned(
              top: 8, right: 20,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// HERO RANKING CARD
// ===========================================================================
class _HeroRankCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppColors.glowBlue(intensity: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Olá, João! 👋', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Que comece a competição!', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text('12°', style: AppTextStyles.buttonSm.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _RankStat(label: 'Pontos', value: '1.240', icon: Icons.bolt_rounded, color: AppColors.neonGreen)),
                  Expanded(child: _RankStat(label: 'Acertos', value: '68%', icon: Icons.check_circle_rounded, color: AppColors.neonBlue)),
                  Expanded(child: _RankStat(label: 'Sequência', value: '5 🔥', icon: Icons.local_fire_department_rounded, color: AppColors.gold)),
                ],
              ),
              const SizedBox(height: 20),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Próximo nível: Craque', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                      Text('1240 / 1500 pts', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: 1240 / 1500,
                      minHeight: 6,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _RankStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}

// ===========================================================================
// LIVE HEADER
// ===========================================================================
class _LiveMatchesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const LiveBadge(label: 'AO VIVO', color: AppColors.liveRed),
        const SizedBox(width: 10),
        Text('Jogos em andamento', style: AppTextStyles.h3),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Text('Ver todos', style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ===========================================================================
// LIVE MATCHES LIST
// ===========================================================================
class _LiveMatchesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final live = MockMatches.live;
    if (live.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: live.length,
          itemBuilder: (context, i) => _LiveCard(match: live[i]),
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final Match match;
  const _LiveCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      withNeonBorder: false,
      borderColor: AppColors.liveRed.withOpacity(0.3),
      backgroundColor: AppColors.card,
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(match.group ?? match.competition.name, style: AppTextStyles.caption),
                const LiveBadge(label: 'AO VIVO', color: AppColors.liveRed, fontSize: 9),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MiniTeam(team: match.homeTeam),
                Column(
                  children: [
                    Text(
                      '${match.homeScoreFt ?? 0}  –  ${match.awayScoreFt ?? 0}',
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, letterSpacing: 0),
                    ),
                    Text("${match.liveMinute ?? 0}'", style: AppTextStyles.caption.copyWith(color: AppColors.neonGreen)),
                  ],
                ),
                _MiniTeam(team: match.awayTeam),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: match.homePossession ?? 0.5,
                minHeight: 4,
                backgroundColor: AppColors.liveRed.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(AppColors.neonBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTeam extends StatelessWidget {
  final Team team;
  const _MiniTeam({required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamFlag(url: team.flagUrl ?? team.logoUrl, size: 36),
        const SizedBox(height: 4),
        Text(team.shortName ?? team.name, style: AppTextStyles.teamNameSm),
      ],
    );
  }
}

// ===========================================================================
// UPCOMING MATCHES LIST
// ===========================================================================
class _UpcomingMatchesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final upcoming = MockMatches.scheduled;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => MatchCard(match: upcoming[i]),
        childCount: upcoming.length.clamp(0, 3),
      ),
    );
  }
}

// ===========================================================================
// HIGHLIGHTS ROW
// ===========================================================================
class _HighlightsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 130,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _HighlightCard(
              icon: Icons.emoji_events_rounded,
              title: 'Mata-Mata',
              subtitle: 'Oitavas disponíveis',
              color: AppColors.gold,
            ),
            _HighlightCard(
              icon: Icons.group_rounded,
              title: 'Meu Grupo',
              subtitle: '8 participantes',
              color: AppColors.neonBlue,
            ),
            _HighlightCard(
              icon: Icons.bar_chart_rounded,
              title: 'Estatísticas',
              subtitle: 'Ver meu desempenho',
              color: AppColors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _HighlightCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
