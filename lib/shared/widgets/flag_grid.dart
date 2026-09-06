import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/language_theme_registry.dart';
import '../../core/constants/language_catalog.dart';
import '../../shared/models/language_theme.dart';
import '../../features/onboarding/widgets/flag_tile.dart';

class FlagGrid extends StatefulWidget {
  final String? selectedLanguageCode;
  final void Function(String langCode, FlagInfo selectedFlag) onLanguageSelected;

  const FlagGrid({
    super.key,
    this.selectedLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  State<FlagGrid> createState() => _FlagGridState();
}

class _FlagGridState extends State<FlagGrid> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Popular',
    'European',
    'Asian',
    'Middle Eastern',
  ];

  static const Map<String, String> _englishNames = {
    'en': 'English',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'th': 'Thai',
    'tl': 'Tagalog',
    'ms': 'Malay',
  };

  static const Map<String, List<String>> _categoryMap = {
    'Popular': ['es', 'ja', 'fr', 'de', 'zh', 'ms', 'ar'],
    'European': ['es', 'fr', 'de', 'it', 'pt', 'ru', 'en'],
    'Asian': ['ja', 'ko', 'zh', 'hi', 'th', 'tl', 'ms'],
    'Middle Eastern': ['ar'],
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
      showModalBottomSheet(
        context: context,
        backgroundColor: SparkLingoTheme.surfaceContainer,
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
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: theme.flags.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: SparkLingoTheme.surfaceContainerHighest, height: 1),
                      itemBuilder: (context, index) {
                        final flag = theme.flags[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: SparkLingoTheme.surfaceContainerHighest,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            flag.locale,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
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
      widget.onLanguageSelected(langCode, theme.flags.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> allCodes = LanguageThemeRegistry.availableLanguageCodes
        .where(LanguageCatalog.hasBundledCurriculum)
        .toList(growable: false);

    final List<MapEntry<String, LanguageTheme>> list = allCodes.map((code) {
      return MapEntry(code, LanguageThemeRegistry.themeFor(code));
    }).toList();

    // Category filter
    final categoryFiltered = _selectedCategory == 'All'
        ? list
        : list.where((entry) =>
            _categoryMap[_selectedCategory]?.contains(entry.key) ?? false).toList();

    // Search query filter
    final filteredList = categoryFiltered.where((entry) {
      final code = entry.key;
      final theme = entry.value;
      final english = _englishNames[code]?.toLowerCase() ?? '';
      final native = theme.displayName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return english.contains(query) || native.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input Field
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: SparkLingoTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SparkLingoTheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search 15+ languages...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
        ),

        // Category Filter Chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final isCatSelected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCatSelected
                        ? SparkLingoTheme.electricCyan.withValues(alpha: 0.2)
                        : SparkLingoTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCatSelected
                          ? SparkLingoTheme.electricCyan
                          : SparkLingoTheme.surfaceContainerHighest,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCatSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isCatSelected
                            ? SparkLingoTheme.electricCyan
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 2-Column Responsive Flag Grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int columns = constraints.maxWidth > 700 ? 3 : 2;

              if (filteredList.isEmpty) {
                return Center(
                  child: Text(
                    'No languages found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final entry = filteredList[index];
                  final code = entry.key;
                  final theme = entry.value;
                  final englishName = _englishNames[code] ?? theme.displayName;
                  final isSelected = widget.selectedLanguageCode == code;

                  return FlagTile(
                    nativeName: theme.displayName,
                    englishName: englishName,
                    flagAsset: theme.flags.isNotEmpty
                        ? theme.flags.first.flagAsset
                        : 'assets/flags/en_us.svg',
                    isSelected: isSelected,
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
