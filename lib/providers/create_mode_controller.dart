import 'package:flutter/foundation.dart';

enum CreateMode { progression, fullSong }

/// Small UI-state controller shared by the Create surface and app shell.
///
/// The mode is intentionally separate from composition data: switching back to
/// Progression can hide the full-song workspace without destroying the current
/// SongDraft, so returning to Full Song resumes the existing arrangement.
class CreateModeController extends ChangeNotifier {
  CreateMode _mode = CreateMode.progression;

  CreateMode get mode => _mode;
  bool get isProgression => _mode == CreateMode.progression;
  bool get isFullSong => _mode == CreateMode.fullSong;

  void setMode(CreateMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }
}
