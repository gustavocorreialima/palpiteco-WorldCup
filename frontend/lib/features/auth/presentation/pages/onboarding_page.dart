import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _contentController;

  late Animation<double> _heroScale;
  late Animation<double> _glowOpacity;
  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _contentSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── HERO — gradient premium background (imagem carregada se existir) ──
          AnimatedBuilder(
            animation: _heroScale,
            builder: (context, child) => Transform.scale(
              scale: _heroScale.value,
              child: child,
            ),
            child: _HeroBackground(size: size),
          ),

          // ── VERY LIGHT GRADIENT OVERLAY (top 20% → transparent → bottom) ─
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x55081220), // top: very faint
                  Colors.transparent, // middle: clear
                  Colors.transparent,
                  Color(0xCC081220), // bottom 30%: fade to bg
                  Color(0xFF081220), // very bottom: solid
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.2, 0.55, 0.82, 1.0],
              ),
            ),
          ),

          // ── CINEMATIC SIDE VIGNETTE ─────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x44081220), Colors.transparent, Color(0x44081220)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── PARTICLES ────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particleController.value),
              size: size,
            ),
          ),

          // ── GLOW BEHIND TROPHY (center) ──────────────────────────────────
          AnimatedBuilder(
            animation: _glowOpacity,
            builder: (context, _) => Center(
              child: Container(
                width: size.width * 0.7,
                height: size.height * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonBlue.withOpacity(_glowOpacity.value * 0.25),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                    BoxShadow(
                      color: AppColors.gold.withOpacity(_glowOpacity.value * 0.15),
                      blurRadius: 80,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── TOP LOGO ─────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _contentFade,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.neonBlue, AppColors.purple]),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: AppColors.glowBlue(intensity: 0.5),
                        ),
                        child: const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'BOLÃO ', style: AppTextStyles.h1.copyWith(color: Colors.white, letterSpacing: 2, fontSize: 26)),
                            TextSpan(text: '2026', style: AppTextStyles.h1.copyWith(color: AppColors.neonGreen, letterSpacing: 2, fontSize: 26)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'COPA DO MUNDO • USA / CAN / MEX',
                    style: AppTextStyles.labelNeon.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 3,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── BOTTOM CONTENT ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _contentSlide.value),
                child: FadeTransition(opacity: _contentFade, child: child),
              ),
              child: _BottomContent(),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// BOTTOM CONTENT CARD
// ===========================================================================
class _BottomContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 32, 24, MediaQuery.of(context).padding.bottom + 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.4],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tagline
          Text(
            'Entre no melhor bolão da\nCopa do Mundo 2026',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Palpite. Compete. Vença.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 32),

          // Stats row
          const _StatsRow(),

          const SizedBox(height: 28),

          // CTA Button — primary
          _NeonButton(
            label: 'Começar agora',
            icon: Icons.arrow_forward_rounded,
            onTap: () => context.go('/login'),
          ),

          const SizedBox(height: 16),

          // Secondary link
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/login');
            },
            child: Text(
              'Já tenho uma conta',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(value: '48', label: 'Seleções'),
        _StatDivider(),
        _StatItem(value: '104', label: 'Jogos'),
        _StatDivider(),
        _StatItem(value: '1.2K', label: 'Participantes'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.neonGreen)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: AppColors.cardBorder);
  }
}

class _NeonButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _NeonButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563FF), Color(0xFF3B82F6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label, style: AppTextStyles.button),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PARTICLE PAINTER — subtle floating lights
// ===========================================================================
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _rng = math.Random(42);

  static final _particles = List.generate(25, (i) => _Particle(
    x: _rng.nextDouble(),
    y: _rng.nextDouble(),
    radius: 1.0 + _rng.nextDouble() * 2.5,
    speed: 0.04 + _rng.nextDouble() * 0.08,
    phase: _rng.nextDouble() * math.pi * 2,
    isBlue: i % 3 != 0,
  ));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t + 1.0) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase) * 0.04;

      final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.6;
      final color = p.isBlue
          ? AppColors.neonBlue.withOpacity(opacity)
          : AppColors.neonGreen.withOpacity(opacity * 0.7);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, radius, speed, phase;
  final bool isBlue;
  const _Particle({
    required this.x, required this.y, required this.radius,
    required this.speed, required this.phase, required this.isBlue,
  });
}

// ===========================================================================
// HERO BACKGROUND — premium gradient com campo de futebol estilizado
// ===========================================================================
class _HeroBackground extends StatelessWidget {
  final Size size;
  const _HeroBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.1),
              radius: 1.3,
              colors: [Color(0xFF0F2A50), Color(0xFF081220)],
            ),
          ),
        ),
        // Campo de futebol estilizado (linhas)
        CustomPaint(painter: _FieldPainter()),
        // Glow central dourado (troféu)
        Center(
          child: Container(
            width: size.width * 0.6,
            height: size.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Troféu central
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.gold.withOpacity(0.2), Colors.transparent],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 60, spreadRadius: 10),
                  ],
                ),
                child: Icon(Icons.emoji_events_rounded, size: 80, color: AppColors.gold.withOpacity(0.9)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Círculo central
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.42), size.width * 0.25, paint);
    // Linha central
    canvas.drawLine(Offset(0, size.height * 0.42), Offset(size.width, size.height * 0.42), paint);
    // Área grande
    final areaRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.72),
      width: size.width * 0.55,
      height: size.height * 0.22,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(areaRect, const Radius.circular(4)), paint);
  }

  @override
  bool shouldRepaint(_FieldPainter old) => false;
}
