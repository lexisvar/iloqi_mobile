import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/voice/presentation/pages/voice_analysis_page.dart';
import '../../features/voice/presentation/pages/accent_twin_page.dart';
import '../../features/training/presentation/pages/training_page.dart';
import '../../features/training/presentation/pages/training_session_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.when(
        data: (user) {
          print('🔍 Auth state check - user: $user');
          return user != null;
        },
        loading: () {
          print('🔍 Auth state check - loading');
          return false;
        },
        error: (error, stack) {
          print('🔍 Auth state check - error: $error');
          return false;
        },
      );

      final isOnAuthPage = state.matchedLocation.startsWith('/auth');
      final isOnSplashPage = state.matchedLocation == '/splash';

      print('🔍 Router redirect - location: ${state.matchedLocation}, isLoggedIn: $isLoggedIn, isOnAuthPage: $isOnAuthPage');

      if (isOnSplashPage) {
        return null; // Let splash page handle navigation
      }

      if (!isLoggedIn && !isOnAuthPage) {
        print('🔍 Redirecting to login');
        return '/auth/login';
      }

      if (isLoggedIn && isOnAuthPage) {
        print('🔍 Redirecting to home');
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/voice-analysis',
            builder: (context, state) => const VoiceAnalysisPage(),
          ),
          GoRoute(
            path: '/accent-twin/:id',
            builder: (context, state) => AccentTwinPage(
              analysisId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/training',
            builder: (context, state) => const TrainingPage(),
          ),
          GoRoute(
            path: '/training-session/:id',
            builder: (context, state) => TrainingSessionPage(
              sessionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) => const ProgressPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Voice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Training',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/voice')) return 1;
    if (location.startsWith('/training')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/voice-analysis');
        break;
      case 2:
        context.go('/training');
        break;
      case 3:
        context.go('/progress');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
