import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/matches/presentation/pages/home_page.dart';
import '../../features/bets/presentation/pages/palpites_page.dart';
import '../../features/matches/presentation/pages/ao_vivo_page.dart';
import '../../features/rankings/presentation/pages/ranking_page.dart';
import '../../features/social/presentation/pages/grupos_page.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home',    builder: (_, __) => const HomePage()),
        GoRoute(path: '/palpites', builder: (_, __) => const PalpitesPage()),
        GoRoute(path: '/ao-vivo', builder: (_, __) => const AoVivoPage()),
        GoRoute(path: '/ranking', builder: (_, __) => const RankingPage()),
        GoRoute(path: '/grupos',  builder: (_, __) => const GruposPage()),
      ],
    ),
  ],
);

class Bolao2026App extends StatelessWidget {
  const Bolao2026App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bolão 2026',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
