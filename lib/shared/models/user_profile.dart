import 'package:flutter/foundation.dart';
import '../../core/constants/language_catalog.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final DateTime createdAt;
  final DateTime trialExpiresAt;
  final bool isPremium;
  final String? nativeLanguage;
  final List<String> targetLanguages;
  final String? activeLanguage;

  const UserProfile({
    required this.id,
    this.displayName,
    required this.createdAt,
    required this.trialExpiresAt,
    required this.isPremium,
    this.nativeLanguage,
    required this.targetLanguages,
    this.activeLanguage,
  });

  // Convert PostgreSQL JSON map to UserProfile instance
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final storedLanguages =
        (map['target_languages'] as List<dynamic>? ?? const [])
            .whereType<String>();
    final targetLanguages = LanguageCatalog.canonicalizeAll(storedLanguages);
    final storedActiveLanguage = LanguageCatalog.tryCanonicalCode(
      map['active_language'] as String?,
    );
    final activeLanguage = targetLanguages.contains(storedActiveLanguage)
        ? storedActiveLanguage
        : (targetLanguages.isEmpty ? null : targetLanguages.first);

    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      trialExpiresAt: _parseDate(map['trial_expires_at']) ?? DateTime.now(),
      isPremium: map['is_premium'] as bool? ?? false,
      nativeLanguage: map['native_language'] as String?,
      targetLanguages: targetLanguages,
      activeLanguage: activeLanguage,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Convert UserProfile instance to PostgreSQL JSON map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
      'trial_expires_at': trialExpiresAt.toIso8601String(),
      'is_premium': isPremium,
      'native_language': nativeLanguage,
      'target_languages': LanguageCatalog.canonicalizeAll(targetLanguages),
      'active_language': LanguageCatalog.tryCanonicalCode(activeLanguage),
    };
  }

  // CopyWith helper to modify specific parameters immutably
  UserProfile copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    DateTime? trialExpiresAt,
    bool? isPremium,
    String? nativeLanguage,
    List<String>? targetLanguages,
    String? activeLanguage,
    bool clearActiveLanguage = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      isPremium: isPremium ?? this.isPremium,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguages: targetLanguages == null
          ? this.targetLanguages
          : LanguageCatalog.canonicalizeAll(targetLanguages),
      activeLanguage: clearActiveLanguage
          ? null
          : (LanguageCatalog.tryCanonicalCode(activeLanguage) ??
                this.activeLanguage),
    );
  }
}
