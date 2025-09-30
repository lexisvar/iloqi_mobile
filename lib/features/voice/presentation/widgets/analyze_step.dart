import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';

class AnalyzeStep extends ConsumerWidget {
  final VoiceRecordingState recordingState;
  final AsyncValue<VoiceAnalysis?> analysisState;
  final VoidCallback onAnalysisComplete;

  const AnalyzeStep({
    super.key,
    required this.recordingState,
    required this.analysisState,
    required this.onAnalysisComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Step 3: Analyze Your Voice',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI is analyzing your speech patterns and accent',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Analysis animation
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: analysisState.isLoading
                  ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.4)]
                  : [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: analysisState.isLoading ? Colors.blue : Colors.green,
              width: 4,
            ),
          ),
          child: analysisState.isLoading
              ? const CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                )
              : Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
        ),

        const SizedBox(height: 32),

        // Status text
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: analysisState.isLoading ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: analysisState.isLoading ? Colors.blue.shade200 : Colors.green.shade200,
            ),
          ),
          child: Column(
            children: [
              Text(
                analysisState.isLoading
                    ? 'Analyzing your voice patterns...'
                    : 'Analysis Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: analysisState.isLoading ? Colors.blue.shade800 : Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              if (analysisState.isLoading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  backgroundColor: Colors.blue,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ],
          ),
        ),

        // Analyze button
        if (!analysisState.isLoading && analysisState.hasError) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (recordingState.recordingPath != null) {
                  ref.read(voiceAnalysisProvider.notifier)
                      .analyzeVoice(recordingState.recordingPath!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Retry Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        // Continue button
        if (!analysisState.isLoading && analysisState.hasValue && analysisState.value != null) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onAnalysisComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'View Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],

        // Error display
        if (analysisState.hasError) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Analysis Failed',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  analysisState.error.toString(),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}