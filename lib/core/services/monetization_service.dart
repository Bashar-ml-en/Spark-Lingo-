import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'revenuecat_service.dart';

class MonetizationService {
  static const int freeDailyCap = 3;
  static const int freeMockExamsPerWeek = 1;
  static const int freePlacementTestsPerLanguage = 1;

  final Ref _ref;

  MonetizationService(this._ref);

  /// Checks if the user is allowed to perform a token-heavy exam rubric scoring call.
  Future<bool> canPerformRubricCall() async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_getTodayKey()) ?? 0;
    return count < freeDailyCap;
  }

  Future<void> incrementRubricCallCount() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  Future<int> getRemainingFreeAttempts() async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return 999;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_getTodayKey()) ?? 0;
    final remaining = freeDailyCap - count;
    return remaining < 0 ? 0 : remaining;
  }

  /// Check if user can take a mock exam this week
  Future<bool> canTakeMockExam() async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_getWeekKey()) ?? 0;
    return count < freeMockExamsPerWeek;
  }

  Future<void> incrementMockExamCount() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getWeekKey();
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  /// Check if user can take a placement test for a specific language
  Future<bool> canTakePlacementTest(String languageCode) async {
    final isPremium = await _ref.read(isPremiumProvider.future);
    if (isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final key = 'placement_test_$languageCode';
    final count = prefs.getInt(key) ?? 0;
    return count < freePlacementTestsPerLanguage;
  }

  Future<void> incrementPlacementTestCount(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'placement_test_$languageCode';
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return 'rubric_calls_${now.year}_${now.month}_${now.day}';
  }

  String _getWeekKey() {
    final now = DateTime.now();
    // A simple week key based on the year and week of year
    final int weekOfYear = ((now.day - now.weekday + 10) / 7).floor();
    return 'mock_exams_${now.year}_$weekOfYear';
  }
}

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return MonetizationService(ref);
});
