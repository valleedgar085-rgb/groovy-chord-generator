import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keeps Chord Flow in Android immersive-sticky mode while still allowing
/// transient system bars to appear when the user intentionally swipes for them.
///
/// Android may restore overlays after the keyboard, dialogs, app switching, or
/// other system UI. Re-applying immersive mode on resume and after an overlay
/// reveal makes fullscreen behavior substantially more reliable without
/// hard-coding anything into the generated Android host.
class FullscreenService {
  FullscreenService._();

  static Timer? _restoreTimer;
  static bool _callbackInstalled = false;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> enableImmersive() async {
    if (!_isAndroid) return;

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    if (_callbackInstalled) return;
    _callbackInstalled = true;
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (!systemOverlaysAreVisible || !_isAndroid) return;
      _restoreTimer?.cancel();
      // Android intentionally prevents immediate UI hiding after some system
      // interactions (notably the keyboard). A short delayed restore respects
      // that transition while returning the studio to fullscreen automatically.
      _restoreTimer = Timer(const Duration(milliseconds: 1200), () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      });
    });
  }

  static void dispose() {
    _restoreTimer?.cancel();
    _restoreTimer = null;
  }
}

/// Lifecycle wrapper that restores immersive mode after returning to the app.
class FullscreenLifecycle extends StatefulWidget {
  const FullscreenLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<FullscreenLifecycle> createState() => _FullscreenLifecycleState();
}

class _FullscreenLifecycleState extends State<FullscreenLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FullscreenService.enableImmersive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FullscreenService.enableImmersive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
