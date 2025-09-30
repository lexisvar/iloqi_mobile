import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app/app.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await di.init();
  
  // Initialize SharedPreferences
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: IloqiApp(),
    ),
  );
}
