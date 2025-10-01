import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';
import '../../../../core/models/voice_models.dart';

class AccentTwinStep extends ConsumerStatefulWidget {
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
  ConsumerState<AccentTwinStep> createState() => _AccentTwinStepState();
}

class _AccentTwinStepState extends ConsumerState<AccentTwinStep> {
  final TextEditingController _textController = TextEditingController();
  String _selectedAccent = 'US';
  bool _isHiFiMode = true; // Hi-Fi (twin) vs Generic mode
  bool _showComparison = false;
  String? _lastSelectedAccent;

  @override
  void initState() {
    super.initState();
    _textController.text = 'The quick brown fox jumps over the lazy dog.';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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

        // Mode Toggle and Text Input
        _buildControlsSection(context, ref),
        const SizedBox(height: 24),

        // Accent selection
        if (widget.currentSample != null) ...[
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
                        isSelected: _selectedAccent == 'US',
                        onTap: () => _selectAccent('US', ref),
                        isLoading: accentTwinState.isLoading && _selectedAccent == 'US',
                      ),
                      _AccentOptionCard(
                        flag: '🇬🇧',
                        name: 'British',
                        code: 'UK',
                        isSelected: _selectedAccent == 'UK',
                        onTap: () => _selectAccent('UK', ref),
                        isLoading: accentTwinState.isLoading && _selectedAccent == 'UK',
                      ),
                      _AccentOptionCard(
                        flag: '🇦🇺',
                        name: 'Australian',
                        code: 'AU',
                        isSelected: _selectedAccent == 'AU',
                        onTap: () => _selectAccent('AU', ref),
                        isLoading: accentTwinState.isLoading && _selectedAccent == 'AU',
                      ),
                      _AccentOptionCard(
                        flag: '🇨🇦',
                        name: 'Canadian',
                        code: 'CA',
                        isSelected: _selectedAccent == 'CA',
                        onTap: () => _selectAccent('CA', ref),
                        isLoading: accentTwinState.isLoading && _selectedAccent == 'CA',
                      ),
                      _AccentOptionCard(
                        flag: '🇮🇪',
                        name: 'Irish',
                        code: 'IE',
                        isSelected: _selectedAccent == 'IE',
                        onTap: () => _selectAccent('IE', ref),
                        isLoading: accentTwinState.isLoading && _selectedAccent == 'IE',
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

        // Generation status and result
        if (widget.accentTwinState.hasValue && widget.accentTwinState.value != null) ...[
          const SizedBox(height: 24),
          _AccentTwinResultCard(
            accentTwin: widget.accentTwinState.value!,
            audioPlaybackState: widget.audioPlaybackState,
            onPlay: (url) => ref.read(accentTwinProvider.notifier).playAccentTwin(url),
            onPause: () => ref.read(accentTwinProvider.notifier).pauseAccentTwinPlayback(),
            onResume: () => ref.read(accentTwinProvider.notifier).resumeAccentTwinPlayback(),
            onStop: () => ref.read(accentTwinProvider.notifier).stopAccentTwinPlayback(),
            onRefresh: () {
              final accentTwinId = widget.accentTwinState.value?.id;
              if (accentTwinId != null) {
                ref.read(accentTwinProvider.notifier).refreshAccentTwin(accentTwinId);
              }
            },
            onToggleComparison: () => setState(() => _showComparison = !_showComparison),
            showComparison: _showComparison,
          ),
        ],

        // Loading state
        if (widget.accentTwinState.isLoading) ...[
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
        if (widget.accentTwinState.hasError) ...[
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
                    widget.accentTwinState.error.toString(),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.currentSample != null) {
                        // Retry with the last selected accent
                        ref.read(accentTwinProvider.notifier)
                            .generateAccentTwin(widget.currentSample!.id, _selectedAccent);
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

  Widget _buildControlsSection(BuildContext context, WidgetRef ref) {
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
            // Mode Toggle
            Row(
              children: [
                Text(
                  'Mode:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('Hi-Fi'),
                  selected: _isHiFiMode,
                  onSelected: (selected) => setState(() => _isHiFiMode = selected),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Generic'),
                  selected: !_isHiFiMode,
                  onSelected: (selected) => setState(() => _isHiFiMode = !selected),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Input
            Text(
              'Text',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Type or pick a phrase...',
                suffixIcon: PopupMenuButton<String>(
                  onSelected: (phrase) => setState(() => _textController.text = phrase),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'The quick brown fox jumps over the lazy dog.', child: Text('Ship-Sheep')),
                    const PopupMenuItem(value: 'Full-Fool', child: Text('Full-Fool')),
                    const PopupMenuItem(value: 'Stress patterns in English', child: Text('Stress')),
                  ],
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Quick Phrase Buttons
            Text(
              'Quick Phrases',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _textController.text = 'The quick brown fox jumps over the lazy dog.'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Ship-Sheep'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _textController.text = 'Full-Fool'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Full-Fool'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _textController.text = 'Stress patterns in English'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Stress'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectAccent(String accent, WidgetRef ref) {
    setState(() => _selectedAccent = accent);
    if (widget.currentSample != null) {
      ref.read(accentTwinProvider.notifier).generateAccentTwin(
        widget.currentSample!.id,
        accent,
      );
    }
  }
}

class _AccentOptionCard extends StatelessWidget {
  final String flag;
  final String name;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const _AccentOptionCard({
    required this.flag,
    required this.name,
    required this.code,
    this.isSelected = false,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                )
              : null,
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
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ] else if (isLoading) ...[
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
  final VoidCallback onToggleComparison;
  final bool showComparison;

  const _AccentTwinResultCard({
    required this.accentTwin,
    required this.audioPlaybackState,
    required this.onPlay,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onRefresh,
    required this.onToggleComparison,
    required this.showComparison,
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

            // A/B Comparison Toggle
            if (accentTwin.isReady == true) ...[
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: onToggleComparison,
                  icon: Icon(showComparison ? Icons.toggle_on : Icons.toggle_off, size: 18),
                  label: Text(showComparison ? 'Hide Comparison' : 'A/B Compare'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),

              // A/B Comparison Section
              if (showComparison) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'A/B Comparison',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ComparisonButton(
                              label: 'Original',
                              onPressed: () {
                                // Play original recording
                                // This would need access to the original voice sample
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ComparisonButton(
                              label: 'Accent Twin',
                              onPressed: () {
                                if (accentTwin.fileUrl != null) {
                                  onPlay(accentTwin.fileUrl!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],

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

class _ComparisonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ComparisonButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
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