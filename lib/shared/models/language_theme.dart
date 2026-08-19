import 'package:flutter/material.dart';

enum LanguageTextDirection { ltr, rtl }

class FlagInfo {
  final String locale;
  final String flagAsset;
  final String countryName;

  const FlagInfo({
    required this.locale,
    required this.flagAsset,
    required this.countryName,
  });

  factory FlagInfo.fromJson(Map<String, dynamic> json) {
    return FlagInfo(
      locale: json['locale'] as String,
      flagAsset: json['flag_asset'] as String,
      countryName: json['country_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale': locale,
      'flag_asset': flagAsset,
      'country_name': countryName,
    };
  }
}

class LanguageTheme {
  final String displayName;
  final List<FlagInfo> flags;
  final Color primaryColor;
  final Color accentColor;
  final String fontFamily;
  final LanguageTextDirection textDirection;
  final String motif;
  final String motifAsset;

  const LanguageTheme({
    required this.displayName,
    required this.flags,
    required this.primaryColor,
    required this.accentColor,
    required this.fontFamily,
    required this.textDirection,
    required this.motif,
    required this.motifAsset,
  });

  factory LanguageTheme.fromJson(Map<String, dynamic> json) {
    return LanguageTheme(
      displayName: json['display_name'] as String? ?? '',
      flags: json['flags'] != null
          ? (json['flags'] as List<dynamic>)
                .map((item) => FlagInfo.fromJson(item as Map<String, dynamic>))
                .toList()
          : const [],
      primaryColor: parseHexColor(json['primary_color'] as String),
      accentColor: parseHexColor(json['accent_color'] as String),
      fontFamily: json['font_family'] as String? ?? 'Inter',
      textDirection: (json['text_direction'] as String? ?? 'ltr') == 'rtl'
          ? LanguageTextDirection.rtl
          : LanguageTextDirection.ltr,
      motif: json['motif'] as String? ?? '',
      motifAsset: json['motif_asset'] as String? ?? '',
    );
  }

  static Color parseHexColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    }
    return Color(int.parse(cleanHex, radix: 16));
  }
}
