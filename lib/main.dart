// Groovy Chord Generator
// Main Application Entry Point
// Version 2.5
// Author: Edgar Valle

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with web-specific handling
  try {
    await FirebaseService.initialize();
    await AuthService.signInAnonymously();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('App will use local storage only');
  }

  runApp(const GroovyChordGeneratorApp());
}

class GroovyChordGeneratorApp extends StatelessWidget {
  const GroovyChordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final appState = AppState();
        // Load favorites on startup
        appState.loadFavorites();
        return appState;
      },
      child: MaterialApp(
        title: 'Groovy Chord Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
