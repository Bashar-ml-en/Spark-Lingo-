import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/legal_config.dart';

/// Processing purposes that require an approved notice and an affirmative,
/// server-recorded choice before the application enables the related feature.
enum ConsentPurpose {
  analytics,
  aiProcessing,
  voiceProcessing;

  String get documentKey => switch (this) {
    ConsentPurpose.analytics => 'analytics',
    ConsentPurpose.aiProcessing => 'ai_processing',
    ConsentPurpose.voiceProcessing => 'voice_processing',
  };

  LegalDocument? get document => switch (this) {
    ConsentPurpose.analytics => LegalConfig.analyticsNoticeDocument,
    ConsentPurpose.aiProcessing ||
    ConsentPurpose.voiceProcessing => LegalConfig.aiAndVoiceNoticeDocument,
  };
}

class ConsentConfigurationException implements Exception {
  const ConsentConfigurationException();
}

class ConsentServiceException implements Exception {
  const ConsentServiceException();
}

/// Accesses the consent ledger only through server-side RPCs.
///
/// The mobile client never supplies a user id or timestamp, and it cannot
/// write the underlying tables directly. A missing legal build configuration,
/// inactive document registry entry, missing session, or malformed server
/// response is treated as no permission to enable processing.
class ConsentService {
  ConsentService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> hasCurrentConsent(ConsentPurpose purpose) async {
    final document = purpose.document;
    if (document == null || _client.auth.currentUser == null) return false;

    try {
      final data = await _client.rpc(
        'has_current_user_consent',
        params: {
          'p_document_key': purpose.documentKey,
          'p_document_version': document.version,
        },
      );
      final record = _firstRecord(data);
      final hasConsent = record?['has_consent'];
      if (hasConsent is! bool) throw const ConsentServiceException();
      return hasConsent;
    } catch (_) {
      // The caller must fail closed. Do not log server payloads, document
      // metadata, or user context from a privacy-control path.
      throw const ConsentServiceException();
    }
  }

  Future<void> recordConsent(ConsentPurpose purpose) async {
    final document = purpose.document;
    if (document == null || _client.auth.currentUser == null) {
      throw const ConsentConfigurationException();
    }

    try {
      final data = await _client.rpc(
        'record_user_consent',
        params: {
          'p_document_key': purpose.documentKey,
          'p_document_version': document.version,
        },
      );
      final record = _firstRecord(data);
      if (record?['accepted_at'] is! String) {
        throw const ConsentServiceException();
      }
    } catch (error) {
      if (error is ConsentConfigurationException) rethrow;
      throw const ConsentServiceException();
    }
  }

  Future<void> withdrawConsent(ConsentPurpose purpose) async {
    final document = purpose.document;
    if (document == null || _client.auth.currentUser == null) {
      throw const ConsentConfigurationException();
    }

    try {
      final data = await _client.rpc(
        'withdraw_user_consent',
        params: {
          'p_document_key': purpose.documentKey,
          'p_document_version': document.version,
        },
      );
      final record = _firstRecord(data);
      if (record == null || record['recorded'] is! bool) {
        throw const ConsentServiceException();
      }
    } catch (error) {
      if (error is ConsentConfigurationException) rethrow;
      throw const ConsentServiceException();
    }
  }

  Map<String, dynamic>? _firstRecord(dynamic data) {
    final value = switch (data) {
      final Map<String, dynamic> record => record,
      final Map record => Map<String, dynamic>.from(record),
      final List values when values.isNotEmpty && values.first is Map =>
        Map<String, dynamic>.from(values.first as Map),
      _ => null,
    };
    return value;
  }
}

final consentServiceProvider = Provider<ConsentService>((ref) {
  return ConsentService();
});
