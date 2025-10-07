import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';

class RecordStep extends ConsumerStatefulWidget {
  final VoiceRecordingState recordingState;
  final VoidCallback onRecordingComplete;

  const RecordStep({
    super.key,
    required this.recordingState,
    required this.onRecordingComplete,
  });

  @override
  ConsumerState<RecordStep> createState() => _RecordStepState();
}

class _RecordStepState extends ConsumerState<RecordStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Step 2: Record Your Voice',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Record a 10-30 second sample of your natural speech',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Recording Button with enhanced animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.recordingState.isRecording ? 240 : 220,
          height: widget.recordingState.isRecording ? 240 : 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.recordingState.isRecording
                  ? [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0.3)]
                  : [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.recordingState.isRecording ? Colors.red : Colors.blue,
              width: 4,
            ),
            boxShadow: [
              if (widget.recordingState.isRecording)
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(200),
              onTap: () {
                if (widget.recordingState.isRecording) {
                  ref.read(voiceRecordingProvider.notifier).stopRecording();
                  // Don't call onRecordingComplete here - it will be called in didUpdateWidget
                } else {
                  ref.read(voiceRecordingProvider.notifier).startRecording();
                }
              },
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.recordingState.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 80,
                      color: widget.recordingState.isRecording ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.recordingState.isRecording ? 'STOP' : 'RECORD',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.recordingState.isRecording ? Colors.red : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Status and instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.recordingState.isRecording) ...[
                const SizedBox(height: 12),
                Text(
                  _formatDuration(widget.recordingState.recordingDuration),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Audio level indicator
        if (widget.recordingState.isRecording && widget.recordingState.audioLevel != null) ...[
          const SizedBox(height: 24),
          Text(
            'Audio Level',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.shade300,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (widget.recordingState.audioLevel! + 40) / 40,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],

        // Playback controls
        if (widget.recordingState.hasRecording && !widget.recordingState.isRecording) ...[
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Recording Complete!',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.recordingState.isPlaying
                ? () => ref.read(voiceRecordingProvider.notifier).stopPlayback()
                : () => ref.read(voiceRecordingProvider.notifier).playRecording(),
            icon: Icon(widget.recordingState.isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(widget.recordingState.isPlaying ? 'Stop Playback' : 'Play Recording'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          
          // Action buttons for user choice
          const SizedBox(height: 24),
          Row(
            children: [
              // Record Again button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Clear current recording and start fresh
                    ref.read(voiceRecordingProvider.notifier).clearRecording();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Record Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Proceed to Analysis button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🎤 User chose to proceed with analysis');
                    widget.onRecordingComplete();
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('Analyze Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Error message
        if (widget.recordingState.errorMessage != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.recordingState.errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText() {
    if (widget.recordingState.errorMessage != null) {
      return 'Error occurred';
    }

    switch (widget.recordingState.status) {
      case RecordingStatus.idle:
        return 'Tap the microphone to start recording your voice';
      case RecordingStatus.recording:
        return 'Recording... Speak naturally for 10-30 seconds';
      case RecordingStatus.stopped:
        return widget.recordingState.hasRecording
            ? 'Recording complete! Listen to your recording and choose an option below'
            : 'Tap the microphone to start recording';
      case RecordingStatus.playing:
        return 'Playing your recording...';
      case RecordingStatus.analyzing:
        return 'Analyzing your voice...';
      case RecordingStatus.analyzed:
        return 'Voice analysis complete!';
      case RecordingStatus.error:
        return 'An error occurred';
    }
  }

  Color _getStatusColor() {
    if (widget.recordingState.errorMessage != null) {
      return Colors.red;
    }

    switch (widget.recordingState.status) {
      case RecordingStatus.idle:
        return Colors.grey.shade600;
      case RecordingStatus.recording:
        return Colors.red;
      case RecordingStatus.stopped:
        return widget.recordingState.hasRecording ? Colors.green : Colors.grey.shade600;
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