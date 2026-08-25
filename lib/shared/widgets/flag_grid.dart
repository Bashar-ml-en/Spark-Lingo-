import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../core/constants/language_catalog.dart';
import '../../shared/models/language_theme.dart';
import '../../features/onboarding/widgets/flag_tile.dart';

class FlagGrid extends StatefulWidget {
  final void Function(String langCode, FlagInfo selectedFlag)
  onLanguageSelected;

  const FlagGrid({super.key, required this.onLanguageSelected});

  @override
  State<FlagGrid> createState() => _FlagGridState();
}

class _FlagGridState extends State<FlagGrid> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Map<String, String> _englishNames = {
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese (Mandarin)',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'th': 'Thai',
    'tl': 'Tagalog',
    'ms': 'Malay',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLanguageTap(
    BuildContext context,
    String langCode,
    LanguageTheme theme,
  ) {
    if (theme.flags.length > 1) {
      // Open bottom sheet for regional variants
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFFFFFFFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select region for ${theme.displayName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: theme.flags.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFFF3F4F6), height: 1),
                      itemBuilder: (context, index) {
                        final flag = theme.flags[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: SvgPicture.asset(
                              flag.flagAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            flag.countryName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          subtitle: Text(
                            flag.locale,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onLanguageSelected(langCode, flag);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Single flag option, resolve immediately
      widget.onLanguageSelected(langCode, theme.flags.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The visual registry intentionally contains future language themes. Only
    // expose a language for selection once this release contains curriculum for
    // it; otherwise users would land in an empty course after onboarding.
    final List<String> allCodes = LanguageThemeRegistry.availableLanguageCodes
        .where(LanguageCatalog.hasBundledCurriculum)
        .toList(growable: false);

    // Parse language data
    final List<MapEntry<String, LanguageTheme>> list = allCodes.map((code) {
      return MapEntry(code, LanguageThemeRegistry.themeFor(code));
    }).toList();

    // Apply query filters on English and native-script display names
    final filteredList = list.where((entry) {
      final code = entry.key;
      final theme = entry.value;
      final english = _englishNames[code]?.toLowerCase() ?? '';
      final native = theme.displayName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return english.contains(query) || native.contains(query);
    }).toList();

    return Column(
      children: [
        // Premium minimal search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search languages...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Responsive flag grid using LayoutBuilder
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int columns;
              if (constraints.maxWidth <= 600) {
                columns = 2; // Mobile
              } else if (constraints.maxWidth <= 1000) {
                columns = 3; // Tablet
              } else {
                columns = 4; // Desktop
              }

              if (filteredList.isEmpty) {
                return const Center(
                  child: Text(
                    'No languages found',
                    style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final entry = filteredList[index];
                  final code = entry.key;
                  final theme = entry.value;
                  final englishName = _englishNames[code] ?? theme.displayName;

                  return FlagTile(
                    nativeName: theme.displayName,
                    englishName: englishName,
                    flagAsset: theme.flags.isNotEmpty
                        ? theme.flags.first.flagAsset
                        : 'assets/flags/en_us.svg',
                    onTap: () => _handleLanguageTap(context, code, theme),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
