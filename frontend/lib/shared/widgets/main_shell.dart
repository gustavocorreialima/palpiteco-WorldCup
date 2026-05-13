import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

// ===========================================================================
// MAIN SHELL — persistent bottom nav + page scaffold
// ===========================================================================
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _tabs = [
    _NavTab(path: '/home',     icon: Icons.home_rounded,          label: 'Início'),
    _NavTab(path: '/palpites', icon: Icons.sports_soccer_rounded,  label: 'Palpites'),
    _NavTab(path: '/ao-vivo',  icon: Icons.radio_button_checked_rounded, label: 'Ao vivo'),
    _NavTab(path: '/ranking',  icon: Icons.leaderboard_rounded,    label: 'Ranking'),
    _NavTab(path: '/grupos',   icon: Icons.group_rounded,          label: 'Grupos'),
  ];

  int _currentIndex = 0;

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index].path);
  }

  @override
  Widget build(BuildContext context) {
    // Sync index from router location
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (idx >= 0 && idx != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = idx);
      });
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: _onTabTap,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

// ===========================================================================
// GLASS NAVIGATION BAR
// ===========================================================================
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
              color: AppColors.card.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.cardBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.neonBlue.withOpacity(0.06),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final isActive = i == currentIndex;
                return Expanded(
                  child: _NavItem(
                    tab: tabs[i],
                    isActive: isActive,
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _glow  = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) _ctrl.forward();
      else _ctrl.reverse();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.tab.path == '/ao-vivo';

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow background
                if (widget.isActive)
                  Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      color: (isLive ? AppColors.liveRed : AppColors.neonBlue).withOpacity(_glow.value * 0.15),
                    ),
                  ),
                Transform.scale(
                  scale: _scale.value,
                  child: Icon(
                    widget.tab.icon,
                    size: 22,
                    color: widget.isActive
                        ? (isLive ? AppColors.liveRed : AppColors.neonBlue)
                        : AppColors.textMuted,
                  ),
                ),
                // Live dot
                if (isLive)
                  Positioned(
                    top: 0,
                    right: 8,
                    child: _LiveDot(),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              widget.tab.label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                color: widget.isActive
                    ? (isLive ? AppColors.liveRed : AppColors.neonBlue)
                    : AppColors.textMuted,
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
  final String path;
  final IconData icon;
  final String label;
  const _NavTab({required this.path, required this.icon, required this.label});
}
