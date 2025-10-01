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
import '../../features/onboarding/presentation/pages/onboarding_flow.dart';
import '../providers/auth_provider.dart';
import '../di/injection_container.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasConsent = ref.watch(consentProvider);
  final onboardingInProgress = ref.watch(onboardingInProgressProvider);

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
      final isOnOnboardingPage = state.matchedLocation.startsWith('/onboarding');

      // Determine onboarding requirement when logged in
      final currentUser = authState.valueOrNull;
      print('🔐 Consent check: $hasConsent (key: consent_accent_twin)');

      // Check if user has completed profile but still needs consent
      final hasProfileData = currentUser?.l1Language != null && currentUser?.targetAccent != null;
      print('🔍 Profile check - hasProfileData: $hasProfileData, l1: ${currentUser?.l1Language}, accent: ${currentUser?.targetAccent}');
      final needsOnboarding = isLoggedIn && (!hasProfileData || !hasConsent);

      print('🔍 Final onboarding decision - needsOnboarding: $needsOnboarding (profile: $hasProfileData, consent: $hasConsent)');
      print('🔍 Onboarding in progress: $onboardingInProgress');

      // Prevent redirects during onboarding flow
      if (onboardingInProgress && isOnOnboardingPage) {
        print('🔍 Onboarding in progress, staying on onboarding page');
        return null;
      }

      // Special case: If user is on onboarding page and has profile but no consent, let them continue
      if (isOnOnboardingPage && hasProfileData && !hasConsent) {
        print('🔍 User on onboarding with profile but no consent - allowing continuation');
        return null;
      }

      print('🔍 Router redirect - location: ${state.matchedLocation}, isLoggedIn: $isLoggedIn, needsOnboarding: $needsOnboarding, isOnAuthPage: $isOnAuthPage, isOnOnboarding: $isOnOnboardingPage');

      // Prevent redirects during onboarding flow - stay on onboarding
      if (onboardingInProgress) {
        print('🔍 Onboarding in progress, forcing onboarding page');
        if (!isOnOnboardingPage) {
          return '/onboarding';
        }
        return null;
      }

      // Let splash handle initial navigation only if not in onboarding
      if (isOnSplashPage && !onboardingInProgress) {
        return null;
      }

      // Not logged in → force auth (unless already on auth)
      if (!isLoggedIn) {
        if (!isOnAuthPage) {
          print('🔍 Redirecting to login');
          return '/auth/login';
        }
        return null;
      }

      // Logged in and needs onboarding → force onboarding (but not if already there)
      if (needsOnboarding && !isOnOnboardingPage) {
        print('🧭 Redirecting to onboarding - needsOnboarding: $needsOnboarding');
        return '/onboarding';
      }

      // Logged in and onboarding complete → prevent staying on onboarding
      if (!needsOnboarding && isOnOnboardingPage && !onboardingInProgress) {
        print('🧭 Onboarding complete, redirecting to home - needsOnboarding: $needsOnboarding');
        return '/home';
      }

      // Logged in users should not visit auth pages
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowPage(),
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
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/voice')) return 1;
      if (location.startsWith('/training')) return 2;
      if (location.startsWith('/progress')) return 3;
      if (location.startsWith('/profile')) return 4;
      return 0;
    } catch (e) {
      // Fallback if GoRouterState is not available
      print('Warning: Could not get GoRouterState: $e');
      return 0;
    }
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
