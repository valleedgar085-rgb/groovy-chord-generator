// Groovy Chord Generator
// Main Application Entry Point
// Version 2.7
// Author: Edgar Valle

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/playback_controller.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final appState = AppState();
            appState.loadFavorites();
            return appState;
          },
        ),
        ChangeNotifierProvider(create: (_) => PlaybackController()),
      ],
      child: MaterialApp(
        title: 'Chord Flow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
