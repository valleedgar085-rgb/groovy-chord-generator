import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/song_timeline.dart';
import '../providers/song_session_controller.dart';
import '../services/timeline_transport.dart';
import '../utils/theme.dart';

/// Compact arrangement visualization backed by the canonical SongTimeline.
///
/// [transport] is optional on purpose. Without it the widget remains a fully
/// interactive static editor view; production supplies a transport to add the
/// live audio-clock playhead. This keeps ordinary widget tests native-FFI free.
class SongTimelinePreview extends StatelessWidget {
  const SongTimelinePreview({
    super.key,
    required this.session,
    this.transport,
  });

  final SongSessionController session;
  final TimelineTransport? transport;

  @override
  Widget build(BuildContext context) {
    final liveTransport = transport;
    if (liveTransport == null) {
      return _buildTimeline(context, null);
    }
    return AnimatedBuilder(
      animation: liveTransport,
      builder: (context, _) => _buildTimeline(context, liveTransport),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    TimelineTransport? liveTransport,
  ) {
    final timeline = session.currentTimeline;
    if (timeline == null || timeline.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final playing = liveTransport?.isTimelinePlayback == true &&
        liveTransport?.isPlaying == true;
    final hasPlayhead = liveTransport != null &&
        (liveTransport.isTimelinePlayback || liveTransport.songBeat > 0);
    final playheadBeat = hasPlayhead
        ? liveTransport.songBeat.clamp(0.0, timeline.totalBeats).toDouble()
        : null;
    final barsLabel = timeline.totalBars == timeline.totalBars.roundToDouble()
        ? timeline.totalBars.round().toString()
        : timeline.totalBars.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderColor.withValues(alpha: 0.66),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                playing ? Icons.graphic_eq_rounded : Icons.timeline_rounded,
                color: playing ? AppTheme.success : AppTheme.accentCyan,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                playing ? 'SONG PLAYBACK' : 'TIMELINE',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '$barsLabel BARS • ${timeline.totalBeats.round()} BEATS',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const labelWidth = 54.0;
              final laneWidth = math.max(
                constraints.maxWidth - labelWidth,
                timeline.totalBars * 13.0,
              );
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: laneWidth + labelWidth,
                  child: Column(
                    children: [
                      _SectionRuler(
                        session: session,
                        timeline: timeline,
                        laneWidth: laneWidth,
                        labelWidth: labelWidth,
                        playheadBeat: playheadBeat,
                      ),
                      const SizedBox(height: 5),
                      for (final lane in const <(String, TimelineTrackType)>[
                        ('HARMONY', TimelineTrackType.harmony),
                        ('MELODY', TimelineTrackType.melody),
                        ('BASS', TimelineTrackType.bass),
                      ]) ...[
                        _TimelineLane(
                          label: lane.$1,
                          timeline: timeline,
                          track: lane.$2,
                          laneWidth: laneWidth,
                          labelWidth: labelWidth,
                          focusBeat: session.selectedTimelineSection?.startBeat,
                          playheadBeat: playheadBeat,
                        ),
                        if (lane.$2 != TimelineTrackType.bass)
                          const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: playing ? AppTheme.success : AppTheme.accentSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  playing
                      ? 'PLAYHEAD • ${_sectionLabel(liveTransport?.activeSectionId ?? session.selectedSectionId ?? timeline.sections.first.id)} • BEAT ${(liveTransport?.songBeat ?? 0).toStringAsFixed(1)}'
                      : 'SECTION FOCUS • ${_sectionLabel(session.selectedSectionId ?? timeline.sections.first.id)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionRuler extends StatelessWidget {
  const _SectionRuler({
    required this.session,
    required this.timeline,
    required this.laneWidth,
    required this.labelWidth,
    required this.playheadBeat,
  });

  final SongSessionController session;
  final SongTimeline timeline;
  final double laneWidth;
  final double labelWidth;
  final double? playheadBeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: labelWidth,
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SECTION',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.55,
                ),
              ),
            ),
          ),
          SizedBox(
            width: laneWidth,
            child: Stack(
              children: [
                ...timeline.sections.map((section) {
                  final left = section.startBeat / timeline.totalBeats * laneWidth;
                  final width = math.max(
                    28.0,
                    section.durationBeats / timeline.totalBeats * laneWidth - 2,
                  );
                  final selected = session.selectedSectionId == section.id;
                  return Positioned(
                    left: left,
                    top: 0,
                    width: width,
                    bottom: 0,
                    child: InkWell(
                      key: ValueKey<String>('timeline-section-${section.id}'),
                      onTap: () => session.selectSection(section.id),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: AppTheme.animationFast,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.accentPrimary.withValues(alpha: 0.28)
                              : AppTheme.bgElevated.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? AppTheme.accentSecondary.withValues(alpha: 0.82)
                                : AppTheme.borderColor.withValues(alpha: 0.42),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _sectionLabel(section.id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (playheadBeat != null && timeline.totalBeats > 0)
                  Positioned(
                    left: (playheadBeat! / timeline.totalBeats * laneWidth)
                        .clamp(0.0, laneWidth - 2)
                        .toDouble(),
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentCyan.withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLane extends StatelessWidget {
  const _TimelineLane({
    required this.label,
    required this.timeline,
    required this.track,
    required this.laneWidth,
    required this.labelWidth,
    required this.focusBeat,
    required this.playheadBeat,
  });

  final String label;
  final SongTimeline timeline;
  final TimelineTrackType track;
  final double laneWidth;
  final double labelWidth;
  final double? focusBeat;
  final double? playheadBeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 7.2,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.35,
              ),
            ),
          ),
          SizedBox(
            width: laneWidth,
            height: 24,
            child: CustomPaint(
              painter: _TimelineLanePainter(
                events: timeline.eventsForTrack(track),
                totalBeats: timeline.totalBeats,
                focusBeat: focusBeat,
                playheadBeat: playheadBeat,
                track: track,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLanePainter extends CustomPainter {
  _TimelineLanePainter({
    required this.events,
    required this.totalBeats,
    required this.focusBeat,
    required this.playheadBeat,
    required this.track,
  });

  final List<MusicalTimelineEvent> events;
  final double totalBeats;
  final double? focusBeat;
  final double? playheadBeat;
  final TimelineTrackType track;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      Paint()..color = AppTheme.bgElevated.withValues(alpha: 0.54),
    );

    final eventColor = switch (track) {
      TimelineTrackType.harmony => AppTheme.accentPrimary,
      TimelineTrackType.melody => AppTheme.accentCyan,
      TimelineTrackType.bass => AppTheme.accentPink,
    };
    final eventPaint = Paint()..color = eventColor.withValues(alpha: 0.72);

    for (final event in events) {
      if (totalBeats <= 0) continue;
      final left = event.startBeat / totalBeats * size.width;
      final width = math.max(1.5, event.durationBeats / totalBeats * size.width);
      final verticalInset = track == TimelineTrackType.harmony ? 4.0 : 7.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            verticalInset,
            width,
            size.height - (verticalInset * 2),
          ),
          const Radius.circular(2.5),
        ),
        eventPaint,
      );
    }

    if (focusBeat != null && totalBeats > 0) {
      final x = focusBeat! / totalBeats * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppTheme.accentSecondary.withValues(alpha: 0.58)
          ..strokeWidth = 1.0,
      );
    }

    if (playheadBeat != null && totalBeats > 0) {
      final x = (playheadBeat! / totalBeats * size.width)
          .clamp(0.0, size.width)
          .toDouble();
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = AppTheme.accentCyan.withValues(alpha: 0.28)
          ..strokeWidth = 5,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.96)
          ..strokeWidth = 1.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLanePainter oldDelegate) =>
      oldDelegate.events != events ||
      oldDelegate.totalBeats != totalBeats ||
      oldDelegate.focusBeat != focusBeat ||
      oldDelegate.playheadBeat != playheadBeat ||
      oldDelegate.track != track;
}

String _sectionLabel(String id) {
  switch (id) {
    case 'intro':
      return 'INTRO';
    case 'verse-1':
      return 'V1';
    case 'pre-1':
      return 'PRE1';
    case 'chorus-1':
      return 'CH1';
    case 'verse-2':
      return 'V2';
    case 'pre-2':
      return 'PRE2';
    case 'chorus-2':
      return 'CH2';
    case 'bridge':
      return 'BRIDGE';
    case 'final-chorus':
      return 'FINAL';
    case 'outro':
      return 'OUTRO';
    default:
      return id.toUpperCase();
  }
}
