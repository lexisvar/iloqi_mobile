import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/di/injection_container.dart';
import '../../../onboarding/presentation/pages/onboarding_flow.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    print('🚀 SplashPage initState called');
    _checkAuthAndNavigate();
  }

 Future<void> _checkAuthAndNavigate() async {
   print('🚀 Starting auth check and navigation');
   
   // Check if onboarding is in progress - if so, don't navigate
   final onboardingInProgress = ref.read(onboardingInProgressProvider);
   if (onboardingInProgress) {
     print('🚀 Onboarding in progress, splash page will not navigate');
     return;
   }
   
   await Future.delayed(const Duration(seconds: 2));
   
   if (!mounted) return;

   print('🚀 Widget still mounted, checking auth state');
   final authState = ref.read(authStateProvider);
   final isLoggedIn = authState.when(
     data: (user) {
       print('🚀 Auth state data: user = $user');
       return user != null;
     },
     loading: () {
       print('🚀 Auth state loading');
       return false;
     },
     error: (error, _) {
       print('🚀 Auth state error: $error');
       return false;
     },
   );

   if (!isLoggedIn) {
     context.go('/auth/login');
     return;
   }

   // If logged in, check onboarding prerequisites (profile + consent)
   final user = ref.read(currentUserProvider);
   final needsProfileSetup = user == null || user.l1Language == null || user.targetAccent == null;

   // Use consent provider to check consent status
   final hasConsent = ref.read(consentProvider);
   final needsConsent = !hasConsent;

   if (needsProfileSetup || needsConsent) {
     print('🧭 Redirecting to onboarding: needsProfile=$needsProfileSetup, needsConsent=$needsConsent');
     context.go('/onboarding');
     return;
   }

   context.go('/home');
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF8A82FF),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_rounded,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'iloqi',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Revolutionary Accent Training',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
