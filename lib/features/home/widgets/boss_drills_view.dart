import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// Stitch Design System — Boss Drills / AI Scenario Selector
/// Corresponds to Stitch screen: "AI Scenario Selector"
class BossDrillsView extends StatelessWidget {
  final String languageCode;
  final void Function(String scenarioTitle) onStartScenario;

  const BossDrillsView({
    super.key,
    required this.languageCode,
    required this.onStartScenario,
  });

  static const List<Map<String, String>> scenarios = [
    {
      'title': 'Airport Customs & Security',
      'category': 'Travel & Logistics',
      'level': 'A2',
      'description': 'Explain your itinerary, declare items, and navigate transit instructions with authority.',
      'icon': 'flight_takeoff',
    },
    {
      'title': 'Ordering at a Traditional Bistro',
      'category': 'Social & Dining',
      'level': 'B1',
      'description': 'Ask for local specialties, dietary modifications, and settle the bill naturally.',
      'icon': 'restaurant',
    },
    {
      'title': 'Apartment Lease Negotiation',
      'category': 'Daily Living',
      'level': 'B2',
      'description': 'Discuss lease terms, utility expenses, and maintenance guarantees with a landlord.',
      'icon': 'home_work',
    },
    {
      'title': 'Technical Strategy Presentation',
      'category': 'Professional',
      'level': 'C1',
      'description': 'Defend product architecture choices, address client pushback, and articulate trade-offs.',
      'icon': 'business_center',
    },
    {
      'title': 'Emergency Clinic Triage',
      'category': 'Urgent Care',
      'level': 'B1',
      'description': 'Describe acute symptoms, medical history, and understand prescription directions.',
      'icon': 'local_hospital',
    },
  ];

  IconData _iconFor(String name) {
    return switch (name) {
      'flight_takeoff' => Icons.flight_takeoff_rounded,
      'restaurant' => Icons.restaurant_rounded,
      'home_work' => Icons.home_work_rounded,
      'business_center' => Icons.business_center_rounded,
      'local_hospital' => Icons.local_hospital_rounded,
      _ => Icons.forum_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'BOSS DRILLS · SCENARIO LAB',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: StitchTokens.primaryIndigo,
                letterSpacing: 1.5,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Live High-Stakes Roleplay',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: StitchTokens.textPrimary,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Test spontaneous conversational agility under real situational pressure with Sparky AI.',
              style: TextStyle(
                fontSize: 13,
                color: StitchTokens.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Scenario cards
        ...scenarios.map((sc) {
          final level = sc['level']!;
          final title = sc['title']!;
          final desc = sc['description']!;
          final category = sc['category']!;
          final icon = _iconFor(sc['icon']!);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StitchGlassCard(
              isElevated: true,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: StitchTokens.primaryIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: StitchTokens.primaryIndigo.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: StitchTokens.primaryIndigo,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: StitchTokens.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: StitchTokens.textPrimary,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      StitchCefrBadge(level: level),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: StitchTokens.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StitchGradientButton(
                    label: 'ENGAGE SCENARIO',
                    icon: Icons.mic_rounded,
                    onPressed: () => onStartScenario(title),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
