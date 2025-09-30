import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';
import '../../../../core/models/voice_models.dart';

class AccentTwinStep extends ConsumerWidget {
  final AsyncValue<VoiceAnalysis?> analysisState;
  final AsyncValue<AccentTwin?> accentTwinState;
  final AudioPlaybackState audioPlaybackState;
  final VoiceSample? currentSample;

  const AccentTwinStep({
    super.key,
    required this.analysisState,
    required this.accentTwinState,
    required this.audioPlaybackState,
    required this.currentSample,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5: Create Accent Twin',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Generate your voice speaking in different accents',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // Accent selection
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_pin,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Choose Target Accent',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an accent to transform your voice into',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                if (currentSample != null) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _AccentOptionCard(
                        flag: '🇺🇸',
                        name: 'American',
                        code: 'US',
                        onTap: () => ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(currentSample!.id, 'US'),
                        isLoading: accentTwinState.isLoading,
                      ),
                      _AccentOptionCard(
                        flag: '🇬🇧',
                        name: 'British',
                        code: 'UK',
                        onTap: () => ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(currentSample!.id, 'UK'),
                        isLoading: accentTwinState.isLoading,
                      ),
                      _AccentOptionCard(
                        flag: '🇦🇺',
                        name: 'Australian',
                        code: 'AU',
                        onTap: () => ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(currentSample!.id, 'AU'),
                        isLoading: accentTwinState.isLoading,
                      ),
                      _AccentOptionCard(
                        flag: '🇨🇦',
                        name: 'Canadian',
                        code: 'CA',
                        onTap: () => ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(currentSample!.id, 'CA'),
                        isLoading: accentTwinState.isLoading,
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete voice analysis first to create accent twins.',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Generation status and result
        if (accentTwinState.hasValue && accentTwinState.value != null) ...[
          const SizedBox(height: 24),
          _AccentTwinResultCard(
            accentTwin: accentTwinState.value!,
            audioPlaybackState: audioPlaybackState,
            onPlay: (url) => ref.read(accentTwinProvider.notifier).playAccentTwin(url),
            onPause: () => ref.read(accentTwinProvider.notifier).pauseAccentTwinPlayback(),
            onResume: () => ref.read(accentTwinProvider.notifier).resumeAccentTwinPlayback(),
            onStop: () => ref.read(accentTwinProvider.notifier).stopAccentTwinPlayback(),
            onRefresh: () {
              final accentTwinId = accentTwinState.value?.id;
              if (accentTwinId != null) {
                ref.read(accentTwinProvider.notifier).refreshAccentTwin(accentTwinId);
              }
            },
          ),
        ],

        // Loading state
        if (accentTwinState.isLoading) ...[
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Generating your accent twin...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Error state
        if (accentTwinState.hasError) ...[
          const SizedBox(height: 24),
          Card(
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Generation Failed',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accentTwinState.error.toString(),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (currentSample != null) {
                        // Retry with the same accent (you might want to store the last selected accent)
                        ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(currentSample!.id, 'US'); // Default to US
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccentOptionCard extends StatelessWidget {
  final String flag;
  final String name;
  final String code;
  final VoidCallback onTap;
  final bool isLoading;

  const _AccentOptionCard({
    required this.flag,
    required this.name,
    required this.code,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLoading ? Colors.grey : Colors.black,
                ),
              ),
              Text(
                code,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentTwinResultCard extends StatelessWidget {
  final AccentTwin accentTwin;
  final AudioPlaybackState audioPlaybackState;
  final Function(String) onPlay;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onRefresh;

  const _AccentTwinResultCard({
    required this.accentTwin,
    required this.audioPlaybackState,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accent Twin Ready!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Your voice transformed into ${accentTwin.targetAccent.toUpperCase()} accent',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Audio controls
            if (accentTwin.isReady == true && accentTwin.fileUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Listen to your transformed voice',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your voice transformed into ${accentTwin.targetAccent.toUpperCase()} accent',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Listen to your transformed voice',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (audioPlaybackState.currentAudioUrl == accentTwin.fileUrl) ...[
                          if (audioPlaybackState.isPlaying) ...[
                            ElevatedButton.icon(
                              onPressed: onPause,
                              icon: const Icon(Icons.pause, size: 18),
                              label: const Text('Pause'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: onStop,
                              icon: const Icon(Icons.stop, size: 18),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ] else if (audioPlaybackState.isPaused) ...[
                            ElevatedButton.icon(
                              onPressed: onResume,
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Resume'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: onStop,
                              icon: const Icon(Icons.stop, size: 18),
                              label: const Text('Stop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ]
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => onPlay(accentTwin.fileUrl!),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Play Accent Twin'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Details
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: 'Target Accent',
                    value: accentTwin.targetAccent.toUpperCase(),
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    label: 'Provider',
                    value: accentTwin.ttsProvider.toUpperCase(),
                  ),
                ),
              ],
            ),

            if (accentTwin.processingTime != null) ...[
              const SizedBox(height: 8),
              _DetailItem(
                label: 'Processing Time',
                value: '${accentTwin.processingTime!.toStringAsFixed(1)}s',
              ),
            ],

            if (accentTwin.similarityScore != null) ...[
              const SizedBox(height: 8),
              _DetailItem(
                label: 'Similarity Score',
                value: '${(accentTwin.similarityScore! * 100).toStringAsFixed(1)}%',
              ),
            ],

            const SizedBox(height: 16),

            // Refresh button
            Center(
              child: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}