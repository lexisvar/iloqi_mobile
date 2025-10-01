import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/models/voice_models.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/voice_provider.dart';
import '../../../../core/services/voice_api_service.dart';

// Provider to track onboarding state
final onboardingInProgressProvider = StateProvider<bool>((ref) => false);

// Provider to track current onboarding step
final onboardingStepProvider = StateProvider<OnboardingStep>((ref) => OnboardingStep.l1Goals);

enum OnboardingStep { l1Goals, micPermission, enrollment, analysis, consent, status }

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> with WidgetsBindingObserver {
  bool _isSubmittingProfile = false; // Add flag to prevent router interference

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final currentStep = ref.read(onboardingStepProvider);
    print('🔄 OnboardingFlowPage initState - initial step: $currentStep');
    
    // Determine the correct step based on user state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineCorrectStep();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 App lifecycle state changed: $state');
    
    if (state == AppLifecycleState.resumed) {
      // App resumed, possibly from Settings
      print('🔄 App resumed, re-determining correct step');
      
      // Add a delay to allow iOS to update permission status
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _determineCorrectStep();
        }
      });
    }
  }

  void _determineCorrectStep() async {
    final authState = ref.read(authStateProvider);
    final hasConsent = ref.read(consentProvider);
    
    authState.whenData((user) async {
      if (user != null) {
        final hasProfileData = user.l1Language != null && user.targetAccent != null;
        
        if (hasProfileData && hasConsent) {
          // User has both profile and consent - go to final step
          print('🔄 User has profile and consent, setting step to status');
          ref.read(onboardingStepProvider.notifier).state = OnboardingStep.status;
        } else if (hasProfileData && !hasConsent) {
          // User has profile but no consent - check microphone permission
          final micStatus = await Permission.microphone.status;
          print('🔄 User has profile but no consent, mic permission: $micStatus');
          
          if (micStatus.isGranted) {
            // Mic permission already granted, go to enrollment
            print('🔄 Mic permission granted, setting step to enrollment');
            ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
          } else {
            // Need mic permission first
            print('🔄 Need mic permission, setting step to micPermission');
            ref.read(onboardingStepProvider.notifier).state = OnboardingStep.micPermission;
          }
        } else {
          // User needs to set up profile - stay on first step
          print('🔄 User needs profile setup, staying on l1Goals');
          ref.read(onboardingStepProvider.notifier).state = OnboardingStep.l1Goals;
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    print('🔄 OnboardingFlowPage dispose');
    super.dispose();
  }

  // L1 & goals form
  final _formKey = GlobalKey<FormState>();
  String? _l1Language;
  String? _region;
  String? _goal;
  int _minutesPerDay = 10;
  String _targetAccent = 'US';

  // Consent
  static const String _consentPhrase = 'I consent to iloqi creating a personal synthetic voice of me.';
  bool _isRecordingConsent = false;
  String? _consentRecordingPath;
  bool _submittingConsent = false;
  String? _error;

  // Helpers
  VoiceApiService get _voiceApi => ServiceLocator.instance.voiceApi;

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(onboardingStepProvider);
    print('🔄 OnboardingFlowPage build - current step: $currentStep');
    final recordingState = ref.watch(voiceRecordingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
        leading: currentStep == OnboardingStep.l1Goals
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBack,
              ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Padding(
            key: ValueKey(currentStep),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStepperHeader(theme, currentStep),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildStepContent(context, recordingState, currentStep),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: _error!, onClose: () => setState(() => _error = null)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header showing progress
  Widget _buildStepperHeader(ThemeData theme, OnboardingStep currentStep) {
    final steps = OnboardingStep.values;
    final idx = currentStep.index;
    return Row(
      children: steps.map((s) {
        final sIdx = s.index;
        final isCompleted = sIdx < idx;
        final isCurrent = sIdx == idx;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? theme.primaryColor
                          : Colors.grey.shade300,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : Text(
                          '${sIdx + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                ),
              ),
              if (sIdx < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: sIdx < idx ? Colors.green : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepContent(BuildContext context, VoiceRecordingState recordingState, OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.l1Goals:
        return _L1GoalsStep(
          formKey: _formKey,
          l1Language: _l1Language,
          region: _region,
          goal: _goal,
          minutesPerDay: _minutesPerDay,
          targetAccent: _targetAccent,
          onChanged: (l1, reg, g, min, accent) {
            print('🎯 Form changed - l1: $l1, region: $reg, goal: $g, minutes: $min, accent: $accent');
            setState(() {
              _l1Language = l1;
              _region = reg;
              _goal = g;
              _minutesPerDay = min;
              _targetAccent = accent;
            });
          },
          onContinue: _submitProfile,
        );

      case OnboardingStep.micPermission:
        return _MicPermissionStep(
          onAllow: _handleMicrophonePermission,
          onOpenSettings: openAppSettings,
          onCheckPermission: _recheckMicrophonePermission,
          onMicrophoneConfirmed: _microphoneConfirmed,
          onDebugSkip: _debugSkipMicPermission,
        );

      case OnboardingStep.enrollment:
        return _EnrollmentStep(
          recordingState: recordingState,
          onStart: () {
            setState(() => _error = null);
            ref.read(voiceRecordingProvider.notifier).startRecording();
          },
          onStop: () async {
            await ref.read(voiceRecordingProvider.notifier).stopRecording();
            // Validate duration 10-60s
            final dur = recordingState.recordingDuration.inSeconds;
            if (dur < 10 || dur > 60) {
              setState(() => _error = 'Please record between 10 and 60 seconds.');
              return;
            }

            // Check if we have a recording path
            if (recordingState.recordingPath == null) {
              setState(() => _error = 'Recording failed. Please try again.');
              return;
            }

            // Optional quality inspection
            try {
              final quality = await _voiceApi.inspectAudioQuality(File(recordingState.recordingPath!));
              debugPrint('Audio inspection: $quality');
            } catch (e) {
              debugPrint('Audio inspection failed: $e');
            }

            // Trigger voice analysis
            try {
              await ref.read(voiceAnalysisProvider.notifier).analyzeVoice(recordingState.recordingPath!);
            } catch (e) {
              setState(() => _error = 'Voice analysis failed: $e');
              return;
            }

            // Auto-advance to analysis step
            ref.read(onboardingStepProvider.notifier).state = OnboardingStep.analysis;
          },
          onReRecord: () {
            ref.read(voiceRecordingProvider.notifier).clearRecording();
          },
        );

      case OnboardingStep.analysis:
        return _AnalysisStep(
          recordingState: recordingState,
          analysisState: ref.watch(voiceAnalysisProvider),
          onAnalysisComplete: () => ref.read(onboardingStepProvider.notifier).state = OnboardingStep.consent,
          onReRecord: () {
            ref.read(voiceRecordingProvider.notifier).clearRecording();
            ref.read(voiceAnalysisProvider.notifier).clearAnalysis();
            ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
          },
        );

      case OnboardingStep.consent:
        return _ConsentStep(
          consentPhrase: _consentPhrase,
          isRecording: _isRecordingConsent,
          onStart: () async {
            setState(() {
              _error = null;
              _isRecordingConsent = true;
            });
            // clear and reuse same provider
            ref.read(voiceRecordingProvider.notifier).clearRecording();
            await ref.read(voiceRecordingProvider.notifier).startRecording();
          },
          onStop: () async {
            await ref.read(voiceRecordingProvider.notifier).stopRecording();
            final path = ref.read(voiceRecordingProvider).recordingPath;
            setState(() {
              _consentRecordingPath = path;
              _isRecordingConsent = false;
            });
          },
          onSubmit: _submitConsent,
        );

      case OnboardingStep.status:
        return _StatusStep(
          onGoHome: () => context.go('/home'),
        );
    }
  }

  // Actions
  void _onBack() {
    final currentStep = ref.read(onboardingStepProvider);
    if (currentStep.index == 0) return;
    ref.read(onboardingStepProvider.notifier).state = OnboardingStep.values[currentStep.index - 1];
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Set flag to prevent router interference
    ref.read(onboardingInProgressProvider.notifier).state = true;
    setState(() => _isSubmittingProfile = true);

    try {
      print('📝 Submitting profile - l1: $_l1Language, accent: $_targetAccent, minutes: $_minutesPerDay');

      // Persist user profile
      final success = await ref.read(authStateProvider.notifier).updateProfile({
        'l1_language': _l1Language ?? '',
        'target_accent': _targetAccent,
        'preferred_session_duration': _minutesPerDay,
        // Optional custom fields could be stored server-side later (goal/region)
      });

      print('📝 Profile update success: $success');

      if (!mounted) return;
      if (success) {
        // Check if user already has consent (maybe from previous session)
        final existingConsent = ref.read(consentProvider);
        if (existingConsent) {
          print('📝 User already has consent, skipping to status');
          ref.read(onboardingStepProvider.notifier).state = OnboardingStep.status;
          ref.read(onboardingInProgressProvider.notifier).state = false;
          return;
        }

        print('📝 Proceeding to mic permission step');
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.micPermission;
        print('📝 Step set to: ${ref.read(onboardingStepProvider)}');
        // Keep the flag true until onboarding is complete
      } else {
        setState(() => _error = 'Failed to save your profile. Please try again.');
        ref.read(onboardingInProgressProvider.notifier).state = false;
      }
    } catch (e) {
      setState(() => _error = 'Error saving profile: $e');
      ref.read(onboardingInProgressProvider.notifier).state = false;
    } finally {
      setState(() => _isSubmittingProfile = false);
    }
  }

  // Enhanced microphone permission handling
  Future<void> _handleMicrophonePermission() async {
    print('🎤 Starting comprehensive microphone permission check...');
    
    try {
      // Step 1: Check current status
      var status = await Permission.microphone.status;
      print('🎤 Current permission status: $status');
      
      if (status.isGranted) {
        print('🎤 Permission already granted, advancing to enrollment');
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
        return;
      }
      
      // Step 2: If not granted, check if we can request
      if (status.isDenied) {
        print('🎤 Permission denied, attempting to request...');
        status = await Permission.microphone.request();
        print('🎤 After request, status: $status');
        
        if (status.isGranted) {
          print('🎤 Permission granted after request, advancing to enrollment');
          ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
          return;
        }
      }
      
      // Step 3: Handle permanently denied or restricted
      if (status.isPermanentlyDenied || status.isRestricted) {
        print('🎤 Permission permanently denied or restricted');
        if (mounted) {
          setState(() => _error = 'Microphone access is required. Please enable it in Settings > Privacy & Security > Microphone, then restart the app.');
        }
        return;
      }
      
      // Step 4: Handle other denial cases
      if (mounted) {
        setState(() => _error = 'Microphone permission is required to continue. Please try again.');
      }
      
    } catch (e) {
      print('🎤 Error handling microphone permission: $e');
      if (mounted) {
        setState(() => _error = 'Error accessing microphone permissions: $e');
      }
    }
  }

  // Method for when user says they've enabled permission in Settings
  Future<void> _recheckMicrophonePermission() async {
    print('🎤 Rechecking microphone permission after Settings...');
    setState(() => _error = null);
    
    try {
      // Force refresh permission status
      final status = await Permission.microphone.status;
      print('🎤 Rechecked permission status: $status');
      
      if (status.isGranted) {
        print('🎤 Permission now granted! Advancing to enrollment');
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
      } else {
        print('🎤 Permission still not granted: $status');
        setState(() => _error = 'Permission still not enabled. Please check Settings > Privacy & Security > Microphone and enable access for this app.');
      }
    } catch (e) {
      print('🎤 Error rechecking permission: $e');
      setState(() => _error = 'Error checking permission: $e');
    }
  }

  // Debug method to skip permission (for development only)
  void _debugSkipMicPermission() {
    print('🎤 DEBUG: Skipping microphone permission');
    ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
  }

  // Method to advance when microphone is confirmed working (bypasses cached permission check)
  void _microphoneConfirmed() {
    print('🎤 Microphone confirmed working through real test - advancing to enrollment');
    ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
  }

  Future<void> _checkMicPermission() async {
    print('🎤 Checking microphone permission...');
    
    try {
      // Check current status
      var status = await Permission.microphone.status;
      print('🎤 Initial permission status: $status');
      
      // On iOS, sometimes we need to refresh the status after returning from Settings
      if (status.isDenied || status.isPermanentlyDenied) {
        // Wait a bit and check again
        await Future.delayed(const Duration(milliseconds: 500));
        status = await Permission.microphone.status;
        print('🎤 Refreshed permission status: $status');
      }
      
      if (!mounted) return;
      
      if (status.isGranted) {
        print('🎤 Permission is granted, advancing to enrollment');
        ref.read(onboardingStepProvider.notifier).state = OnboardingStep.enrollment;
      } else {
        print('🎤 Permission still not granted: $status');
        // Update the UI to reflect current status
        if (mounted) {
          setState(() {
            // Trigger a rebuild to update the permission button
          });
        }
      }
    } catch (e) {
      print('🎤 Error checking microphone permission: $e');
    }
  }

  Future<void> _submitConsent() async {
    if (_consentRecordingPath == null) {
      setState(() => _error = 'Please record the consent phrase first.');
      return;
    }
    setState(() {
      _error = null;
      _submittingConsent = true;
    });

    try {
      // Upload consent audio as a voice sample
      final sample = await _voiceApi.uploadVoiceSample(File(_consentRecordingPath!));

      // Record consent linked to that sample
      final resp = await _voiceApi.recordConsent({
        'consent_type': 'accent_twin',
        'voice_sample_id': sample.id,
      });
      debugPrint('Consent record: $resp');

      // Persist local flag for splash/router checks
      await ref.read(consentProvider.notifier).setConsent(true);
      print('✅ Consent saved via provider: consent_accent_twin = true');

      // Clear onboarding flag since we're now complete
      ref.read(onboardingInProgressProvider.notifier).state = false;

      // Refresh auth state after consent is complete to trigger router update
      await ref.read(authStateProvider.notifier).checkAuthStatus();

      if (!mounted) return;
      ref.read(onboardingStepProvider.notifier).state = OnboardingStep.status;
    } catch (e) {
      setState(() => _error = 'Failed to submit consent: $e');
    } finally {
      setState(() => _submittingConsent = false);
    }
  }
}

// -------------------- UI Sub-widgets --------------------

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;
  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120), // Limit height
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _L1GoalsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? l1Language;
  final String? region;
  final String? goal;
  final int minutesPerDay;
  final String targetAccent;
  final void Function(String?, String?, String?, int, String) onChanged;
  final VoidCallback onContinue;

  const _L1GoalsStep({
    required this.formKey,
    required this.l1Language,
    required this.region,
    required this.goal,
    required this.minutesPerDay,
    required this.targetAccent,
    required this.onChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final languages = <String>[
      'Spanish',
      'Mandarin',
      'Hindi',
      'Arabic',
      'Portuguese',
      'French',
      'Japanese',
      'Korean',
      'German',
      'Other',
    ];
    final goals = <String>[
      'Be clearer at work',
      'Improve pronunciation for study',
      'Travel confidently',
      'Public speaking',
      'Other',
    ];
    final accents = <String>['US', 'UK', 'AU', 'CA', 'IE'];

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text('Your native language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: l1Language,
            items: languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              onChanged(v, region, goal, minutesPerDay, targetAccent);
            },
            validator: (v) => v == null || v.isEmpty ? 'Please choose your native language' : null,
          ),
          const SizedBox(height: 16),
          Text('Region (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: region,
            onChanged: (v) {
              onChanged(l1Language, v, goal, minutesPerDay, targetAccent);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. Colombia',
            ),
          ),
          const SizedBox(height: 16),
          Text('Goal'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: goal,
            items: goals.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              onChanged(l1Language, region, v, minutesPerDay, targetAccent);
            },
            validator: (v) => v == null || v.isEmpty ? 'Please choose a goal' : null,
          ),
          const SizedBox(height: 16),
          Text('Time per day'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: minutesPerDay,
            items: [10, 15, 20, 25, 30].map((e) => DropdownMenuItem(value: e, child: Text('$e min'))).toList(),
            onChanged: (v) {
              onChanged(l1Language, region, goal, v ?? 10, targetAccent);
            },
          ),
          const SizedBox(height: 16),
          Text('Target accent'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: accents
                .map(
                  (a) => ChoiceChip(
                    label: Text(a),
                    selected: targetAccent == a,
                    onSelected: (sel) {
                      if (sel) {
                        print('🎯 Accent selected: $a');
                        onChanged(l1Language, region, goal, minutesPerDay, a);
                      }
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onContinue();
                }
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicPermissionStep extends StatefulWidget {
  final VoidCallback onAllow;
  final Future<bool> Function() onOpenSettings;
  final VoidCallback onCheckPermission;
  final VoidCallback onMicrophoneConfirmed; // New callback for when mic is confirmed working
  final VoidCallback? onDebugSkip;

  const _MicPermissionStep({
    required this.onAllow, 
    required this.onOpenSettings,
    required this.onCheckPermission,
    required this.onMicrophoneConfirmed,
    this.onDebugSkip,
  });

  @override
  State<_MicPermissionStep> createState() => _MicPermissionStepState();
}

class _MicPermissionStepState extends State<_MicPermissionStep> with WidgetsBindingObserver {
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Check permission when returning from Settings
      _checkPermissionStatus();
      widget.onCheckPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.microphone.status;
    if (mounted) {
      setState(() => _permissionStatus = status);
      
      // If permission is granted, automatically advance
      if (status.isGranted) {
        widget.onCheckPermission();
      }
    }
  }

  Future<void> _handleMicrophoneTap() async {
    print('🎤 Microphone icon tapped, testing actual recording capability...');
    
    try {
      // Test if we can actually initialize recording (this triggers native permission)
      final recorder = FlutterSoundRecorder();
      await recorder.openRecorder();
      await recorder.closeRecorder();
      
      print('🎤 Microphone access confirmed through recording test');
      
      // Update state to granted and proceed
      setState(() {
        _permissionStatus = PermissionStatus.granted;
      });
      
      widget.onMicrophoneConfirmed();
      
    } catch (e) {
      print('🎤 Recording test failed: $e');
      
      // Check the cached permission status as fallback
      final status = await Permission.microphone.status;
      print('🎤 Fallback permission status: $status');
      
      setState(() {
        _permissionStatus = status;
      });
      
      // Try requesting permission if denied
      if (status.isDenied) {
        final requestedStatus = await Permission.microphone.request();
        print('🎤 Permission request result: $requestedStatus');
        
        setState(() {
          _permissionStatus = requestedStatus;
        });
        
        if (requestedStatus.isGranted) {
          widget.onCheckPermission();
        }
      }
    }
  }

  Future<bool> _testMicrophoneAccess() async {
    print('🎤 Testing microphone access through recording capability...');
    
    try {
      // Test if we can actually initialize recording
      final recorder = FlutterSoundRecorder();
      await recorder.openRecorder();
      await recorder.closeRecorder();
      
      print('🎤 Microphone access confirmed - recording is possible');
      return true;
      
    } catch (e) {
      print('🎤 Microphone access test failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied = _permissionStatus == PermissionStatus.permanentlyDenied;
    final isDenied = _permissionStatus == PermissionStatus.denied;
    final isGranted = _permissionStatus == PermissionStatus.granted;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Interactive microphone icon
          GestureDetector(
            onTap: _handleMicrophoneTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isGranted 
                    ? Colors.green.withOpacity(0.1)
                    : isPermanentlyDenied 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.deepPurple.withOpacity(0.1),
                border: Border.all(
                  color: isGranted 
                      ? Colors.green
                      : isPermanentlyDenied 
                          ? Colors.red
                          : Colors.deepPurple,
                  width: 3,
                ),
              ),
              child: Icon(
                isGranted ? Icons.mic : Icons.mic_off,
                size: 60,
                color: isGranted 
                    ? Colors.green
                    : isPermanentlyDenied 
                        ? Colors.red
                        : Colors.deepPurple,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            isGranted 
                ? 'Microphone ready!'
                : 'We need your microphone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isGranted
                  ? 'Perfect! You can now continue with voice setup.'
                  : isPermanentlyDenied 
                      ? 'Please enable microphone access in Settings to continue.'
                      : isDenied
                          ? 'Tap the microphone above to allow access.'
                          : 'To analyze your pronunciation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isGranted ? Colors.green.shade700 : null,
              ),
            ),
          ),
          if (isPermanentlyDenied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'If this app doesn\'t appear in your microphone settings:',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Delete this app completely\n2. Reinstall from App Store\n3. Grant microphone permission when asked',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else if (isDenied) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap the microphone icon above to get the permission dialog',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                if (isGranted) ...[
                  // Permission granted - show continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Double-check permission with real test before continuing
                        print('🎤 Continue button: Testing microphone before proceeding...');
                        final hasRealPermission = await _testMicrophoneAccess();
                        if (hasRealPermission) {
                          print('🎤 Continue button: Microphone confirmed working, advancing to enrollment...');
                          // Directly advance to enrollment since we confirmed microphone works
                          widget.onMicrophoneConfirmed();
                        } else {
                          print('🎤 Continue button: Microphone test failed, refreshing state...');
                          setState(() {
                            _permissionStatus = PermissionStatus.denied;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (isPermanentlyDenied) ...[
                  // Permission permanently denied - show settings option
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.onOpenSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Test real microphone access before proceeding
                        print('🎤 "I\'ve enabled it" button: Testing microphone...');
                        final hasRealPermission = await _testMicrophoneAccess();
                        if (hasRealPermission) {
                          print('🎤 "I\'ve enabled it" button: Microphone confirmed working, proceeding...');
                          setState(() {
                            _permissionStatus = PermissionStatus.granted;
                          });
                          widget.onMicrophoneConfirmed();
                        } else {
                          print('🎤 "I\'ve enabled it" button: Microphone test failed, staying on current step...');
                          setState(() {
                            _permissionStatus = PermissionStatus.permanentlyDenied;
                          });
                        }
                      },
                      child: const Text('I\'ve enabled it'),
                    ),
                  ),
                ] else ...[
                  // Permission not yet requested or denied - show primary action
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleMicrophoneTap,
                      icon: const Icon(Icons.mic),
                      label: const Text('Allow Microphone Access'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await widget.onOpenSettings();
                    },
                    child: const Text('Open Settings Manually'),
                  ),
                ],
              ],
            ),
          ),
          
          // Debug section for development
          if (widget.onDebugSkip != null) ...[
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              'Debug Options (Development Only)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: widget.onDebugSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('DEBUG: Skip Permission'),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _EnrollmentStep extends StatelessWidget {
  final VoiceRecordingState recordingState;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onReRecord;

  const _EnrollmentStep({
    required this.recordingState,
    required this.onStart,
    required this.onStop,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = recordingState.isRecording;
    final hasRecording = recordingState.hasRecording;

    return ListView(
      children: [
        const SizedBox(height: 4),
        Text(
          'Read naturally:',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Text('“I live in Sydney…”'),
        ),
        const SizedBox(height: 16),
        _Meters(recordingState: recordingState),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: isRecording ? onStop : onStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isRecording ? 180 : 160,
              height: isRecording ? 180 : 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isRecording
                      ? [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.3)]
                      : [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.3)],
                ),
                border: Border.all(color: isRecording ? Colors.red : Colors.blue, width: 4),
              ),
              child: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 80, color: isRecording ? Colors.red : Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (hasRecording)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReRecord,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Meters extends StatelessWidget {
  final VoiceRecordingState recordingState;
  const _Meters({required this.recordingState});

  @override
  Widget build(BuildContext context) {
    final level = recordingState.audioLevel ?? -40;
    final factor = ((level + 40) / 40).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            const Text('REC'),
            const SizedBox(width: 8),
            Text(_format(recordingState.recordingDuration),
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Level'),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: factor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _format(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }
}

class _ConsentStep extends StatelessWidget {
  final String consentPhrase;
  final bool isRecording;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Future<void> Function() onSubmit;

  const _ConsentStep({
    required this.consentPhrase,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        Text('Say this sentence to give consent:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text('“$consentPhrase”'),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: isRecording ? onStop : onStart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isRecording ? 120 : 100,
              height: isRecording ? 120 : 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording ? Colors.red.shade100 : Colors.blue.shade100,
                border: Border.all(color: isRecording ? Colors.red : Colors.blue, width: 3),
              ),
              child: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 48, color: isRecording ? Colors.red : Colors.blue),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _AnalysisStep extends StatelessWidget {
  final VoiceRecordingState recordingState;
  final AsyncValue<VoiceAnalysis?> analysisState;
  final VoidCallback onAnalysisComplete;
  final VoidCallback onReRecord;

  const _AnalysisStep({
    required this.recordingState,
    required this.analysisState,
    required this.onAnalysisComplete,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    return analysisState.when(
      data: (analysis) => _buildAnalysisResults(context, analysis),
      loading: () => _buildAnalyzingView(),
      error: (error, stack) => _buildAnalysisErrorView(error, stack),
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.analytics, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Analyzing Your Voice',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Our AI is analyzing your speech patterns and accent',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('This may take a few moments...'),
      ],
    );
  }

  Widget _buildAnalysisResults(BuildContext context, VoiceAnalysis? analysis) {
    if (analysis == null) {
      return _buildNoResultsView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Analysis Complete',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here are the results of your voice analysis',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // Analysis summary card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analysis Results',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Detected Accent
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 28,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected Accent',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              analysis.detectedAccent.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quality metrics
                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.trending_up,
                        label: 'Confidence',
                        value: '${(analysis.confidence * 100).toStringAsFixed(1)}%',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.high_quality,
                        label: 'Audio Quality',
                        value: '${(analysis.audioQuality * 100).toStringAsFixed(1)}%',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: '${analysis.duration.toStringAsFixed(1)}s',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.waves,
                        label: 'Pronunciation',
                        value: analysis.pronunciationScore != null
                            ? '${(analysis.pronunciationScore! * 100).toStringAsFixed(1)}%'
                            : 'N/A',
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReRecord,
                icon: const Icon(Icons.refresh),
                label: const Text('Re-record'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAnalysisComplete,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoResultsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'Analysis Not Available',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unable to analyze your recording. Please try again.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onReRecord,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisErrorView(Object error, StackTrace stack) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        const Text(
          'Analysis Failed',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onReRecord,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final VoidCallback onGoHome;
  const _StatusStep({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.autorenew, size: 64),
          const SizedBox(height: 8),
          const Text('Creating your voice twin…'),
          const SizedBox(height: 8),
          const Text('Processing (you can keep using the app)'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onGoHome,
              child: const Text('Go to Home'),
            ),
          ),
        ],
      ),
    );
  }
}