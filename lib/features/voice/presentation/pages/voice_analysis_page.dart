import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';

class VoiceAnalysisPage extends ConsumerWidget {
  const VoiceAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(voiceRecordingProvider);
    final analysisState = ref.watch(voiceAnalysisProvider);
    final accentTwinState = ref.watch(accentTwinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Analysis'),
        actions: [
          if (recordingState.hasRecording)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(voiceRecordingProvider.notifier).clearRecording();
                ref.read(voiceAnalysisProvider.notifier).clearAnalysis();
                ref.read(accentTwinProvider.notifier).clearAccentTwin();
              },
              tooltip: 'Clear and start over',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Recording Section
            Expanded(
              flex: 2,
              child: _RecordingSection(recordingState: recordingState),
            ),
            
            const SizedBox(height: 24),
            
            // Analysis Button
            if (recordingState.hasRecording && !recordingState.isRecording)
              _AnalyzeButton(
                onPressed: () {
                  if (recordingState.recordingPath != null) {
                    ref.read(voiceAnalysisProvider.notifier)
                        .analyzeVoice(recordingState.recordingPath!);
                  }
                },
                isLoading: analysisState.isLoading,
              ),
            
            const SizedBox(height: 24),
            
            // Analysis Results
            Expanded(
              flex: 3,
              child: _AnalysisResults(
                analysisState: analysisState,
                accentTwinState: accentTwinState,
                onGenerateAccentTwin: (sampleId, targetAccent) {
                  ref.read(accentTwinProvider.notifier)
                      .generateAccentTwin(sampleId, targetAccent);
                },
                currentSample: ref.read(voiceAnalysisProvider.notifier).currentSample,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingSection extends ConsumerWidget {
  final VoiceRecordingState recordingState;

  const _RecordingSection({required this.recordingState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recording Button
          Container(
            width: 200,
            height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: recordingState.isRecording 
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            border: Border.all(
              color: recordingState.isRecording ? Colors.red : Colors.blue,
              width: 4,
            ),
          ),
          child: IconButton(
            iconSize: 80,
            icon: Icon(
              recordingState.isRecording ? Icons.stop : Icons.mic,
              color: recordingState.isRecording ? Colors.red : Colors.blue,
            ),
            onPressed: () {
              if (recordingState.isRecording) {
                ref.read(voiceRecordingProvider.notifier).stopRecording();
              } else {
                ref.read(voiceRecordingProvider.notifier).startRecording();
              }
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Status Text
        Text(
          _getStatusText(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Recording Duration
        if (recordingState.isRecording)
          Text(
            _formatDuration(recordingState.recordingDuration),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
        
        // Audio Level Indicator
        if (recordingState.isRecording && recordingState.audioLevel != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            height: 8,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade300,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (recordingState.audioLevel! + 40) / 40, // Normalize audio level
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green,
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Playback Controls
        if (recordingState.hasRecording && !recordingState.isRecording)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: recordingState.isPlaying
                    ? () => ref.read(voiceRecordingProvider.notifier).stopPlayback()
                    : () => ref.read(voiceRecordingProvider.notifier).playRecording(),
                icon: Icon(recordingState.isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(recordingState.isPlaying ? 'Stop' : 'Play'),
              ),
            ],
          ),
        
        // Error Message
        if (recordingState.errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              recordingState.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
      ),
    );
  }

  String _getStatusText() {
    if (recordingState.errorMessage != null) {
      return 'Error occurred';
    }
    
    switch (recordingState.status) {
      case RecordingStatus.idle:
        return 'Tap the microphone to start recording';
      case RecordingStatus.recording:
        return 'Recording... Tap to stop';
      case RecordingStatus.stopped:
        return recordingState.hasRecording 
            ? 'Recording ready for analysis'
            : 'Tap the microphone to start recording';
      case RecordingStatus.playing:
        return 'Playing recording...';
      case RecordingStatus.analyzing:
        return 'Analyzing recording...';
      case RecordingStatus.analyzed:
        return 'Recording analyzed successfully';
      case RecordingStatus.error:
        return 'Error occurred';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _AnalyzeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _AnalyzeButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Analyzing...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text('Analyze Voice', style: TextStyle(fontSize: 16)),
                ],
              ),
      ),
    );
  }
}

class _AnalysisResults extends ConsumerWidget {
  final AsyncValue<VoiceAnalysis?> analysisState;
  final AsyncValue<AccentTwin?> accentTwinState;
  final Function(int, String) onGenerateAccentTwin;
  final VoiceSample? currentSample;

  const _AnalysisResults({
    required this.analysisState,
    required this.accentTwinState,
    required this.onGenerateAccentTwin,
    required this.currentSample,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return analysisState.when(
      data: (analysis) {
        if (analysis == null) {
          return const Center(
            child: Text(
              'Record your voice and tap "Analyze Voice" to see detailed analysis of your accent.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Analysis Results Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Analysis Results',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Detected Accent
                      _ResultRow(
                        label: 'Detected Accent',
                        value: analysis.detectedAccent.toUpperCase(),
                        icon: Icons.flag,
                      ),
                      
                      // Confidence Score
                      _ResultRow(
                        label: 'Confidence',
                        value: '${(analysis.confidence * 100).toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                      ),
                      
                      // Audio Quality
                      _ResultRow(
                        label: 'Audio Quality',
                        value: '${(analysis.audioQuality * 100).toStringAsFixed(1)}%',
                        icon: Icons.high_quality,
                      ),
                      
                      // Duration
                      _ResultRow(
                        label: 'Duration',
                        value: '${analysis.duration.toStringAsFixed(1)}s',
                        icon: Icons.timer,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transcription Card
              if (analysis.transcription.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Transcription',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 120),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              analysis.transcription,
                              style: const TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Accent Twin Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Generate Accent Twin',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Generate your voice speaking in different accents:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      // Accent Options
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (currentSample != null) ...[
                            _AccentChip(
                              label: 'US 🇺🇸',
                              accent: 'us',
                              onTap: () => onGenerateAccentTwin(currentSample!.id, 'US'),
                              isLoading: accentTwinState.isLoading,
                            ),
                            _AccentChip(
                              label: 'UK 🇬🇧',
                              accent: 'uk',
                              onTap: () => onGenerateAccentTwin(currentSample!.id, 'UK'),
                              isLoading: accentTwinState.isLoading,
                            ),
                            _AccentChip(
                              label: 'AU 🇦🇺',
                              accent: 'au',
                              onTap: () => onGenerateAccentTwin(currentSample!.id, 'AU'),
                              isLoading: accentTwinState.isLoading,
                            ),
                            _AccentChip(
                              label: 'CA 🇨🇦',
                              accent: 'ca',
                              onTap: () => onGenerateAccentTwin(currentSample!.id, 'CA'),
                              isLoading: accentTwinState.isLoading,
                            ),
                          ] else
                            const Text(
                              'Upload and analyze a voice sample first to generate accent twins.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                      
                      // Accent Twin Result
                      if (accentTwinState.hasValue && accentTwinState.value != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Accent Twin Generated!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Target Accent: ${accentTwinState.value!.targetAccent.toUpperCase()}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (accentTwinState.value!.similarityScore != null)
                                Text(
                                  'Similarity Score: ${(accentTwinState.value!.similarityScore! * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      
                      // Accent Twin Loading
                      if (accentTwinState.isLoading)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Generating accent twin...',
                                style: TextStyle(color: Colors.blue.shade800),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your voice...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
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
              'Analysis failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(voiceAnalysisProvider.notifier).clearAnalysis(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  final String label;
  final String accent;
  final VoidCallback onTap;
  final bool isLoading;

  const _AccentChip({
    required this.label,
    required this.accent,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: isLoading ? null : onTap,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
    );
  }
}
