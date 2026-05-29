import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/bet_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../shared/widgets/glass_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  List<BetModel> _bets = [];
  bool _loadingBets = true;

  AuthService get _auth => sl<AuthService>();
  UserModel?  get _user => _auth.user;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _loadBets();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadBets() async {
    try {
      final raw = await sl<ApiService>().getBets();
      setState(() {
        _bets = raw.map((b) => BetModel.fromJson(b as Map<String, dynamic>)).toList();
        _loadingBets = false;
      });
    } catch (_) {
      setState(() => _loadingBets = false);
    }
  }

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return AppColors.neonBlue; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _auth,
        builder: (context, _) {
          final user = _user;
          if (user == null) return const Center(child: CircularProgressIndicator(color: AppColors.neonBlue));

          return FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _ProfileAppBar(onLogout: () async {
                  await _auth.logout();
                  if (mounted) context.go('/login');
                }),
                SliverToBoxAdapter(child: _ProfileHeroCard(user: user, parseColor: _parseColor)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Estatísticas', style: AppTextStyles.h3),
                  ),
                ),
                SliverToBoxAdapter(child: _StatsGrid(user: user)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text('Conquistas', style: AppTextStyles.h3),
                  ),
                ),
                SliverToBoxAdapter(child: _BadgesRow(badges: user.badges)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Text('Meus palpites', style: AppTextStyles.h3),
                        const Spacer(),
                        Text(
                          '${_bets.length} total',
                          style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loadingBets)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator(color: AppColors.neonBlue, strokeWidth: 2)),
                    ),
                  )
                else if (_bets.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyBets(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _BetHistoryRow(bet: _bets[i]),
                      childCount: _bets.take(10).length,
                    ),
                  ),
                SliverToBoxAdapter(child: _SettingsSection(onLogout: () async {
                  await _auth.logout();
                  if (mounted) context.go('/login');
                })),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================
class _ProfileAppBar extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfileAppBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      title: Text('Meu Perfil', style: AppTextStyles.h2),
      actions: [
        GlassCard(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(10),
          onTap: () {},
          child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }
}

// ===========================================================================
// HERO CARD
// ===========================================================================
class _ProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final Color Function(String) parseColor;
  const _ProfileHeroCard({required this.user, required this.parseColor});

  String get _levelLabel {
    final pts = user.points;
    if (pts >= 3000) return 'Lendário';
    if (pts >= 2000) return 'Ídolo';
    if (pts >= 1500) return 'Craque';
    if (pts >= 1000) return 'Titular';
    if (pts >= 500)  return 'Reserva';
    return 'Estreante';
  }

  int get _nextLevelPts {
    final pts = user.points;
    if (pts >= 3000) return 3000;
    if (pts >= 2000) return 3000;
    if (pts >= 1500) return 2000;
    if (pts >= 1000) return 1500;
    if (pts >= 500)  return 1000;
    return 500;
  }

  double get _levelProgress => (user.points / _nextLevelPts).clamp(0.0, 1.0);
  Color get _avatarColor => parseColor(user.avatarColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF7C3AED)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: AppColors.glowBlue(intensity: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarColor.withOpacity(0.25),
                          border: Border.all(color: Colors.white24, width: 2.5),
                          boxShadow: [BoxShadow(color: _avatarColor.withOpacity(0.4), blurRadius: 16)],
                        ),
                        child: Center(
                          child: Text(
                            user.avatarInitials,
                            style: AppTextStyles.h1.copyWith(fontSize: 28, color: _avatarColor),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.neonGreen,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: AppTextStyles.h2.copyWith(fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('@${user.username}', style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _LevelBadge(level: _levelLabel, icon: Icons.bolt_rounded, color: AppColors.gold),
                            if (user.rank != null) ...[
                              const SizedBox(width: 8),
                              _LevelBadge(level: '${user.rank}° geral', icon: Icons.leaderboard_rounded, color: AppColors.neonBlue),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // XP bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Próximo nível', style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                      Text('${user.points} / $_nextLevelPts pts', style: AppTextStyles.caption.copyWith(color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: _levelProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(AppColors.neonGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _QuickStat(label: 'Pontos',   value: '${user.points}', color: AppColors.neonGreen)),
                  _SD(),
                  Expanded(child: _QuickStat(label: 'Acertos',  value: '${user.accuracy.toStringAsFixed(0)}%', color: AppColors.neonBlue)),
                  _SD(),
                  Expanded(child: _QuickStat(label: 'Palpites', value: '${user.betsTotal}', color: AppColors.gold)),
                  _SD(),
                  Expanded(child: _QuickStat(label: 'Sequência', value: '${user.streak}', color: AppColors.liveRed)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SD extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: Colors.white12);
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final IconData icon;
  final Color color;
  const _LevelBadge({required this.level, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(level, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: color, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

// ===========================================================================
// STATS GRID
// ===========================================================================
class _StatsGrid extends StatelessWidget {
  final UserModel user;
  const _StatsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _StatCard(icon: Icons.check_circle_rounded,           label: 'Exatos',      value: '${user.betsExact}',   sub: 'Placar exato',       color: AppColors.neonGreen),
          _StatCard(icon: Icons.sports_soccer_rounded,          label: 'Corretos',    value: '${user.betsCorrect}', sub: 'Resultado certo',    color: AppColors.neonBlue),
          _StatCard(icon: Icons.cancel_rounded,                 label: 'Erros',       value: '${user.betsWrong}',   sub: 'Palpites errados',   color: AppColors.liveRed),
          _StatCard(icon: Icons.local_fire_department_rounded,  label: 'Sequência',   value: '${user.streak}',      sub: 'Acertos seguidos',   color: AppColors.gold),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h2.copyWith(color: color)),
              Text(sub,   style: AppTextStyles.caption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// BADGES ROW
// ===========================================================================
class _BadgesRow extends StatelessWidget {
  final List<String> badges;
  const _BadgesRow({required this.badges});

  static const _allBadges = [
    _BadgeDef(slug: 'champion',  icon: Icons.emoji_events_rounded,           label: 'Campeão',   color: AppColors.gold),
    _BadgeDef(slug: 'on_fire',   icon: Icons.local_fire_department_rounded,  label: 'Em Chamas', color: AppColors.liveRed),
    _BadgeDef(slug: 'lightning', icon: Icons.bolt_rounded,                   label: 'Relâmpago', color: AppColors.neonGreen),
    _BadgeDef(slug: 'social',    icon: Icons.groups_rounded,                  label: 'Social',    color: AppColors.neonBlue),
    _BadgeDef(slug: 'legend',    icon: Icons.military_tech_rounded,           label: 'Lendário',  color: AppColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _allBadges.length,
        itemBuilder: (context, i) {
          final b = _allBadges[i];
          final unlocked = badges.contains(b.slug);
          final color = unlocked ? b.color : AppColors.textMuted;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 70,
            child: Column(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(unlocked ? 0.12 : 0.05),
                    border: Border.all(color: color.withOpacity(unlocked ? 0.5 : 0.15), width: 1.5),
                    boxShadow: unlocked ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12)] : null,
                  ),
                  child: Icon(b.icon, color: color.withOpacity(unlocked ? 1 : 0.3), size: 26),
                ),
                const SizedBox(height: 6),
                Text(b.label, style: AppTextStyles.caption.copyWith(fontSize: 9, color: color.withOpacity(unlocked ? 1 : 0.35)), textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeDef {
  final String slug, label;
  final IconData icon;
  final Color color;
  const _BadgeDef({required this.slug, required this.icon, required this.label, required this.color});
}

// ===========================================================================
// BET HISTORY ROW
// ===========================================================================
class _BetHistoryRow extends StatelessWidget {
  final BetModel bet;
  const _BetHistoryRow({required this.bet});

  Color get _color {
    if (bet.isExact)   return AppColors.neonGreen;
    if (bet.isWon)     return AppColors.neonBlue;
    if (bet.isLost)    return AppColors.liveRed;
    return AppColors.textMuted;
  }

  String get _label {
    if (bet.isExact) return '+${bet.points ?? 10} pts ★';
    if (bet.isWon)   return '+${bet.points ?? 5} pts ✓';
    if (bet.isLost)  return '0 pts ✗';
    return 'Pendente';
  }

  IconData get _icon {
    if (bet.isExact) return Icons.star_rounded;
    if (bet.isWon)   return Icons.check_rounded;
    if (bet.isLost)  return Icons.close_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _color.withOpacity(0.2)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withOpacity(0.12)),
            child: Icon(_icon, color: _color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Palpite: ${bet.predictedHome} – ${bet.predictedAway}',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  bet.submittedAt != null ? _formatDate(bet.submittedAt!) : 'Aguardando jogo',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: _color.withOpacity(0.3)),
            ),
            child: Text(_label, style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.w800, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}

class _EmptyBets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_soccer_rounded, size: 32, color: AppColors.textMuted.withOpacity(0.4)),
              const SizedBox(height: 8),
              Text('Nenhum palpite ainda — vá palpitar!', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// SETTINGS SECTION
// ===========================================================================
class _SettingsSection extends StatelessWidget {
  final VoidCallback onLogout;
  const _SettingsSection({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conta', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _SettingsItem(icon: Icons.notifications_rounded,   label: 'Notificações',       onTap: () {}),
          _SettingsItem(icon: Icons.share_rounded,           label: 'Compartilhar perfil', onTap: () {}),
          _SettingsItem(icon: Icons.help_outline_rounded,    label: 'Ajuda & Suporte',     onTap: () {}),
          _SettingsItem(icon: Icons.logout_rounded,          label: 'Sair da conta',       color: AppColors.liveRed, onTap: onLogout),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color != null ? color!.withOpacity(0.3) : AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: c, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, color: color != null ? c : AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
