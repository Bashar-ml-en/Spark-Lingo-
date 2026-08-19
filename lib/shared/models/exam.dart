import 'package:flutter/foundation.dart';

@immutable
class ExamDefinition {
  final String id;
  final String languageCode;
  final String displayName;
  final String issuingBody;
  final String framework;
  final List<String> skillsTested;
  final String? scoringNotes;
  final String? sourceUrl;

  const ExamDefinition({
    required this.id,
    required this.languageCode,
    required this.displayName,
    required this.issuingBody,
    required this.framework,
    required this.skillsTested,
    this.scoringNotes,
    this.sourceUrl,
  });

  factory ExamDefinition.fromJson(Map<String, dynamic> json) {
    return ExamDefinition(
      id: json['id'] as String,
      languageCode: json['language_code'] as String,
      displayName: json['display_name'] as String,
      issuingBody: json['issuing_body'] as String,
      framework: json['framework'] as String,
      skillsTested: List<String>.from(json['skills_tested'] ?? []),
      scoringNotes: json['scoring_notes'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }
}

@immutable
class MockExam {
  final String id;
  final String examId;
  final String title;
  final String targetLevel;
  final int timeLimitMinutes;
  final bool isFullLength;

  const MockExam({
    required this.id,
    required this.examId,
    required this.title,
    required this.targetLevel,
    required this.timeLimitMinutes,
    required this.isFullLength,
  });

  factory MockExam.fromJson(Map<String, dynamic> json) {
    return MockExam(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      title: json['title'] as String,
      targetLevel: json['target_level'] as String,
      timeLimitMinutes: json['time_limit_minutes'] as int,
      isFullLength: json['is_full_length'] as bool,
    );
  }
}

@immutable
class MockExamSection {
  final String id;
  final String mockExamId;
  final String skill;
  final int sectionOrder;
  final Map<String, dynamic> promptContent;
  final double maxScore;

  const MockExamSection({
    required this.id,
    required this.mockExamId,
    required this.skill,
    required this.sectionOrder,
    required this.promptContent,
    required this.maxScore,
  });

  factory MockExamSection.fromJson(Map<String, dynamic> json) {
    return MockExamSection(
      id: json['id'] as String,
      mockExamId: json['mock_exam_id'] as String,
      skill: json['skill'] as String,
      sectionOrder: json['section_order'] as int,
      promptContent: json['prompt_content'] as Map<String, dynamic>? ?? {},
      maxScore: (json['max_score'] as num).toDouble(),
    );
  }
}

@immutable
class UserExamReadiness {
  final String userId;
  final String examId;
  final String? currentEstimatedLevel;
  final String? targetLevel;
  final DateTime? targetDate;

  const UserExamReadiness({
    required this.userId,
    required this.examId,
    this.currentEstimatedLevel,
    this.targetLevel,
    this.targetDate,
  });

  factory UserExamReadiness.fromJson(Map<String, dynamic> json) {
    return UserExamReadiness(
      userId: json['user_id'] as String,
      examId: json['exam_id'] as String,
      currentEstimatedLevel: json['current_estimated_level'] as String?,
      targetLevel: json['target_level'] as String?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
    );
  }
}

@immutable
class UserMockExamAttempt {
  final String id;
  final String userId;
  final String mockExamId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double? overallScore;
  final String? overallBandOrLevel;
  final Map<String, dynamic>? aiFeedback;

  const UserMockExamAttempt({
    required this.id,
    required this.userId,
    required this.mockExamId,
    required this.startedAt,
    this.completedAt,
    this.overallScore,
    this.overallBandOrLevel,
    this.aiFeedback,
  });

  factory UserMockExamAttempt.fromJson(Map<String, dynamic> json) {
    return UserMockExamAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mockExamId: json['mock_exam_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      overallBandOrLevel: json['overall_band_or_level'] as String?,
      aiFeedback: json['ai_feedback'] as Map<String, dynamic>?,
    );
  }
}
