import 'package:shared_preferences/shared_preferences.dart';

import '../engine/song_candidate.dart';

class ProducerPreferenceSnapshot {
  const ProducerPreferenceSnapshot(this.counts);

  final Map<ProducerVariationStyle, int> counts;

  int countFor(ProducerVariationStyle style) => counts[style] ?? 0;

  int get totalChoices => counts.values.fold<int>(0, (sum, value) => sum + value);

  ProducerVariationStyle? get preferredStyle {
    if (totalChoices == 0) return null;
    ProducerVariationStyle? best;
    var bestCount = -1;
    for (final style in const <ProducerVariationStyle>[
      ProducerVariationStyle.polished,
      ProducerVariationStyle.creative,
      ProducerVariationStyle.hook,
    ]) {
      final count = countFor(style);
      if (count > bestCount) {
        best = style;
        bestCount = count;
      }
    }
    return best;
  }

  double affinityFor(ProducerVariationStyle style) {
    if (totalChoices == 0) return 0.0;
    return countFor(style) / totalChoices;
  }
}

/// Small persistent taste model for Producer A/B/C choices.
///
/// Phase 5.4 intentionally records preference frequency without silently
/// changing the music ranking yet. The app can surface a truthful "your taste"
/// signal today, while a later phase can use the same data as a bounded ranking
/// prior once enough choices have accumulated.
class ProducerPreferenceStore {
  ProducerPreferenceStore._();

  static final ProducerPreferenceStore instance = ProducerPreferenceStore._();

  static const _prefix = 'producer_direction_count_';

  Future<ProducerPreferenceSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ProducerPreferenceSnapshot({
      for (final style in const <ProducerVariationStyle>[
        ProducerVariationStyle.polished,
        ProducerVariationStyle.creative,
        ProducerVariationStyle.hook,
      ])
        style: prefs.getInt('$_prefix${style.name}') ?? 0,
    });
  }

  Future<ProducerPreferenceSnapshot> record(
    ProducerVariationStyle style,
  ) async {
    if (style == ProducerVariationStyle.raw) return load();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${style.name}';
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
    return load();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final style in const <ProducerVariationStyle>[
      ProducerVariationStyle.polished,
      ProducerVariationStyle.creative,
      ProducerVariationStyle.hook,
    ]) {
      await prefs.remove('$_prefix${style.name}');
    }
  }
}
