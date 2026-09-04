// Chord Flow
// Main application entry point

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'providers/song_session_controller.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/fullscreen_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FullscreenService.enableImmersive();

  // Initialize Firebase with web-specific handling.
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
        ChangeNotifierProvider(
          create: (_) => SongSessionController(),
        ),
      ],
      child: FullscreenLifecycle(
        child: MaterialApp(
          title: 'Chord Flow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
