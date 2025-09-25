import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/voice_models.dart';

class TrainingPage extends ConsumerWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
      ),
      body: Padding(
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: TrainingType.values.length,
                itemBuilder: (context, index) {
                  final trainingType = TrainingType.values[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          _getTrainingIcon(trainingType),
                          color: Colors.blue.shade700,
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
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${trainingType.displayName} training coming soon!'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
