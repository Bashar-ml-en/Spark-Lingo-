import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/components.dart';

/// Stitch Design System — CEFR Oral Scenarios / Situational Milestones
/// Corresponds to Stitch screen: "AI Scenario Selector"
class CEFRScenariosView extends StatelessWidget {
  final String languageCode;
  final void Function(String scenarioTitle) onStartScenario;

  const CEFRScenariosView({
    super.key,
    required this.languageCode,
    required this.onStartScenario,
  });

  List<Map<String, String>> _scenariosForLanguage(String lang) {
    switch (lang.toLowerCase()) {
      case 'ms':
        return const [
          {
            'title': 'Pesanan di Kedai Kopi & Pasar Malam',
            'category': 'Sosial & Makanan',
            'level': 'A1',
            'description': 'Pesan makanan tempatan, tanya cadangan menu, dan bayar dengan yakin.',
            'icon': 'restaurant',
          },
          {
            'title': 'Navigasi Transit KL Sentral & Lapangan Terbang',
            'category': 'Perjalanan & Logistik',
            'level': 'A2',
            'description': 'Tanya arah jalan, beli tiket transit harian, dan fahami pengumuman perjalanan.',
            'icon': 'flight_takeoff',
          },
          {
            'title': 'Perbincangan Perjanjian Sewa Rumah',
            'category': 'Kehidupan Harian',
            'level': 'B1',
            'description': 'Bincangkan kadar sewa, bayaran utiliti, dan syarat penyelenggaraan dengan tuan rumah.',
            'icon': 'home_work',
          },
          {
            'title': 'Temuduga Pekerjaan & Pembentangan Projek',
            'category': 'Profesional',
            'level': 'B2',
            'description': 'Terangkan pengalaman kerja, jawab soalan situasi, dan nyatakan matlamat kerjaya.',
            'icon': 'business_center',
          },
          {
            'title': 'Klinik Kesihatan & Rujukan Perubatan',
            'category': 'Kecemasan & Kesihatan',
            'level': 'B1',
            'description': 'Jelaskan simptom kesihatan, fahami preskripsi ubat, dan dapatkan nasihat doktor.',
            'icon': 'local_hospital',
          },
        ];
      case 'ja':
        return const [
          {
            'title': '居酒屋・カフェでのおすすめ注文',
            'category': '食事・交流',
            'level': 'A1',
            'description': '人気のおすすめ料理を尋ね、お会計までスムーズに会話します。',
            'icon': 'restaurant',
          },
          {
            'title': '新幹線・駅での乗り換え案内',
            'category': '旅行・移動',
            'level': 'A2',
            'description': '指定席の予約確認や乗り換え口への道順を駅員に質問します。',
            'icon': 'flight_takeoff',
          },
          {
            'title': '不動産屋での賃貸契約相談',
            'category': '日常生活',
            'level': 'B1',
            'description': '初期費用や契約条件、家具・家電付きの部屋について相談します。',
            'icon': 'home_work',
          },
          {
            'title': 'ビジネス商談と敬語対応',
            'category': 'ビジネス',
            'level': 'B2',
            'description': '適切な敬語を使い、クライアントへの企画提案と日程調整を行います。',
            'icon': 'business_center',
          },
          {
            'title': '病院での問診と症状説明',
            'category': '医療・健康',
            'level': 'B1',
            'description': '体調不良の症状やアレルギーについて正確に医師へ伝えます。',
            'icon': 'local_hospital',
          },
        ];
      case 'ar':
        return const [
          {
            'title': 'الضيافة والطلب في المقهى والمطعم',
            'category': 'المجتمع والضيافة',
            'level': 'A1',
            'description': 'طلب الوجبات التقليدية والاستفسار عن المكونات والحساب بأسلوب طبيعي.',
            'icon': 'restaurant',
          },
          {
            'title': 'إجراءات المطار والجمارك',
            'category': 'السفر والنقل',
            'level': 'A2',
            'description': 'شرح مسار الرحلة وإجراءات الدخول واستلام الأمتعة بسهولة.',
            'icon': 'flight_takeoff',
          },
          {
            'title': 'مفاوضة عقد إيجار سكن',
            'category': 'الحياة اليومية',
            'level': 'B1',
            'description': 'مناقشة بنود الإيجار والخدمات ومواعيد السداد مع المالك.',
            'icon': 'home_work',
          },
          {
            'title': 'محادثة عمل ومقابلة مهنية',
            'category': 'المجال المهني',
            'level': 'B2',
            'description': 'استعراض الخبرات ومناقشة تفاصيل المشاريع والتفاوض المهني.',
            'icon': 'business_center',
          },
          {
            'title': 'استشارة الطبيب والطوارئ الصحية',
            'category': 'الرعاية الصحية',
            'level': 'B1',
            'description': 'وصف الأعراض وفهم التعليمات الطبية والجرعات الدوائية بدقة.',
            'icon': 'local_hospital',
          },
        ];
      case 'es':
        return const [
          {
            'title': 'Pedir en un Bar de Tapas Tradicional',
            'category': 'Gastronomía y Vida Social',
            'level': 'A1',
            'description': 'Pide especialidades locales, consulta ingredientes y pide la cuenta con soltura.',
            'icon': 'restaurant',
          },
          {
            'title': 'Aduana del Aeropuerto y Tránsitos',
            'category': 'Viajes y Logística',
            'level': 'A2',
            'description': 'Explica tu itinerario, declara equipaje y comprende avisos de vuelo.',
            'icon': 'flight_takeoff',
          },
          {
            'title': 'Negociación de Contrato de Alquiler',
            'category': 'Vida Diaria',
            'level': 'B1',
            'description': 'Conversa sobre condiciones de arrendamiento, gastos de comunidad y fianzas.',
            'icon': 'home_work',
          },
          {
            'title': 'Entrevista de Trabajo y Presentación',
            'category': 'Ámbito Profesional',
            'level': 'B2',
            'description': 'Defiende tu trayectoria, responde a preguntas complejas y negocia condiciones.',
            'icon': 'business_center',
          },
          {
            'title': 'Consulta de Urgencias y Farmacia',
            'category': 'Salud y Cuidados',
            'level': 'B1',
            'description': 'Describe síntomas agudos, antecedentes y entiende las pautas de medicación.',
            'icon': 'local_hospital',
          },
        ];
      default:
        return const [
          {
            'title': 'Café & Traditional Bistro Ordering',
            'category': 'Social & Dining',
            'level': 'A1',
            'description': 'Order regional dishes, ask about dietary options, and settle the bill smoothly.',
            'icon': 'restaurant',
          },
          {
            'title': 'Airport Transit & Customs Clearance',
            'category': 'Travel & Logistics',
            'level': 'A2',
            'description': 'Explain your itinerary, declare belongings, and navigate transit instructions.',
            'icon': 'flight_takeoff',
          },
          {
            'title': 'Apartment Lease & Living Logistics',
            'category': 'Daily Living',
            'level': 'B1',
            'description': 'Discuss tenancy terms, utility arrangements, and property maintenance.',
            'icon': 'home_work',
          },
          {
            'title': 'Professional Interview & Strategy Debate',
            'category': 'Professional',
            'level': 'B2',
            'description': 'Articulate experience, navigate technical pushback, and debate trade-offs.',
            'icon': 'business_center',
          },
          {
            'title': 'Medical Clinic & Pharmacy Consultation',
            'category': 'Healthcare',
            'level': 'B1',
            'description': 'Describe acute symptoms, past medical history, and follow prescription instructions.',
            'icon': 'local_hospital',
          },
        ];
    }
  }

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
    final scenarioList = _scenariosForLanguage(languageCode);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'CEFR ORAL PROFICIENCY · SITUATIONAL MILESTONES',
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
              'Spontaneous Conversational Roleplay',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: StitchTokens.textPrimary,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Build spontaneous communicative fluency across real-world situational contexts with Sparky AI.',
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
        ...scenarioList.map((sc) {
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
                    label: 'START ORAL PRACTICE',
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

/// Backward compatibility alias for existing code
typedef BossDrillsView = CEFRScenariosView;
