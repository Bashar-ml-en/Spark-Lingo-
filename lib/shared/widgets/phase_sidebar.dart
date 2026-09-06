import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/language_theme_registry.dart';
import '../models/curriculum.dart';

/// Learning-path navigation sidebar for the home screen.
///
/// Lists every unit (phase) of the active language; expanding a unit reveals
/// its lessons, and tapping a lesson both scrolls the curriculum to that unit
/// and opens the lesson directly ([onLessonSelected]). Wide layouts pin this
/// panel beside the content; compact layouts use it inside an end drawer via
/// [drawerBody].
class PhaseSidebar extends ConsumerStatefulWidget {
  final String langCode;
  final List<Unit> units;
  final int selectedUnitIndex;
  final ValueChanged<int> onUnitSelected;
  final void Function(int unitIndex, Lesson lesson) onLessonSelected;

  const PhaseSidebar({
    super.key,
    required this.langCode,
    required this.units,
    required this.selectedUnitIndex,
    required this.onUnitSelected,
    required this.onLessonSelected,
  });

  static const double panelWidth = 280;

  /// Drawer variant used by compact layouts.
  static Widget drawerBody({
    required BuildContext scaffoldContext,
    required String langCode,
    required List<Unit> units,
    required int selectedUnitIndex,
    required ValueChanged<int> onUnitSelected,
    required void Function(int unitIndex, Lesson lesson) onLessonSelected,
  }) {
    return PhaseSidebar(
      langCode: langCode,
      units: units,
      selectedUnitIndex: selectedUnitIndex,
      onUnitSelected: (index) {
        Navigator.of(scaffoldContext).pop();
        onUnitSelected(index);
      },
      onLessonSelected: (unitIndex, lesson) {
        Navigator.of(scaffoldContext).pop();
        onLessonSelected(unitIndex, lesson);
      },
    );
  }

  @override
  ConsumerState<PhaseSidebar> createState() => _PhaseSidebarState();
}

class _PhaseSidebarState extends ConsumerState<PhaseSidebar> {
  int? _expandedUnitIndex;

  @override
  void initState() {
    super.initState();
    _expandedUnitIndex = widget.selectedUnitIndex;
  }

  @override
  void didUpdateWidget(covariant PhaseSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnitIndex != widget.selectedUnitIndex &&
        _expandedUnitIndex != widget.selectedUnitIndex) {
      _expandedUnitIndex = widget.selectedUnitIndex;
    }
  }

  void _toggleUnit(int index) {
    setState(() {
      _expandedUnitIndex = _expandedUnitIndex == index ? null : index;
    });
    widget.onUnitSelected(index);
  }

  IconData _lessonIcon(Lesson lesson) {
    if (lesson.type == 'ai_tutor_session' ||
        lesson.type == 'mock_exam_section') {
      return Icons.mic_none_outlined;
    }
    return Icons.style_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = LanguageThemeRegistry.themeFor(widget.langCode);
    return Container(
      width: PhaseSidebar.panelWidth,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: national symbol + language names.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SvgPicture.asset(
                    theme.motifAsset,
                    width: 40,
                    height: 40,
                    placeholderBuilder: (_) =>
                        const SizedBox(width: 40, height: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.units.length} phases',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'LEARNING PATH',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Color(0xFF475569),
              ),
            ),
          ),
          // Units (phases) with expandable lesson lists.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: widget.units.length,
              itemBuilder: (context, index) {
                final unit = widget.units[index];
                final selected = index == widget.selectedUnitIndex;
                final expanded = _expandedUnitIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: selected
                            ? theme.primaryColor.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleUnit(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? theme.primaryColor
                                        : const Color(0xFFF3F4F6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    unit.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? theme.primaryColor
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Lesson list for the expanded unit.
                      if (expanded)
                        Consumer(
                          builder: (context, ref, _) {
                            final lessonsAsync = ref.watch(
                              lessonsProvider(unit.id),
                            );
                            return lessonsAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              error: (_, _) => const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Lessons unavailable right now.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              data: (lessons) => Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 20,
                                  top: 2,
                                  bottom: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final lesson in lessons)
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        onTap: () => widget.onLessonSelected(
                                          index,
                                          lesson,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 7,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _lessonIcon(lesson),
                                                size: 14,
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.75),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  lesson.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF4B5563),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
