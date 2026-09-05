import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groovy_chord_generator/engine/song_request.dart';
import 'package:groovy_chord_generator/engine/song_timeline.dart';
import 'package:groovy_chord_generator/engine/timeline_playback_plan.dart';
import 'package:groovy_chord_generator/models/types.dart';
import 'package:groovy_chord_generator/providers/song_session_controller.dart';
import 'package:groovy_chord_generator/services/timeline_transport.dart';
import 'package:groovy_chord_generator/widgets/full_song_transport.dart';

SongRequest _request({int seed = 450001}) => SongRequest(
      seed: seed,
      key: KeyName.C,
      genre: GenreKey.soulfulRnb,
      mood: MoodType.dreamy,
      complexity: ComplexityLevel.medium,
      spice: SpiceLevel.medium,
      rhythm: RhythmLevel.moderate,
      candidateCount: 4,
      chordVariety: 58,
      useVoiceLeading: true,
      useAdvancedTheory: false,
      useModalInterchange: false,
      useFunctionalHarmony: true,
      includeMelody: true,
      includeBass: true,
    );

class _FakeTimelineTransport extends ChangeNotifier
    implements TimelineTransport {
  bool _isPlaying = false;
  bool _isTimelinePlayback = false;
  bool _looping = false;
  int _bpm = 96;
  double _songBeat = 0;
  double _rangeStart = 0;
  double _rangeEnd = 0;
  String? _activeSectionId;
  final Set<TimelineTrackType> _muted = <TimelineTrackType>{};
  final Set<TimelineTrackType> _solo = <TimelineTrackType>{};

  @override
  bool get isPlaying => _isPlaying;
  @override
  bool get isTimelinePlayback => _isTimelinePlayback;
  @override
  bool get looping => _looping;
  @override
  int get bpm => _bpm;
  @override
  double get songBeat => _songBeat;
  @override
  double get timelineRangeStart => _rangeStart;
  @override
  double get timelineRangeEnd => _rangeEnd;
  @override
  String? get activeSectionId => _activeSectionId;

  @override
  bool isTrackMuted(TimelineTrackType track) => _muted.contains(track);
  @override
  bool isTrackSoloed(TimelineTrackType track) => _solo.contains(track);

  @override
  void setBpm(int value) {
    _bpm = value.clamp(55, 180);
    notifyListeners();
  }

  @override
  void setLooping(bool value) {
    _looping = value;
    notifyListeners();
  }

  @override
  void setTrackMuted(TimelineTrackType track, bool muted) {
    muted ? _muted.add(track) : _muted.remove(track);
    notifyListeners();
  }

  @override
  void setTrackSoloed(TimelineTrackType track, bool soloed) {
    soloed ? _solo.add(track) : _solo.remove(track);
    notifyListeners();
  }

  @override
  void clearTrackMix() {
    _muted.clear();
    _solo.clear();
    notifyListeners();
  }

  @override
  Future<void> playFullSong(
    SongTimeline timeline, {
    double startBeat = 0,
  }) async {
    _isPlaying = true;
    _isTimelinePlayback = true;
    _looping = false;
    _songBeat = startBeat;
    _rangeStart = 0;
    _rangeEnd = timeline.totalBeats;
    _activeSectionId = timeline.sectionAtBeat(startBeat)?.id;
    notifyListeners();
  }

  @override
  Future<void> playSection(
    SongTimeline timeline,
    String sectionId, {
    bool loop = false,
    double? startBeat,
  }) async {
    final section = timeline.sectionById(sectionId);
    if (section == null) return;
    _isPlaying = true;
    _isTimelinePlayback = true;
    _looping = loop;
    _rangeStart = section.startBeat;
    _rangeEnd = section.endBeat;
    _songBeat = startBeat ?? section.startBeat;
    _activeSectionId = section.id;
    notifyListeners();
  }

  @override
  Future<void> seekTimeline(
    SongTimeline timeline,
    double beat, {
    bool resume = true,
  }) async {
    _songBeat = beat.clamp(0.0, timeline.totalBeats).toDouble();
    _activeSectionId = timeline.sectionAtBeat(
      _songBeat == timeline.totalBeats && _songBeat > 0
          ? _songBeat - 0.000001
          : _songBeat,
    )?.id;
    if (resume) {
      _isPlaying = true;
      _isTimelinePlayback = true;
      _rangeStart = 0;
      _rangeEnd = timeline.totalBeats;
    }
    notifyListeners();
  }

  @override
  Future<void> stop({bool resetTimelinePosition = true}) async {
    _isPlaying = false;
    _isTimelinePlayback = false;
    _activeSectionId = null;
    if (resetTimelinePosition) {
      _songBeat = 0;
      _rangeStart = 0;
      _rangeEnd = 0;
    }
    notifyListeners();
  }
}

void main() {
  group('Phase 4.5 full-song playback planning', () {
    test('full-song plan contains performed harmony melody and bass', () {
      final session = SongSessionController()..generate(request: _request());
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();

      final plan = planner.build(timeline);

      expect(plan.startBeat, 0);
      expect(plan.endBeat, 256);
      expect(plan.durationBeats, 256);
      expect(plan.eventsForTrack(TimelineTrackType.harmony), isNotEmpty);
      expect(plan.eventsForTrack(TimelineTrackType.melody), isNotEmpty);
      expect(plan.eventsForTrack(TimelineTrackType.bass), isNotEmpty);
      for (final event in plan.events) {
        expect(event.startBeat, greaterThanOrEqualTo(0));
        expect(event.endBeat, lessThanOrEqualTo(256.000001));
        expect(event.durationBeats, greaterThan(0));
      }
    });

    test('mute and solo filtering follow mixer semantics', () {
      final session = SongSessionController()
        ..generate(request: _request(seed: 450002));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();

      final muted = planner.build(
        timeline,
        mutedTracks: const <TimelineTrackType>{TimelineTrackType.melody},
      );
      expect(muted.eventsForTrack(TimelineTrackType.melody), isEmpty);
      expect(muted.eventsForTrack(TimelineTrackType.harmony), isNotEmpty);
      expect(muted.eventsForTrack(TimelineTrackType.bass), isNotEmpty);

      final soloBass = planner.build(
        timeline,
        mutedTracks: const <TimelineTrackType>{TimelineTrackType.bass},
        soloTracks: const <TimelineTrackType>{TimelineTrackType.bass},
      );
      expect(soloBass.eventsForTrack(TimelineTrackType.bass), isNotEmpty);
      expect(soloBass.eventsForTrack(TimelineTrackType.harmony), isEmpty);
      expect(soloBass.eventsForTrack(TimelineTrackType.melody), isEmpty);
    });

    test('seeking into a sustained event clips only the playback manifest', () {
      final session = SongSessionController()
        ..generate(request: _request(seed: 450003));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();
      final source = timeline.eventsForTrack(TimelineTrackType.harmony).first;
      final performedStart =
          source.performedStartBeat.clamp(0.0, timeline.totalBeats);
      final seekBeat = performedStart + (source.performedDurationBeats * 0.5);

      final plan = planner.build(
        timeline,
        startBeat: seekBeat,
        endBeat: seekBeat + 1,
      );
      final clipped =
          plan.events.where((event) => identical(event.source, source)).first;

      expect(clipped.startBeat, closeTo(seekBeat, 0.000001));
      expect(clipped.durationBeats, lessThan(source.performedDurationBeats));
      expect(source.startBeat, 0);
      expect(source.durationBeats, greaterThan(0));
    });

    test('section playback plan never escapes the selected section', () {
      final session = SongSessionController()
        ..generate(request: _request(seed: 450004));
      final timeline = session.currentTimeline!;
      const planner = TimelinePlaybackPlanner();
      final section = timeline.sectionById('chorus-1')!;

      final plan = planner.section(timeline, section.id);

      expect(plan.startBeat, section.startBeat);
      expect(plan.endBeat, section.endBeat);
      expect(plan.events, isNotEmpty);
      for (final event in plan.events) {
        expect(event.startBeat, greaterThanOrEqualTo(section.startBeat));
        expect(event.endBeat, lessThanOrEqualTo(section.endBeat + 0.000001));
      }
    });

    testWidgets('full-song transport stays compact and navigates sections',
        (tester) async {
      final session = SongSessionController()
        ..generate(request: _request(seed: 450005));
      final transport = _FakeTimelineTransport();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: FullSongTransport(
                  session: session,
                  transport: transport,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('full-song-transport')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey<String>('song-seek-slider')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-play-stop')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-play-section')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('song-section-loop')), findsOneWidget);
      expect(find.text('CHORD'), findsOneWidget);
      expect(find.text('MELODY'), findsOneWidget);
      expect(find.text('BASS'), findsOneWidget);
      expect(session.selectedSectionId, 'intro');

      await tester.tap(find.byKey(const ValueKey<String>('song-next-section')));
      await tester.pumpAndSettle();
      expect(session.selectedSectionId, 'verse-1');
      expect(transport.songBeat, 16);

      await tester.tap(find.byKey(const ValueKey<String>('song-section-loop')));
      await tester.pumpAndSettle();
      expect(transport.looping, isTrue);
    });
  });
}
