import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/models/voice_models.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/voice_provider.dart';
import '../../../../core/services/voice_api_service.dart';

enum OnboardingStep { l1Goals, micPermission, enrollment, analysis, consent, status }

class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  OnboardingStep _step = OnboardingStep.l1Goals;

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
    final recordingState = ref.watch(voiceRecordingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
        leading: _step == OnboardingStep.l1Goals
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
            key: ValueKey(_step),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStepperHeader(theme),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildStepContent(context, recordingState),
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
  Widget _buildStepperHeader(ThemeData theme) {
    final steps = OnboardingStep.values;
    final idx = _step.index;
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

  Widget _buildStepContent(BuildContext context, VoiceRecordingState recordingState) {
    switch (_step) {
      case OnboardingStep.l1Goals:
        return _L1GoalsStep(
          formKey: _formKey,
          l1Language: _l1Language,
          region: _region,
          goal: _goal,
          minutesPerDay: _minutesPerDay,
          targetAccent: _targetAccent,
          onChanged: (l1, reg, g, min, accent) {
            _l1Language = l1;
            _region = reg;
            _goal = g;
            _minutesPerDay = min;
            _targetAccent = accent;
          },
          onContinue: _submitProfile,
        );

      case OnboardingStep.micPermission:
        return _MicPermissionStep(
          onAllow: _requestMicPermission,
          onOpenSettings: openAppSettings,
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
            setState(() => _step = OnboardingStep.analysis);
          },
          onReRecord: () {
            ref.read(voiceRecordingProvider.notifier).clearRecording();
          },
        );

      case OnboardingStep.analysis:
        return _AnalysisStep(
          recordingState: recordingState,
          analysisState: ref.watch(voiceAnalysisProvider),
          onAnalysisComplete: () => setState(() => _step = OnboardingStep.consent),
          onReRecord: () {
            ref.read(voiceRecordingProvider.notifier).clearRecording();
            ref.read(voiceAnalysisProvider.notifier).clearAnalysis();
            setState(() => _step = OnboardingStep.enrollment);
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
    if (_step.index == 0) return;
    setState(() => _step = OnboardingStep.values[_step.index - 1]);
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      // Persist user profile
      final success = await ref.read(authStateProvider.notifier).updateProfile({
        'l1_language': _l1Language ?? '',
        'target_accent': _targetAccent,
        'preferred_session_duration': _minutesPerDay,
        // Optional custom fields could be stored server-side later (goal/region)
      });
      if (!mounted) return;
      if (success) {
        // Refresh auth state to ensure router gets updated user data
        await ref.read(authStateProvider.notifier).checkAuthStatus();
        setState(() => _step = OnboardingStep.micPermission);
      } else {
        setState(() => _error = 'Failed to save your profile. Please try again.');
      }
    } catch (e) {
      setState(() => _error = 'Error saving profile: $e');
    }
  }

  Future<void> _requestMicPermission() async {
    setState(() => _error = null);
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() => _step = OnboardingStep.enrollment);
    } else if (status.isPermanentlyDenied) {
      setState(() => _error = 'Microphone permission permanently denied. Open Settings to enable.');
    } else {
      setState(() => _error = 'Microphone permission denied. Please allow to continue.');
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
      await ServiceLocator.instance.prefs.setBool('consent_accent_twin', true);

      if (!mounted) return;
      setState(() => _step = OnboardingStep.status);
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
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade800),
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

    String? l1 = l1Language;
    String? reg = region;
    String? g = goal;
    int mins = minutesPerDay;
    String accent = targetAccent;

    return Form(
      key: formKey,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text('Your native language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: l1,
            items: languages.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              l1 = v;
              onChanged(l1, reg, g, mins, accent);
            },
            validator: (v) => v == null || v.isEmpty ? 'Please choose your native language' : null,
          ),
          const SizedBox(height: 16),
          Text('Region (optional)'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: reg,
            onChanged: (v) {
              reg = v;
              onChanged(l1, reg, g, mins, accent);
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
            value: g,
            items: goals.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              g = v;
              onChanged(l1, reg, g, mins, accent);
            },
            validator: (v) => v == null || v.isEmpty ? 'Please choose a goal' : null,
          ),
          const SizedBox(height: 16),
          Text('Time per day'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: mins,
            items: [10, 15, 20, 25, 30].map((e) => DropdownMenuItem(value: e, child: Text('$e min'))).toList(),
            onChanged: (v) {
              mins = v ?? 10;
              onChanged(l1, reg, g, mins, accent);
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
                    selected: accent == a,
                    onSelected: (sel) {
                      if (sel) {
                        accent = a;
                        onChanged(l1, reg, g, mins, accent);
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

class _MicPermissionStep extends StatelessWidget {
  final VoidCallback onAllow;
  final Future<bool> Function() onOpenSettings;

  const _MicPermissionStep({required this.onAllow, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.mic, size: 96, color: Colors.deepPurple),
        const SizedBox(height: 16),
        Text(
          'We need your microphone',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'To analyze your pronunciation.',
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onAllow,
            child: const Text('Allow microphone'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
        ),
      ],
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