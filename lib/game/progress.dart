import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stars earned per level, saved on the device.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();
  static const _key = 'quest_stars';

  final Map<int, int> _stars = {};

  int starsFor(int level) => _stars[level] ?? 0;
  bool isUnlocked(int level) => level == 0 || starsFor(level - 1) > 0;
  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in prefs.getStringList(_key) ?? <String>[]) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _stars[int.parse(parts[0])] = int.parse(parts[1]);
        }
      }
    } catch (e) {
      debugPrint('Could not load progress: $e');
    }
    notifyListeners();
  }

  Future<void> record(int level, int stars) async {
    if (stars <= starsFor(level)) return;
    _stars[level] = stars;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, [
        for (final e in _stars.entries) '${e.key}:${e.value}',
      ]);
    } catch (e) {
      debugPrint('Could not save progress: $e');
    }
  }
}
