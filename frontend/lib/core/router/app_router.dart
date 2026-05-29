import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../di/service_locator.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/matches/presentation/pages/home_page.dart';
import '../../features/bets/presentation/pages/palpites_page.dart';
import '../../features/matches/presentation/pages/ao_vivo_page.dart';
import '../../features/rankings/presentation/pages/ranking_page.dart';
import '../../features/social/presentation/pages/grupos_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

GoRouter buildRouter() {
  final auth = sl<AuthService>();

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.status == AuthStatus.unknown) return null;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/onboarding';

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        return '/home';
      }
      if (auth.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home',     builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/palpites', builder: (_, __) => const PalpitesPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ao-vivo',  builder: (_, __) => const AoVivoPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ranking',  builder: (_, __) => const RankingPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/perfil',   builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
}

class Bolao2026App extends StatefulWidget {
  const Bolao2026App({super.key});

  @override
  State<Bolao2026App> createState() => _Bolao2026AppState();
}

class _Bolao2026AppState extends State<Bolao2026App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    // Tenta restaurar sessão ao iniciar
    sl<AuthService>().tryRestoreSession();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bolão 2026',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
