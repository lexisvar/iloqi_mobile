import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccentTwinPage extends ConsumerWidget {
  final String analysisId;

  const AccentTwinPage({super.key, required this.analysisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accent Twin'),
      ),
      body: const Center(
        child: Text(
          'Accent Twin Generation\nComing Soon!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
