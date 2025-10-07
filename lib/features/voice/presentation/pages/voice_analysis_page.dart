import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';
import '../widgets/voice_analysis_step.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/welcome_step.dart';
import '../widgets/record_step.dart';
import '../widgets/analyze_step.dart';
import '../widgets/results_step.dart';
import '../widgets/accent_twin_step.dart';

class VoiceAnalysisPage extends ConsumerStatefulWidget {
  final bool isOnboardingContext;

  const VoiceAnalysisPage({
    super.key,
    this.isOnboardingContext = false,
  });

  @override
  ConsumerState<VoiceAnalysisPage> createState() => _VoiceAnalysisPageState();
}

class _VoiceAnalysisPageState extends ConsumerState<VoiceAnalysisPage> {
  VoiceAnalysisStep _currentStep = VoiceAnalysisStep.welcome;
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(voiceRecordingProvider);
    final analysisState = ref.watch(voiceAnalysisProvider);
    final accentTwinState = ref.watch(accentTwinProvider);
    final audioPlaybackState = ref.watch(audioPlaybackProvider);

    // Initialize step based on existing state (only once)
    if (!_hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeStep(recordingState, analysisState);
      });
      _hasInitialized = true;
    }

    // Auto-advance steps based on state changes
    if (_currentStep == VoiceAnalysisStep.record && recordingState.hasRecording && !recordingState.isRecording) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentStep = VoiceAnalysisStep.analyze;
        });
        // Trigger voice analysis when moving to analyze step
        if (recordingState.recordingPath != null) {
          ref.read(voiceAnalysisProvider.notifier).analyzeVoice(recordingState.recordingPath!);
        }
      });
    }
    if (_currentStep == VoiceAnalysisStep.analyze && analysisState.hasValue && analysisState.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentStep = VoiceAnalysisStep.results;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Analysis'),
        leading: _currentStep != VoiceAnalysisStep.welcome
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentStep = VoiceAnalysisStep.values[_currentStep.index - 1];
                  });
                },
              )
            : null,
        actions: [
          if (recordingState.hasRecording)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(voiceRecordingProvider.notifier).clearRecording();
                ref.read(voiceAnalysisProvider.notifier).clearAnalysis();
                ref.read(accentTwinProvider.notifier).clearAccentTwin();
                setState(() {
                  _currentStep = VoiceAnalysisStep.welcome;
                });
              },
              tooltip: 'Start over',
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          VoiceAnalysisProgressIndicator(currentStep: _currentStep),

          // Step content
          Expanded(
            child: _buildStepContent(
              recordingState: recordingState,
              analysisState: analysisState,
              accentTwinState: accentTwinState,
              audioPlaybackState: audioPlaybackState,
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildStepContent({
    required VoiceRecordingState recordingState,
    required AsyncValue<VoiceAnalysis?> analysisState,
    required AsyncValue<AccentTwin?> accentTwinState,
    required AudioPlaybackState audioPlaybackState,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildCurrentStepContent(
          recordingState: recordingState,
          analysisState: analysisState,
          accentTwinState: accentTwinState,
          audioPlaybackState: audioPlaybackState,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent({
    required VoiceRecordingState recordingState,
    required AsyncValue<VoiceAnalysis?> analysisState,
    required AsyncValue<AccentTwin?> accentTwinState,
    required AudioPlaybackState audioPlaybackState,
  }) {
    switch (_currentStep) {
      case VoiceAnalysisStep.welcome:
        return WelcomeStep(
          onStart: () => setState(() => _currentStep = VoiceAnalysisStep.record),
        );

      case VoiceAnalysisStep.record:
        return RecordStep(
          recordingState: recordingState,
          onRecordingComplete: () => setState(() => _currentStep = VoiceAnalysisStep.analyze),
        );

      case VoiceAnalysisStep.analyze:
        return AnalyzeStep(
          recordingState: recordingState,
          analysisState: analysisState,
          onAnalysisComplete: () => setState(() => _currentStep = VoiceAnalysisStep.results),
        );

      case VoiceAnalysisStep.results:
        return ResultsStep(
          analysisState: analysisState,
          onCreateAccentTwin: () => setState(() => _currentStep = VoiceAnalysisStep.accentTwin),
          onRetakeAnalysis: () {
            // Clear existing recording and analysis, go back to record step
            ref.read(voiceRecordingProvider.notifier).clearRecording();
            ref.read(voiceAnalysisProvider.notifier).clearAnalysis();
            ref.read(accentTwinProvider.notifier).clearAccentTwin();
            setState(() {
              _currentStep = VoiceAnalysisStep.record;
            });
          },
          isOnboardingContext: widget.isOnboardingContext,
        );

      case VoiceAnalysisStep.accentTwin:
        return AccentTwinStep(
          analysisState: analysisState,
          accentTwinState: accentTwinState,
          audioPlaybackState: audioPlaybackState,
          currentSample: ref.read(voiceAnalysisProvider.notifier).currentSample,
        );
    }
  }

  void _initializeStep(VoiceRecordingState recordingState, AsyncValue<VoiceAnalysis?> analysisState) {
    // If user has both recording and analysis, show results step with option to retake
    if (recordingState.hasRecording && analysisState.hasValue && analysisState.value != null) {
      setState(() {
        _currentStep = VoiceAnalysisStep.results;
      });
    }
    // If user has recording but no analysis, go to analyze step
    else if (recordingState.hasRecording && !recordingState.isRecording) {
      setState(() {
        _currentStep = VoiceAnalysisStep.analyze;
      });
      // Trigger analysis
      if (recordingState.recordingPath != null) {
        ref.read(voiceAnalysisProvider.notifier).analyzeVoice(recordingState.recordingPath!);
      }
    }
    // If user has no recording, show welcome step
    else {
      setState(() {
        _currentStep = VoiceAnalysisStep.welcome;
      });
    }
  }
}
