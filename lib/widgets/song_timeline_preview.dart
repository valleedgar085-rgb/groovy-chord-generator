import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/song_timeline.dart';
import '../providers/song_session_controller.dart';
import '../utils/theme.dart';

/// Compact arrangement visualization backed by the canonical SongTimeline.
class SongTimelinePreview extends StatelessWidget {
  const SongTimelinePreview({
    super.key,
    required this.session,
  });

  final SongSessionController session;

  @override
  Widget build(BuildContext context) {
    final timeline = session.currentTimeline;
    if (timeline == null || timeline.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalBars = timeline.totalBars;
    final barsLabel = totalBars == totalBars.roundToDouble()
        ? totalBars.round().toString()
        : totalBars.toStringAsFixed(1);

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
              const Icon(
                Icons.timeline_rounded,
                color: AppTheme.accentCyan,
                size: 16,
              ),
              const SizedBox(width: 7),
              const Text(
                'TIMELINE',
                style: TextStyle(
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
              final fullWidth = laneWidth + labelWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: fullWidth,
                  child: Column(
                    children: [
                      _SectionRuler(
                        session: session,
                        timeline: timeline,
                        laneWidth: laneWidth,
                        labelWidth: labelWidth,
                      ),
                      const SizedBox(height: 5),
                      _TimelineLane(
                        label: 'HARMONY',
                        timeline: timeline,
                        track: TimelineTrackType.harmony,
                        laneWidth: laneWidth,
                        labelWidth: labelWidth,
                        focusBeat: session.selectedTimelineSection?.startBeat,
                      ),
                      const SizedBox(height: 4),
                      _TimelineLane(
                        label: 'MELODY',
                        timeline: timeline,
                        track: TimelineTrackType.melody,
                        laneWidth: laneWidth,
                        labelWidth: labelWidth,
                        focusBeat: session.selectedTimelineSection?.startBeat,
                      ),
                      const SizedBox(height: 4),
                      _TimelineLane(
                        label: 'BASS',
                        timeline: timeline,
                        track: TimelineTrackType.bass,
                        laneWidth: laneWidth,
                        labelWidth: labelWidth,
                        focusBeat: session.selectedTimelineSection?.startBeat,
                      ),
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
                decoration: const BoxDecoration(
                  color: AppTheme.accentSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SECTION FOCUS • ${_sectionLabel(session.selectedSectionId ?? timeline.sections.first.id)}',
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
  });

  final SongSessionController session;
  final SongTimeline timeline;
  final double laneWidth;
  final double labelWidth;

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
              children: timeline.sections.map((section) {
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
              }).toList(growable: false),
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
  });

  final String label;
  final SongTimeline timeline;
  final TimelineTrackType track;
  final double laneWidth;
  final double labelWidth;
  final double? focusBeat;

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
    required this.track,
  });

  final List<MusicalTimelineEvent> events;
  final double totalBeats;
  final double? focusBeat;
  final TimelineTrackType track;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = AppTheme.bgElevated.withValues(alpha: 0.54);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(6),
      ),
      background,
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
      final rect = Rect.fromLTWH(
        left,
        verticalInset,
        width,
        size.height - (verticalInset * 2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
        eventPaint,
      );
    }

    final focus = focusBeat;
    if (focus != null && totalBeats > 0) {
      final x = focus / totalBeats * size.width;
      final focusPaint = Paint()
        ..color = AppTheme.accentSecondary.withValues(alpha: 0.92)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), focusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineLanePainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.totalBeats != totalBeats ||
        oldDelegate.focusBeat != focusBeat ||
        oldDelegate.track != track;
  }
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
