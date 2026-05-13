import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../matches/domain/entities/match.dart';
import '../../../matches/presentation/widgets/match_card.dart';

class PalpitesPage extends StatefulWidget {
  const PalpitesPage({super.key});

  @override
  State<PalpitesPage> createState() => _PalpitesPageState();
}

class _PalpitesPageState extends State<PalpitesPage> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedDate = 2;

  final _dates = [
    ('11', 'QUA'),
    ('12', 'QUI'),
    ('13', 'SEX'),
    ('14', 'SÁB'),
    ('15', 'DOM'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PalpitesAppBar(),
            _DatePicker(
              dates: _dates,
              selectedIndex: _selectedDate,
              onSelect: (i) => setState(() => _selectedDate = i),
            ),
            _StatusTabs(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _PalpitesTab(matches: MockMatches.scheduled),
                  _PalpitesTab(matches: MockMatches.live),
                  _PalpitesTab(matches: MockMatches.finished),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// APP BAR
// ===========================================================================
class _PalpitesAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Palpites', style: AppTextStyles.h2),
              Text('Copa do Mundo 2026', style: AppTextStyles.caption),
            ],
          ),
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.all(10),
            onTap: () {},
            child: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DATE PICKER
// ===========================================================================
class _DatePicker extends StatelessWidget {
  final List<(String, String)> dates;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _DatePicker({
    required this.dates,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final isSelected = i == selectedIndex;
          final (day, weekday) = dates[i];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.neonBlue, Color(0xFF3B82F6)],
                      )
                    : null,
                color: isSelected ? null : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.neonBlue : AppColors.cardBorder,
                ),
                boxShadow: isSelected ? AppColors.glowBlue(intensity: 0.3) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: AppTextStyles.h3.copyWith(
                      fontSize: 18,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    weekday,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// STATUS TABS
// ===========================================================================
class _StatusTabs extends StatelessWidget {
  final TabController controller;
  const _StatusTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
          Tab(text: 'Próximos'),
          Tab(text: 'Ao Vivo'),
          Tab(text: 'Finalizados'),
        ],
      ),
    );
  }
}

// ===========================================================================
// PALPITES TAB
// ===========================================================================
class _PalpitesTab extends StatelessWidget {
  final List<Match> matches;
  const _PalpitesTab({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('Nenhum jogo nesta data', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, i) {
        final match = matches[i];
        return MatchCard(
          match: match,
          onBetSubmit: match.isScheduled ? (home, away) {} : null,
        );
      },
    );
  }
}
