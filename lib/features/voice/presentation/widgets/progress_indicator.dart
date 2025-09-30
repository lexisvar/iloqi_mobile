import 'package:flutter/material.dart';

import 'voice_analysis_step.dart';

class VoiceAnalysisProgressIndicator extends StatelessWidget {
  final VoiceAnalysisStep currentStep;

  const VoiceAnalysisProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final steps = VoiceAnalysisStep.values;
    final currentIndex = currentStep.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: steps.map((step) {
          final stepIndex = step.index;
          final isCompleted = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (stepIndex < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: stepIndex < currentIndex ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}