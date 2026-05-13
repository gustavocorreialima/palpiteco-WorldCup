import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

class GruposPage extends StatefulWidget {
  const GruposPage({super.key});

  @override
  State<GruposPage> createState() => _GruposPageState();
}

class _GruposPageState extends State<GruposPage> with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  bool _fabOpen = false;

  final _groups = _mockGroups;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() { _fabCtrl.dispose(); super.dispose(); }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    _fabOpen ? _fabCtrl.forward() : _fabCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _PremiumFAB(
        isOpen: _fabOpen,
        controller: _fabCtrl,
        onToggle: _toggleFab,
        onCreateGroup: () {},
        onJoinGroup: () {},
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _GruposAppBar(onSearch: () {}),
            SliverToBoxAdapter(child: _MyGroupStats()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Meus Grupos', style: AppTextStyles.h3),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GroupCard(group: _groups[i]),
                childCount: _groups.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text('Grupos Públicos', style: AppTextStyles.h3),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PublicGroupCard(group: _mockPublicGroups[i]),
                childCount: _mockPublicGroups.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// Mock data
class _Group {
  final String name;
  final int members;
  final int maxMembers;
  final String code;
  final int myRank;
  final int myPoints;
  final Color color;
  final bool isPublic;
  const _Group({
    required this.name, required this.members, required this.maxMembers,
    required this.code, required this.myRank, required this.myPoints,
    required this.color, this.isPublic = false,
  });
}

final _mockGroups = [
  const _Group(name: 'Família Porto 🏆', members: 8,  maxMembers: 20, code: 'FAM01', myRank: 2,  myPoints: 890,  color: AppColors.neonBlue),
  const _Group(name: 'Empresa Copa 26',  members: 24, maxMembers: 50, code: 'EMP26', myRank: 7,  myPoints: 1240, color: AppColors.purple),
  const _Group(name: 'Amigos da Pub',    members: 12, maxMembers: 20, code: 'PUB12', myRank: 1,  myPoints: 1580, color: AppColors.neonGreen),
];

final _mockPublicGroups = [
  const _Group(name: 'Brasil nas Quartas 🇧🇷', members: 312, maxMembers: 500, code: 'BRQ1', myRank: 0, myPoints: 0, color: AppColors.neonGreen, isPublic: true),
  const _Group(name: 'Top Palpiteiros 2026',    members: 187, maxMembers: 250, code: 'TOP1', myRank: 0, myPoints: 0, color: AppColors.gold,     isPublic: true),
];

// ===========================================================================
// APP BAR
// ===========================================================================
class _GruposAppBar extends StatelessWidget {
  final VoidCallback onSearch;
  const _GruposAppBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background,
      title: Text('Grupos', style: AppTextStyles.h2),
      actions: [
        GestureDetector(
          onTap: onSearch,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// MY GROUP STATS
// ===========================================================================
class _MyGroupStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.group_rounded, color: AppColors.neonBlue, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('3 grupos', style: AppTextStyles.h3.copyWith(fontSize: 20)),
                          Text('participando', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1° lugar', style: AppTextStyles.h3.copyWith(fontSize: 20, color: AppColors.gold)),
                          Text('em 1 grupo', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// GROUP CARD
// ===========================================================================
class _GroupCard extends StatelessWidget {
  final _Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: group.color.withOpacity(0.25)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Top color bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              gradient: LinearGradient(colors: [group.color.withOpacity(0.0), group.color, group.color.withOpacity(0.0)]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Group avatar
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [group.color.withOpacity(0.3), group.color.withOpacity(0.1)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: group.color.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          group.name[0],
                          style: AppTextStyles.h2.copyWith(color: group.color, fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.people_rounded, color: AppColors.textMuted, size: 12),
                              const SizedBox(width: 4),
                              Text('${group.members}/${group.maxMembers} membros', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSecondary,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(group.code, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: group.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: group.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${group.myRank}°',
                            style: AppTextStyles.caption.copyWith(color: group.color, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${group.myPoints} pts', style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Members bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: group.members / group.maxMembers,
                    minHeight: 4,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation(group.color),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: 'Ver grupo',
                        outlined: true,
                        color: group.color,
                        height: 40,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: NeonButton(
                        label: 'Chat',
                        color: group.color,
                        height: 40,
                        icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
                        onTap: () {},
                      ),
                    ),
                  ],
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
// PUBLIC GROUP CARD
// ===========================================================================
class _PublicGroupCard extends StatelessWidget {
  final _Group group;
  const _PublicGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: group.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: group.color.withOpacity(0.3)),
            ),
            child: Center(
              child: Icon(Icons.public_rounded, color: group.color, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${group.members} membros · Público', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          NeonButton(
            label: 'Entrar',
            color: group.color,
            height: 36,
            width: 80,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// PREMIUM FAB
// ===========================================================================
class _PremiumFAB extends StatelessWidget {
  final bool isOpen;
  final AnimationController controller;
  final VoidCallback onToggle;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  const _PremiumFAB({
    required this.isOpen,
    required this.controller,
    required this.onToggle,
    required this.onCreateGroup,
    required this.onJoinGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini actions
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: isOpen ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isOpen ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FabOption(
                    label: 'Criar grupo',
                    icon: Icons.add_rounded,
                    color: AppColors.neonGreen,
                    onTap: onCreateGroup,
                  ),
                  const SizedBox(height: 8),
                  _FabOption(
                    label: 'Entrar com código',
                    icon: Icons.qr_code_rounded,
                    color: AppColors.neonBlue,
                    onTap: onJoinGroup,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Main FAB
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.neonBlue, Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
                boxShadow: AppColors.glowBlue(intensity: 0.5),
              ),
              child: AnimatedRotation(
                turns: isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FabOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FabOption({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Text(label, style: AppTextStyles.buttonSm.copyWith(color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}
