import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/voice_provider.dart';
import '../widgets/accent_twin_step.dart';

class AccentTwinPage extends ConsumerWidget {
  final String analysisId;

  const AccentTwinPage({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(voiceAnalysisProvider);
    final accentTwinState = ref.watch(accentTwinProvider);
    final audioPlaybackState = ref.watch(audioPlaybackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accent Twin Generation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/voice-analysis'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'About Accent Twins',
          ),
        ],
      ),
      body: analysisState.when(
        data: (analysis) {
          if (analysis == null) {
            return _buildNoAnalysisView(context);
          }

          return AccentTwinStep(
            analysisState: analysisState,
            accentTwinState: accentTwinState,
            audioPlaybackState: audioPlaybackState,
            currentSample: ref.read(voiceAnalysisProvider.notifier).currentSample,
          );
        },
        loading: () => _buildLoadingView(),
        error: (error, stack) => _buildErrorView(context, error),
      ),
    );
  }

  Widget _buildNoAnalysisView(BuildContext context) {
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
            'No Voice Analysis Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete voice analysis first to generate accent twins.',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/voice-analysis'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go to Voice Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading voice analysis...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/voice-analysis'),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Accent Twins'),
        content: const Text(
          'Accent Twins use advanced AI to generate synthetic versions of your voice speaking in perfect target accents. '
          'This revolutionary technology allows you to hear exactly how you would sound with different accents, '
          'making pronunciation training more effective and personalized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
