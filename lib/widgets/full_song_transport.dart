import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/song_timeline.dart';
import '../providers/song_session_controller.dart';
import '../services/audio_playback_service.dart';
import '../utils/theme.dart';
import 'studio_sound_sheet.dart';

/// Compact multitrack transport for the canonical full-song timeline.
class FullSongTransport extends StatefulWidget {
  const FullSongTransport({
    super.key,
    required this.session,
  });

  final SongSessionController session;

  @override
  State<FullSongTransport> createState() => _FullSongTransportState();
}

class _FullSongTransportState extends State<FullSongTransport> {
  final AudioPlaybackService _audio = AudioPlaybackService.instance;
  double? _scrubBeat;
  String? _lastSyncedSection;

  SongSessionController get session => widget.session;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_refresh);
  }

  @override
  void dispose() {
    _audio.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    final activeSection = _audio.activeSectionId;
    if (_audio.isTimelinePlayback &&
        activeSection != null &&
        activeSection != _lastSyncedSection) {
      _lastSyncedSection = activeSection;
      if (session.selectedSectionId != activeSection) {
        session.selectSection(activeSection);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final timeline = session.currentTimeline;
    if (timeline == null || timeline.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final beat = (_scrubBeat ?? _audio.songBeat)
        .clamp(0.0, timeline.totalBeats)
        .toDouble();
    final section = timeline.sectionAtBeat(
          beat == timeline.totalBeats && beat > 0 ? beat - 0.000001 : beat,
        ) ??
        session.selectedTimelineSection ??
        timeline.sections.first;
    final currentBar = timeline.totalBars <= 0
        ? 0
        : ((beat / timeline.beatsPerBar).floor() + 1)
            .clamp(1, timeline.totalBars.ceil());
    final totalBars = timeline.totalBars.ceil();

    return Container(
      key: const ValueKey<String>('full-song-transport'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.34),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.46),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.accentCyan.withValues(alpha: 0.07),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nowPlayingRow(section.id, currentBar, totalBars),
          const SizedBox(height: 5),
          _seekRow(timeline, beat),
          const SizedBox(height: 4),
          _transportRow(timeline, section),
          const SizedBox(height: 7),
          _trackMixRow(),
        ],
      ),
    );
  }

  Widget _nowPlayingRow(String sectionId, int currentBar, int totalBars) {
    return Row(
      children: [
        AnimatedContainer(
          duration: AppTheme.animationFast,
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _audio.isTimelinePlayback && _audio.isPlaying
                ? AppTheme.success
                : AppTheme.textMuted,
            boxShadow: _audio.isTimelinePlayback && _audio.isPlaying
                ? [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.48),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          _audio.isTimelinePlayback && _audio.isPlaying
              ? 'PLAYING  ${_sectionLabel(sectionId)}'
              : 'FULL SONG',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        Text(
          'BAR $currentBar/$totalBars  •  ${_audio.bpm} BPM',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _seekRow(SongTimeline timeline, double beat) {
    return SizedBox(
      height: 27,
      child: Row(
        children: [
          const Text(
            '0',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
              ),
              child: Slider(
                key: const ValueKey<String>('song-seek-slider'),
                value: beat,
                min: 0,
                max: timeline.totalBeats,
                onChanged: (value) => setState(() => _scrubBeat = value),
                onChangeEnd: (value) {
                  final resume = _audio.isTimelinePlayback && _audio.isPlaying;
                  setState(() => _scrubBeat = null);
                  unawaited(
                    _audio.seekTimeline(timeline, value, resume: resume),
                  );
                  final target = timeline.sectionAtBeat(
                    value == timeline.totalBeats && value > 0
                        ? value - 0.000001
                        : value,
                  );
                  if (target != null) session.selectSection(target.id);
                },
              ),
            ),
          ),
          Text(
            '${timeline.totalBeats.round()}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportRow(SongTimeline timeline, TimelineSection currentSection) {
    final selected = session.selectedTimelineSection ?? currentSection;
    return Row(
      children: [
        _TransportIconButton(
          key: const ValueKey<String>('song-prev-section'),
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous section',
          onTap: () => _jumpSection(timeline, -1),
        ),
        const SizedBox(width: 5),
        _TransportIconButton(
          key: const ValueKey<String>('song-play-stop'),
          icon: _audio.isTimelinePlayback && _audio.isPlaying
              ? Icons.stop_rounded
              : Icons.play_arrow_rounded,
          tooltip: _audio.isTimelinePlayback && _audio.isPlaying
              ? 'Stop song'
              : 'Play full song',
          prominent: true,
          active: _audio.isTimelinePlayback && _audio.isPlaying,
          onTap: () {
            if (_audio.isTimelinePlayback && _audio.isPlaying) {
              unawaited(_audio.stop());
            } else {
              final start = _audio.songBeat > 0 &&
                      _audio.songBeat < timeline.totalBeats - 0.001
                  ? _audio.songBeat
                  : 0.0;
              unawaited(_audio.playFullSong(timeline, startBeat: start));
            }
          },
        ),
        const SizedBox(width: 5),
        _TransportIconButton(
          key: const ValueKey<String>('song-next-section'),
          icon: Icons.skip_next_rounded,
          tooltip: 'Next section',
          onTap: () => _jumpSection(timeline, 1),
        ),
        const SizedBox(width: 7),
        _TransportIconButton(
          key: const ValueKey<String>('song-play-section'),
          icon: Icons.playlist_play_rounded,
          tooltip: 'Play selected section',
          active: _audio.isTimelinePlayback &&
              _audio.isPlaying &&
              _audio.timelineRangeStart == selected.startBeat &&
              _audio.timelineRangeEnd == selected.endBeat,
          onTap: () => unawaited(
            _audio.playSection(
              timeline,
              selected.id,
              loop: _audio.looping,
            ),
          ),
        ),
        const SizedBox(width: 5),
        _TransportIconButton(
          key: const ValueKey<String>('song-section-loop'),
          icon: Icons.repeat_one_rounded,
          tooltip: 'Loop selected section',
          active: _audio.looping,
          onTap: () {
            final next = !_audio.looping;
            _audio.setLooping(next);
            if (_audio.isTimelinePlayback && _audio.isPlaying) {
              if (next) {
                unawaited(_audio.playSection(timeline, selected.id, loop: true));
              } else {
                unawaited(_audio.playFullSong(timeline, startBeat: _audio.songBeat));
              }
            }
          },
        ),
        const Spacer(),
        _TempoButton(
          icon: Icons.remove_rounded,
          onTap: () => _audio.setBpm(_audio.bpm - 1),
        ),
        SizedBox(
          width: 38,
          child: Text(
            '${_audio.bpm}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _TempoButton(
          icon: Icons.add_rounded,
          onTap: () => _audio.setBpm(_audio.bpm + 1),
        ),
        const SizedBox(width: 5),
        _TransportIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Studio Sound',
          onTap: () => _openSoundSheet(context),
        ),
      ],
    );
  }

  Widget _trackMixRow() {
    return Row(
      children: [
        const Text(
          'TRACKS',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _TrackMixControl(
                  label: 'CHORDS',
                  track: TimelineTrackType.harmony,
                  audio: _audio,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _TrackMixControl(
                  label: 'MELODY',
                  track: TimelineTrackType.melody,
                  audio: _audio,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _TrackMixControl(
                  label: 'BASS',
                  track: TimelineTrackType.bass,
                  audio: _audio,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: _audio.clearTrackMix,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Text(
              'ALL',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _jumpSection(SongTimeline timeline, int delta) {
    final currentId = _audio.activeSectionId ?? session.selectedSectionId;
    var index = timeline.sections.indexWhere((section) => section.id == currentId);
    if (index < 0) index = 0;
    final targetIndex = (index + delta).clamp(0, timeline.sections.length - 1);
    final target = timeline.sections[targetIndex];
    session.selectSection(target.id);
    if (_audio.isTimelinePlayback && _audio.isPlaying) {
      if (_audio.looping) {
        unawaited(_audio.playSection(timeline, target.id, loop: true));
      } else {
        unawaited(_audio.playFullSong(timeline, startBeat: target.startBeat));
      }
    } else {
      unawaited(_audio.seekTimeline(timeline, target.startBeat, resume: false));
    }
  }

  void _openSoundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const StudioSoundSheet(),
    );
  }
}

class _TrackMixControl extends StatelessWidget {
  const _TrackMixControl({
    required this.label,
    required this.track,
    required this.audio,
  });

  final String label;
  final TimelineTrackType track;
  final AudioPlaybackService audio;

  @override
  Widget build(BuildContext context) {
    final muted = audio.isTrackMuted(track);
    final soloed = audio.isTrackSoloed(track);
    return Container(
      height: 29,
      padding: const EdgeInsets.only(left: 6, right: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: soloed
              ? AppTheme.warning.withValues(alpha: 0.55)
              : muted
                  ? AppTheme.accentPink.withValues(alpha: 0.45)
                  : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted ? AppTheme.textMuted : AppTheme.textSecondary,
                fontSize: 6.6,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _MixButton(
            label: 'M',
            active: muted,
            activeColor: AppTheme.accentPink,
            onTap: () => audio.setTrackMuted(track, !muted),
          ),
          _MixButton(
            label: 'S',
            active: soloed,
            activeColor: AppTheme.warning,
            onTap: () => audio.setTrackSoloed(track, !soloed),
          ),
        ],
      ),
    );
  }
}

class _MixButton extends StatelessWidget {
  const _MixButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.only(left: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : AppTheme.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  const _TransportIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.prominent = false,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool prominent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          width: prominent ? 43 : 34,
          height: prominent ? 43 : 34,
          decoration: BoxDecoration(
            gradient: prominent ? AppTheme.accentGradient : null,
            color: prominent
                ? null
                : active
                    ? AppTheme.accentPrimary.withValues(alpha: 0.22)
                    : AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppTheme.accentSecondary.withValues(alpha: 0.7)
                  : AppTheme.borderColor,
            ),
          ),
          child: Icon(
            icon,
            size: prominent ? 25 : 18,
            color: prominent || active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TempoButton extends StatelessWidget {
  const _TempoButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 24,
        height: 28,
        child: Icon(icon, size: 15, color: AppTheme.textMuted),
      ),
    );
  }
}

String _sectionLabel(String id) {
  switch (id) {
    case 'intro':
      return 'INTRO';
    case 'verse-1':
      return 'VERSE 1';
    case 'pre-1':
      return 'PRE 1';
    case 'chorus-1':
      return 'CHORUS 1';
    case 'verse-2':
      return 'VERSE 2';
    case 'pre-2':
      return 'PRE 2';
    case 'chorus-2':
      return 'CHORUS 2';
    case 'bridge':
      return 'BRIDGE';
    case 'final-chorus':
      return 'FINAL CHORUS';
    case 'outro':
      return 'OUTRO';
    default:
      return id.toUpperCase();
  }
}
