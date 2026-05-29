import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  static const _tabs = [
    _NavTab(icon: Icons.home_rounded,                  label: 'Início',   isLive: false),
    _NavTab(icon: Icons.sports_soccer_rounded,         label: 'Palpites', isLive: false),
    _NavTab(icon: Icons.radio_button_checked_rounded,  label: 'Ao Vivo',  isLive: true),
    _NavTab(icon: Icons.leaderboard_rounded,           label: 'Ranking',  isLive: false),
    _NavTab(icon: Icons.person_rounded,                label: 'Perfil',   isLive: false),
  ];

  void _onTap(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: shell,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: shell.currentIndex,
        tabs: _tabs,
        onTap: _onTap,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavTab> tabs;
  final void Function(int) onTap;
  final double bottomPadding;

  const _GlassNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.cardBorder, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10)),
                BoxShadow(color: AppColors.neonBlue.withOpacity(0.06), blurRadius: 20),
              ],
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                return Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.tab, required this.isActive, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _glow  = Tween<double>(begin: 0.0,  end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isActive) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      widget.isActive ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.tab.isLive ? AppColors.liveRed : AppColors.neonBlue;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isActive)
                  Container(
                    width: 44, height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      color: activeColor.withOpacity(_glow.value * 0.15),
                    ),
                  ),
                Transform.scale(
                  scale: _scale.value,
                  child: Icon(
                    widget.tab.icon,
                    size: 22,
                    color: widget.isActive ? activeColor : AppColors.textMuted,
                  ),
                ),
                if (widget.tab.isLive)
                  Positioned(top: 0, right: 8, child: _LiveDot()),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              widget.tab.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                color: widget.isActive ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.liveRed.withOpacity(0.7 + _pulse.value * 0.3),
          boxShadow: [BoxShadow(color: AppColors.liveRed.withOpacity(0.5), blurRadius: 6)],
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final bool isLive;
  const _NavTab({required this.icon, required this.label, required this.isLive});
}
