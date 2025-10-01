import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/services/voice_api_service.dart';
import '../../../../core/di/injection_container.dart';

enum TrainingStep { listen, record, compare }

class TrainingSessionPage extends ConsumerStatefulWidget {
  final String sessionId;

  const TrainingSessionPage({super.key, required this.sessionId});

  @override
  ConsumerState<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends ConsumerState<TrainingSessionPage> {
  TrainingStep _currentStep = TrainingStep.listen;
  String? _practiceAudioUrl;
  bool _isGeneratingAudio = false;

  @override
  void initState() {
    super.initState();
    _loadSessionAndGenerateAudio();
  }

  Future<void> _loadSessionAndGenerateAudio() async {
    try {
      setState(() => _isGeneratingAudio = true);

      // Load the training session
      final session = await ref.read(voiceApiServiceProvider).getTrainingSession(int.parse(widget.sessionId));

      // Generate practice audio for the session
      final audioResponse = await ref.read(voiceApiServiceProvider).generatePracticeAudio(
        int.parse(widget.sessionId),
        {'text': 'The quick brown fox jumps over the lazy dog.'},
      );

      setState(() {
        _practiceAudioUrl = audioResponse.audioUrl;
        _isGeneratingAudio = false;
      });
    } catch (e) {
      setState(() => _isGeneratingAudio = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isGeneratingAudio ? _buildLoadingView() : _buildTrainingContent(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Preparing your training session...'),
        ],
      ),
    );
  }

  Widget _buildTrainingContent() {
    return Column(
      children: [
        // Progress indicator
        _buildProgressHeader(),

        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildCurrentStepContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: TrainingStep.values.map((step) {
          final stepIndex = step.index;
          final isCompleted = stepIndex < _currentStep.index;
          final isCurrent = stepIndex == _currentStep.index;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                if (stepIndex < TrainingStep.values.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: stepIndex < _currentStep.index ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case TrainingStep.listen:
        return _ListenStep(
          audioUrl: _practiceAudioUrl,
          onContinue: () => setState(() => _currentStep = TrainingStep.record),
        );

      case TrainingStep.record:
        return _RecordStep(
          onRecordingComplete: () => setState(() => _currentStep = TrainingStep.compare),
        );

      case TrainingStep.compare:
        return _CompareStep(
          onTryAgain: () => setState(() => _currentStep = TrainingStep.record),
          onGetFeedback: () => _showFeedbackDialog(),
          onSaveSession: () => _saveSession(),
        );
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instant Feedback'),
        content: const Text('AI feedback and suggestions would appear here based on your recording.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSession() async {
    try {
      await ref.read(voiceApiServiceProvider).completeTrainingSession(int.parse(widget.sessionId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save session: $e')),
        );
      }
    }
  }
}

// Step 1: Listen
class _ListenStep extends StatelessWidget {
  final String? audioUrl;
  final VoidCallback onContinue;

  const _ListenStep({required this.audioUrl, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.headphones,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Step 1: Listen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Listen carefully to the target pronunciation',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Audio player placeholder
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Icon(
                Icons.play_circle_filled,
                size: 64,
                color: Colors.blue.shade600,
              ),
              const SizedBox(height: 12),
              Text(
                'Target Pronunciation',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The quick brown fox jumps over the lazy dog.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.mic),
            label: const Text('I\'m Ready to Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Step 2: Record
class _RecordStep extends ConsumerWidget {
  final VoidCallback onRecordingComplete;

  const _RecordStep({required this.onRecordingComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(voiceRecordingProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mic,
          size: 80,
          color: recordingState.isRecording ? Colors.red : Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Step 2: Record',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Repeat what you heard in your natural voice',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Recording button
        GestureDetector(
          onTap: () {
            if (recordingState.isRecording) {
              ref.read(voiceRecordingProvider.notifier).stopRecording();
              onRecordingComplete();
            } else {
              ref.read(voiceRecordingProvider.notifier).startRecording();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: recordingState.isRecording ? 200 : 180,
            height: recordingState.isRecording ? 200 : 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: recordingState.isRecording
                    ? [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.3)]
                    : [Theme.of(context).primaryColor.withOpacity(0.2), Theme.of(context).primaryColor.withOpacity(0.3)],
              ),
              border: Border.all(
                color: recordingState.isRecording ? Colors.red : Theme.of(context).primaryColor,
                width: 4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  recordingState.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 80,
                  color: recordingState.isRecording ? Colors.red : Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  recordingState.isRecording ? 'STOP' : 'RECORD',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: recordingState.isRecording ? Colors.red : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Recording status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(recordingState).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(recordingState).withOpacity(0.3),
            ),
          ),
          child: Text(
            _getStatusText(recordingState),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(recordingState),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(VoiceRecordingState state) {
    if (state.errorMessage != null) return Colors.red;
    switch (state.status) {
      case RecordingStatus.recording:
        return Colors.red;
      case RecordingStatus.stopped:
        return state.hasRecording ? Colors.green : Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusText(VoiceRecordingState state) {
    if (state.errorMessage != null) return 'Error occurred';
    switch (state.status) {
      case RecordingStatus.recording:
        return 'Recording... Speak naturally';
      case RecordingStatus.stopped:
        return state.hasRecording ? 'Recording complete!' : 'Tap to start recording';
      default:
        return 'Ready to record';
    }
  }
}

// Step 3: Compare
class _CompareStep extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onGetFeedback;
  final VoidCallback onSaveSession;

  const _CompareStep({
    required this.onTryAgain,
    required this.onGetFeedback,
    required this.onSaveSession,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.compare_arrows,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Step 3: Compare',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare your recording with the target pronunciation',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // A/B Comparison
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            children: [
              Text(
                'A/B Comparison',
                style: TextStyle(
                  color: Colors.purple.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ComparisonButton(
                      label: 'Target',
                      color: Colors.blue,
                      onPressed: () {
                        // Play target audio
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ComparisonButton(
                      label: 'Your Recording',
                      color: Colors.green,
                      onPressed: () {
                        // Play user recording
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTryAgain,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onGetFeedback,
                icon: const Icon(Icons.lightbulb),
                label: const Text('Get Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onSaveSession,
            icon: const Icon(Icons.save),
            label: const Text('Save Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ComparisonButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color.shade800,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Text(label),
    );
  }
}
