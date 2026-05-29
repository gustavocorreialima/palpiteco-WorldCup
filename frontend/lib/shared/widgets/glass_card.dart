import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ===========================================================================
// GLASS CARD — glassmorphism premium card
// ===========================================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double blurStrength;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool withNeonBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.boxShadow,
    this.blurStrength = 12,
    this.backgroundColor,
    this.onTap,
    this.withNeonBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppRadius.lg;
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.card.withOpacity(0.85),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(
              color: withNeonBorder ? AppColors.neonBlue.withOpacity(0.4) : (borderColor ?? AppColors.cardBorder),
              width: withNeonBorder ? 1.5 : 1.0,
            ),
            boxShadow: boxShadow ?? AppColors.cardShadow,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(margin: margin, child: card),
      );
    }
    return Container(margin: margin, child: card);
  }
}

// ===========================================================================
// NEON BUTTON — glowing CTA
// ===========================================================================
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final double? width;
  final double height;
  final Widget? icon;
  final bool outlined;

  const NeonButton({
    super.key,
    required this.label,
    this.onTap,
    this.color,
    this.width,
    this.height = 52,
    this.icon,
    this.outlined = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.neonBlue;

    return GestureDetector(
      onTapDown: (_) { if (widget.onTap != null) _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: widget.outlined
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: color.withOpacity(0.6)),
                  color: color.withOpacity(0.08),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
              Text(
                widget.label,
                style: AppTextStyles.button.copyWith(
                  color: widget.outlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// LIVE BADGE — pulsing AO VIVO badge
// ===========================================================================
class LiveBadge extends StatefulWidget {
  final String label;
  final Color? color;
  final double fontSize;
  const LiveBadge({super.key, this.label = 'AO VIVO', this.color, this.fontSize = 10});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.liveRed;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15 + _pulse.value * 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: color.withOpacity(0.5 + _pulse.value * 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.7 + _pulse.value * 0.3),
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: AppTextStyles.labelNeon.copyWith(color: color, fontSize: widget.fontSize),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SECTION HEADER
// ===========================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.h3),
          ),
          if (trailing != null) trailing!,
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: AppTextStyles.caption.copyWith(color: AppColors.neonBlue, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SHIMMER LOADING
// ===========================================================================
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _shimmer = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(_shimmer.value - 1, 0),
            end: Alignment(_shimmer.value, 0),
            colors: [
              AppColors.card,
              AppColors.card.withOpacity(0.6),
              const Color(0xFF1E2837),
              AppColors.card.withOpacity(0.6),
              AppColors.card,
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// TEAM FLAG / LOGO WIDGET
// ===========================================================================
class TeamFlag extends StatelessWidget {
  final String? url;
  final double size;
  final bool withGlow;

  const TeamFlag({super.key, this.url, this.size = 40, this.withGlow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: withGlow ? AppColors.glowBlue(intensity: 0.3) : null,
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.card,
        child: Icon(Icons.sports_soccer_rounded, color: AppColors.textMuted, size: size * 0.5),
      );
}

// ===========================================================================
// COUNTDOWN TIMER WIDGET
// ===========================================================================
class CountdownTimer extends StatefulWidget {
  final DateTime target;
  const CountdownTimer({super.key, required this.target});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_update);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    _remaining = widget.target.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    final d = _remaining.inDays;
    final h = _remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d > 0) ...[
          _TimeUnit(value: d.toString(), label: 'dias'),
          _TimeSeparator(),
        ],
        _TimeUnit(value: h, label: 'h'),
        _TimeSeparator(),
        _TimeUnit(value: m, label: 'min'),
        _TimeSeparator(),
        _TimeUnit(value: s, label: 's'),
      ],
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;
  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.neonGreen, fontWeight: FontWeight.w800)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(':', style: AppTextStyles.h3.copyWith(color: AppColors.textMuted)),
    );
  }
}
