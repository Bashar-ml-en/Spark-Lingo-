import 'package:flutter/foundation.dart';

@immutable
class Flashcard {
  final String id;
  final String front;
  final String back;
  final String? context;
  final String? source;
  final String? sourceAttribution;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.context,
    this.source,
    this.sourceAttribution,
  });

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'] as String,
      front: map['front_text'] as String,
      back: map['back_text'] as String,
      context: map['context_sentence'] as String?,
      source: map['source'] as String?,
      sourceAttribution: map['source_attribution'] as String?,
    );
  }
}

@immutable
class Lesson {
  final String id;
  final String title;
  final String description;
  final String? sourceAttribution;
  final String? type;
  final String? skill;
  final String? rubricRef;
  final String? honestyDisclaimer;
  final String? sparkyPromptTemplate;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    this.sourceAttribution,
    this.type,
    this.skill,
    this.rubricRef,
    this.honestyDisclaimer,
    this.sparkyPromptTemplate,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] ?? '',
      sourceAttribution: map['source_attribution'] as String?,
      type: map['type'] as String?,
      skill: map['skill'] as String?,
      rubricRef: map['rubric_ref'] as String?,
      honestyDisclaimer: map['honesty_disclaimer'] as String?,
      sparkyPromptTemplate: map['sparky_prompt_template'] as String?,
    );
  }
}

@immutable
class Unit {
  final String id;
  final String title;
  final String description;
  final String? sourceAttribution;
  final bool isReviewed;

  const Unit({
    required this.id,
    required this.title,
    required this.description,
    this.sourceAttribution,
    this.isReviewed = false,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] ?? '',
      sourceAttribution: map['source_attribution'] as String?,
      isReviewed: map['is_reviewed'] as bool? ?? false,
    );
  }
}
