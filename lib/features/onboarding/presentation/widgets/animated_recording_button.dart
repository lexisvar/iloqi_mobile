import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated recording button that responds to audio levels
/// Shows visual feedback with pulsing animation based on voice input
class AnimatedRecordingButton extends StatefulWidget {
  final bool isRecording;
  final double? audioLevel; // dB level (-∞ to 0)
  final VoidCallback onStart;
  final VoidCallback onStop;
  final double size;
  final Color primaryColor;
  final Color recordingColor;

  const AnimatedRecordingButton({
    super.key,
    required this.isRecording,
    required this.onStart,
    required this.onStop,
    this.audioLevel,
    this.size = 100.0,
    this.primaryColor = Colors.blue,
    this.recordingColor = Colors.red,
  });

  @override
  State<AnimatedRecordingButton> createState() => _AnimatedRecordingButtonState();
}

class _AnimatedRecordingButtonState extends State<AnimatedRecordingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for recording state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Wave animation for audio level response
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedRecordingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start/stop pulse animation based on recording state
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Update wave animation based on audio level
    if (widget.isRecording && widget.audioLevel != null) {
      _updateWaveAnimation(widget.audioLevel!);
    }
  }

  void _updateWaveAnimation(double audioLevel) {
    // Convert dB level (-60 to 0) to scale factor (1.0 to 1.4)
    final normalizedLevel = math.max(0.0, (audioLevel + 60) / 60);
    final scaleFactor = 1.0 + (normalizedLevel * 0.4);
    
    _waveAnimation = Tween<double>(
      begin: _waveAnimation.value,
      end: scaleFactor,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));
    
    _waveController.reset();
    _waveController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRecording ? widget.onStop : widget.onStart,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
        builder: (context, child) {
          final double scale = widget.isRecording 
            ? _pulseAnimation.value * _waveAnimation.value
            : 1.0;
            
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording 
                  ? widget.recordingColor.withOpacity(0.2)
                  : widget.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: widget.isRecording ? widget.recordingColor : widget.primaryColor,
                  width: 3,
                ),
                boxShadow: widget.isRecording ? [
                  BoxShadow(
                    color: widget.recordingColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ] : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring for audio level visualization
                  if (widget.isRecording && widget.audioLevel != null)
                    Container(
                      width: widget.size * 0.9,
                      height: widget.size * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.recordingColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  
                  // Main icon
                  Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    size: widget.size * 0.4,
                    color: widget.isRecording ? widget.recordingColor : widget.primaryColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A circular audio level visualizer that shows real-time audio levels
class AudioLevelVisualizer extends StatefulWidget {
  final double? audioLevel; // dB level (-∞ to 0)
  final bool isActive;
  final double size;
  final Color color;

  const AudioLevelVisualizer({
    super.key,
    this.audioLevel,
    required this.isActive,
    this.size = 60.0,
    this.color = Colors.green,
  });

  @override
  State<AudioLevelVisualizer> createState() => _AudioLevelVisualizerState();
}

class _AudioLevelVisualizerState extends State<AudioLevelVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  @override
  void didUpdateWidget(AudioLevelVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && widget.audioLevel != null) {
      // Convert dB level (-60 to 0) to percentage (0.0 to 1.0)
      final normalizedLevel = math.max(0.0, (widget.audioLevel! + 60) / 60);
      
      _animation = Tween<double>(
        begin: _animation.value,
        end: normalizedLevel,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      
      _controller.reset();
      _controller.forward();
    } else if (!widget.isActive) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: widget.size - 8,
                height: widget.size - 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
              ),
              
              // Level indicator
              Container(
                width: (widget.size - 8) * _animation.value,
                height: (widget.size - 8) * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.7),
                ),
              ),
              
              // Center icon
              Icon(
                Icons.graphic_eq_rounded,
                color: widget.color,
                size: widget.size * 0.3,
              ),
            ],
          ),
        );
      },
    );
  }
}
