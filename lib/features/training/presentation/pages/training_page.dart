import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/voice_models.dart';
import '../../../../core/providers/voice_provider.dart';

class TrainingPage extends ConsumerStatefulWidget {
  const TrainingPage({super.key});

  @override
  ConsumerState<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends ConsumerState<TrainingPage> {
  @override
  void initState() {
    super.initState();
    // Load training sessions when page opens
    _loadTrainingSessions();
  }

  Future<void> _loadTrainingSessions() async {
    try {
      await ref.read(voiceApiServiceProvider).getTrainingSessions();
    } catch (e) {
      debugPrint('Error loading training sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(voiceAnalysisProvider);
    final hasAnalysis = analysisState.hasValue && analysisState.value != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: hasAnalysis ? _showCreateSessionDialog : null,
            tooltip: 'Create Training Session',
          ),
        ],
      ),
      body: hasAnalysis ? _buildTrainingContent() : _buildNoAnalysisView(),
    );
  }

  Widget _buildTrainingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose Your Training',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a training type or continue an existing session',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Start Section
          _buildQuickStartSection(),
          const SizedBox(height: 24),

          // Training Types
          Expanded(
            child: _buildTrainingTypesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Start',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Start a personalized practice session based on your voice analysis',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _createPersonalizedSession(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Start Personalized Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingTypesList() {
    return ListView.builder(
      itemCount: TrainingType.values.length,
      itemBuilder: (context, index) {
        final trainingType = TrainingType.values[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                _getTrainingIcon(trainingType),
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              trainingType.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(_getTrainingDescription(trainingType)),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _startTrainingType(trainingType),
          ),
        );
      },
    );
  }

  Widget _buildNoAnalysisView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Complete Voice Analysis First',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyze your voice to unlock personalized training sessions.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/voice-analysis'),
            icon: const Icon(Icons.analytics),
            label: const Text('Go to Voice Analysis'),
          ),
        ],
      ),
    );
  }

  void _showCreateSessionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Training Session'),
        content: const Text('Choose how you want to create your training session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createPersonalizedSession();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPersonalizedSession() async {
    try {
      final analysis = ref.read(voiceAnalysisProvider).value;
      if (analysis == null) return;

      // Create a personalized training session
      final sessionData = {
        'name': 'Personalized ${analysis.detectedAccent.toUpperCase()} Training',
        'exercise_type': 'pronunciation',
        'target_accent': analysis.detectedAccent,
      };

      final session = await ref.read(voiceApiServiceProvider).createTrainingSession(sessionData);

      if (mounted) {
        context.go('/training-session/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    }
  }

  void _startTrainingType(TrainingType trainingType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting ${trainingType.displayName} training...'),
        action: SnackBarAction(
          label: 'Continue',
          onPressed: () => _createTrainingSession(trainingType),
        ),
      ),
    );
  }

  Future<void> _createTrainingSession(TrainingType trainingType) async {
    try {
      final sessionData = {
        'name': '${trainingType.displayName} Practice',
        'exercise_type': trainingType.value,
        'target_accent': 'US', // Default, should be from user profile
      };

      final session = await ref.read(voiceApiServiceProvider).createTrainingSession(sessionData);

      if (mounted) {
        context.go('/training-session/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
      }
    }
  }

  IconData _getTrainingIcon(TrainingType type) {
    switch (type) {
      case TrainingType.pronunciation:
        return Icons.record_voice_over;
      case TrainingType.rhythm:
        return Icons.graphic_eq;
      case TrainingType.intonation:
        return Icons.trending_up;
      case TrainingType.stress:
        return Icons.compress;
      case TrainingType.connectedSpeech:
        return Icons.link;
    }
  }

  String _getTrainingDescription(TrainingType type) {
    switch (type) {
      case TrainingType.pronunciation:
        return 'Practice individual sounds and phonemes';
      case TrainingType.rhythm:
        return 'Master the timing and flow of speech';
      case TrainingType.intonation:
        return 'Learn pitch patterns and melody';
      case TrainingType.stress:
        return 'Practice word and sentence stress';
      case TrainingType.connectedSpeech:
        return 'Learn how words connect in natural speech';
    }
  }
}
