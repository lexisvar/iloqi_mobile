import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceAnalysisPage extends ConsumerStatefulWidget {
  const VoiceAnalysisPage({super.key});

  @override
  ConsumerState<VoiceAnalysisPage> createState() => _VoiceAnalysisPageState();
}

class _VoiceAnalysisPageState extends ConsumerState<VoiceAnalysisPage> {
  bool _isRecording = false;
  bool _hasRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Analysis'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording 
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.blue,
                  width: 3,
                ),
              ),
              child: IconButton(
                iconSize: 80,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.red : Colors.blue,
                ),
                onPressed: _toggleRecording,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording 
                  ? 'Recording...' 
                  : _hasRecording 
                      ? 'Tap to record again'
                      : 'Tap to start recording',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Say something in English and let our AI analyze your accent',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_hasRecording)
              ElevatedButton(
                onPressed: _analyzeRecording,
                child: const Text('Analyze Recording'),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        _hasRecording = true;
      }
    });
  }

  void _analyzeRecording() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice analysis feature coming soon!'),
      ),
    );
  }
}
