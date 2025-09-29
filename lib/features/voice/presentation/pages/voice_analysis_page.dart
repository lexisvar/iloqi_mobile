import 'dart:ui';
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
    final audioPlaybackState = ref.watch(audioPlaybackProvider);

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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recording Button with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: recordingState.isRecording ? 220 : 200,
            height: recordingState.isRecording ? 220 : 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: recordingState.isRecording 
                    ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.2)]
                    : [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: recordingState.isRecording ? Colors.red : Colors.blue,
                width: 3,
              ),
              boxShadow: [
                if (recordingState.isRecording)
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(200),
                onTap: () {
                  if (recordingState.isRecording) {
                    ref.read(voiceRecordingProvider.notifier).stopRecording();
                  } else {
                    ref.read(voiceRecordingProvider.notifier).startRecording();
                  }
                },
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    recordingState.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 80,
                    color: recordingState.isRecording ? Colors.red : Colors.blue,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Status Text with better styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(recordingState).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _getStatusColor(recordingState).withOpacity(0.3),
              ),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(recordingState),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recording Duration with better styling
          if (recordingState.isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDuration(recordingState.recordingDuration),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
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

  Color _getStatusColor() {
    if (recordingState.errorMessage != null) {
      return Colors.red;
    }
    
    switch (recordingState.status) {
      case RecordingStatus.idle:
        return Colors.grey[600]!;
      case RecordingStatus.recording:
        return Colors.red;
      case RecordingStatus.stopped:
        return recordingState.hasRecording 
            ? Colors.green
            : Colors.grey[600]!;
      case RecordingStatus.playing:
        return Colors.blue;
      case RecordingStatus.analyzing:
        return Colors.orange;
      case RecordingStatus.analyzed:
        return Colors.green;
      case RecordingStatus.error:
        return Colors.red;
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
                        _AccentTwinResult(
                          accentTwin: accentTwinState.value!,
                          audioPlaybackState: audioPlaybackState,
                          onPlayAccentTwin: (audioUrl) {
                            ref.read(accentTwinProvider.notifier).playAccentTwin(audioUrl);
                          },
                          onPauseAccentTwin: () {
                            ref.read(accentTwinProvider.notifier).pauseAccentTwinPlayback();
                          },
                          onResumeAccentTwin: () {
                            ref.read(accentTwinProvider.notifier).resumeAccentTwinPlayback();
                          },
                          onStopAccentTwin: () {
                            ref.read(accentTwinProvider.notifier).stopAccentTwinPlayback();
                          },
                          onRefresh: () {
                            final accentTwinId = accentTwinState.value?.id;
                            if (accentTwinId != null) {
                              ref.read(accentTwinProvider.notifier)
                                  .refreshAccentTwin(accentTwinId);
                            }
                          },
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
      loading: () => const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your voice...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Expanded(
        child: SingleChildScrollView(
          child: Center(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(voiceAnalysisProvider.notifier).clearAnalysis(),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
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

class _AccentTwinResult extends StatelessWidget {
  final AccentTwin accentTwin;
  final Function(String) onPlayAccentTwin;
  final VoidCallback onPauseAccentTwin;
  final VoidCallback onResumeAccentTwin;
  final VoidCallback onStopAccentTwin;
  final VoidCallback onRefresh;
  final AudioPlaybackState audioPlaybackState;

  const _AccentTwinResult({
    required this.accentTwin,
    required this.onPlayAccentTwin,
    required this.onPauseAccentTwin,
    required this.onResumeAccentTwin,
    required this.onStopAccentTwin,
    required this.onRefresh,
    required this.audioPlaybackState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              Icon(_getStatusIcon(), color: _getStatusColor(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(context),
                  ),
                ),
              ),
              if (accentTwin.generationStatus == 'pending')
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(context)),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Accent Twin Details
          Text(
            'Target Accent: ${accentTwin.targetAccent.toUpperCase()}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Provider: ${accentTwin.ttsProvider.toUpperCase()}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          
          // Processing Time
          if (accentTwin.processingTime != null)
            Text(
              'Processing Time: ${accentTwin.processingTime!.toStringAsFixed(1)}s',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          
          // Similarity Score
          if (accentTwin.similarityScore != null)
            Text(
              'Similarity Score: ${(accentTwin.similarityScore! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 14),
            ),
          
          // Error Message
          if (accentTwin.errorMessage?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Error: ${accentTwin.errorMessage}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade800,
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              // Enhanced Audio Controls (only if ready and has file)
              if (accentTwin.isReady == true && accentTwin.fileUrl != null) ...[
                // Determine if this is the currently playing audio
                if (audioPlaybackState.currentAudioUrl == accentTwin.fileUrl) ...[
                  // Currently playing this file - show pause/stop controls
                  if (audioPlaybackState.isPlaying) ...[
                    // Pause button
                    ElevatedButton.icon(
                      onPressed: onPauseAccentTwin,
                      icon: const Icon(Icons.pause, size: 18),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stop button
                    ElevatedButton.icon(
                      onPressed: onStopAccentTwin,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 32),
                      ),
                    ),
                  ] else if (audioPlaybackState.isPaused) ...[
                    // Resume button
                    ElevatedButton.icon(
                      onPressed: onResumeAccentTwin,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(85, 32),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stop button
                    ElevatedButton.icon(
                      onPressed: onStopAccentTwin,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(70, 32),
                      ),
                    ),
                  ]
                ] else ...[
                  // Not currently playing this file - show play button
                  ElevatedButton.icon(
                    onPressed: () => onPlayAccentTwin(accentTwin.fileUrl!),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                  ),
                ],
              ],
              
              const SizedBox(width: 8),
              
              // Refresh Button
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(90, 32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (accentTwin.generationStatus) {
      case 'completed':
        return Colors.green.shade50;
      case 'pending':
      case 'processing':
        return Colors.blue.shade50;
      case 'failed':
      case 'error':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (accentTwin.generationStatus) {
      case 'completed':
        return Colors.green.shade200;
      case 'pending':
      case 'processing':
        return Colors.blue.shade200;
      case 'failed':
      case 'error':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (accentTwin.generationStatus) {
      case 'completed':
        return Colors.green.shade600;
      case 'pending':
      case 'processing':
        return Colors.blue.shade600;
      case 'failed':
      case 'error':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon() {
    switch (accentTwin.generationStatus) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (accentTwin.generationStatus) {
      case 'completed':
        return 'Accent Twin Ready!';
      case 'pending':
        return 'Generating Accent Twin...';
      case 'processing':
        return 'Processing Audio...';
      case 'failed':
        return 'Generation Failed';
      case 'error':
        return 'Error Occurred';
      default:
        return 'Status: ${accentTwin.generationStatus}';
    }
  }
}
