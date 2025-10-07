import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/voice_provider.dart';
import '../../../../core/models/voice_models.dart';

class AnalyzeStep extends ConsumerStatefulWidget {
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
  ConsumerState<AnalyzeStep> createState() => _AnalyzeStepState();
}

class _AnalyzeStepState extends ConsumerState<AnalyzeStep> {
  bool _hasTriggeredAnalysis = false;

  @override
  void initState() {
    super.initState();
    // Trigger analysis automatically when this step loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAnalysisIfNeeded();
    });
  }

  void _triggerAnalysisIfNeeded() {
    // Only trigger analysis if:
    // 1. We haven't triggered it already
    // 2. We have a recording path
    // 3. Analysis is not already loading or completed
    if (!_hasTriggeredAnalysis && 
        widget.recordingState.recordingPath != null && 
        !widget.analysisState.isLoading && 
        !widget.analysisState.hasValue) {
      debugPrint('🔬 Auto-triggering voice analysis for: ${widget.recordingState.recordingPath}');
      ref.read(voiceAnalysisProvider.notifier).analyzeVoice(widget.recordingState.recordingPath!);
      _hasTriggeredAnalysis = true;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              colors: widget.analysisState.isLoading
                  ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.4)]
                  : [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.analysisState.isLoading ? Colors.blue : Colors.green,
              width: 4,
            ),
          ),
          child: widget.analysisState.isLoading
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
            color: widget.analysisState.isLoading ? Colors.blue.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.analysisState.isLoading ? Colors.blue.shade200 : Colors.green.shade200,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.analysisState.isLoading
                    ? 'Analyzing your voice patterns...'
                    : 'Analysis Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.analysisState.isLoading ? Colors.blue.shade800 : Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.analysisState.isLoading) ...[
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
        if (!widget.analysisState.isLoading && widget.analysisState.hasError) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (widget.recordingState.recordingPath != null) {
                  ref.read(voiceAnalysisProvider.notifier)
                      .analyzeVoice(widget.recordingState.recordingPath!);
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
        if (!widget.analysisState.isLoading && widget.analysisState.hasValue && widget.analysisState.value != null) ...[
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onAnalysisComplete,
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
        if (widget.analysisState.hasError) ...[
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
                  widget.analysisState.error.toString(),
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