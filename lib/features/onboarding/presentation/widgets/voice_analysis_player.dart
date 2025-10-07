import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/models/voice_models.dart';

/// Audio player widget for voice analysis playback
class VoiceAnalysisPlayer extends ConsumerStatefulWidget {
  final String audioPath;
  final VoiceAnalysis analysis;

  const VoiceAnalysisPlayer({
    super.key,
    required this.audioPath,
    required this.analysis,
  });

  @override
  ConsumerState<VoiceAnalysisPlayer> createState() => _VoiceAnalysisPlayerState();
}

class _VoiceAnalysisPlayerState extends ConsumerState<VoiceAnalysisPlayer>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
    
    // Wave animation for playback visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isLoading = false; // Remove seeking check as it doesn't exist in this version
        });
        
        if (_isPlaying) {
          _waveController.repeat(reverse: true);
        } else {
          _waveController.stop();
          _waveController.reset();
        }
      }
    });
  }

  Future<void> _playPause() async {
    if (widget.audioPath.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          // Reset to beginning if at end
          await _audioPlayer.seek(Duration.zero);
        }
        
        await _audioPlayer.play(DeviceFileSource(widget.audioPath));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: $e')),
        );
      }
    }
  }

  Future<void> _seekTo(double value) async {
    final position = _duration * value;
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.headphones_rounded, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Your Recording',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Audio Player Controls
            if (widget.audioPath.isNotEmpty) ...[
              Row(
                children: [
                  // Play/Pause Button
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isPlaying ? _waveAnimation.value : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor.withOpacity(0.1),
                            border: Border.all(color: theme.primaryColor, width: 2),
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _playPause,
                            icon: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primaryColor,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: theme.primaryColor,
                                    size: 28,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Progress and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress bar
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds > 0
                                ? _position.inMilliseconds / _duration.inMilliseconds
                                : 0.0,
                            onChanged: _seekTo,
                            activeColor: theme.primaryColor,
                            inactiveColor: Colors.grey.shade300,
                          ),
                        ),
                        
                        // Time labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Transcription
            if (widget.analysis.transcription != null && widget.analysis.transcription!.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.text_fields_rounded, 
                       color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transcription',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            widget.analysis.transcription ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            // Analysis Scores
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.analytics_rounded, 
                     color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                    'Analysis Results',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              _buildAnalysisScores(),
            ],
        ),
      ),
    );
  }

  Widget _buildAnalysisScores() {
    final analysis = widget.analysis;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _ScoreRow(
          label: 'Detected Accent',
          score: 1.0, // Display accent as a perfect match
          color: theme.primaryColor,
          value: analysis.detectedAccent.toUpperCase(),
        ),
        if (analysis.confidence > 0)
          _ScoreRow(
            label: 'Confidence',
            score: analysis.confidence,
            color: Colors.blue,
          ),
        if (analysis.audioQuality > 0)
          _ScoreRow(
            label: 'Audio Quality',
            score: analysis.audioQuality,
            color: Colors.green,
          ),
        _ScoreRow(
          label: 'Pronunciation',
          score: analysis.pronunciationScore,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final String? value; // Optional custom value (e.g., accent name)

  const _ScoreRow({
    required this.label,
    required this.score,
    required this.color,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (score * 100).round();
    final displayValue = value ?? '$percentage%';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          SizedBox(
            width: 80,
            child: Text(
              displayValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
