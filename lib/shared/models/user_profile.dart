import 'package:flutter/foundation.dart';

@immutable
class UserProfile {
  final String id;
  final String? displayName;
  final DateTime createdAt;
  final DateTime trialExpiresAt;
  final bool isPremium;
  final String? nativeLanguage;
  final List<String> targetLanguages;

  const UserProfile({
    required this.id,
    this.displayName,
    required this.createdAt,
    required this.trialExpiresAt,
    required this.isPremium,
    this.nativeLanguage,
    required this.targetLanguages,
  });

  // Convert PostgreSQL JSON map to UserProfile instance
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      trialExpiresAt: DateTime.parse(map['trial_expires_at'] as String),
      isPremium: map['is_premium'] as bool? ?? false,
      nativeLanguage: map['native_language'] as String?,
      targetLanguages: List<String>.from(map['target_languages'] ?? []),
    );
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
      'target_languages': targetLanguages,
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
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      trialExpiresAt: trialExpiresAt ?? this.trialExpiresAt,
      isPremium: isPremium ?? this.isPremium,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
    );
  }
}
