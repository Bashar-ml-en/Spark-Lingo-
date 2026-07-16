import 'package:flutter/foundation.dart';

@immutable
class Flashcard {
  final String id;
  final String front;
  final String back;
  final String? context;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.context,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      context: json['context'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'context': context,
    };
  }
}

@immutable
class Lesson {
  final String id;
  final String title;
  final String description;
  final List<Flashcard> flashcards;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.flashcards,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final cardList = json['flashcards'] as List<dynamic>? ?? [];
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      flashcards: cardList.map((c) => Flashcard.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'flashcards': flashcards.map((c) => c.toJson()).toList(),
    };
  }
}

@immutable
class Unit {
  final String id;
  final String title;
  final String description;
  final List<Lesson> lessons;

  const Unit({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    final lessonList = json['lessons'] as List<dynamic>? ?? [];
    return Unit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lessons: lessonList.map((l) => Lesson.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'lessons': lessons.map((l) => l.toJson()).toList(),
    };
  }
}

@immutable
class LanguageSyllabus {
  final String languageName;
  final List<Unit> units;

  const LanguageSyllabus({
    required this.languageName,
    required this.units,
  });

  factory LanguageSyllabus.fromJson(String language, Map<String, dynamic> json) {
    final unitList = json['units'] as List<dynamic>? ?? [];
    return LanguageSyllabus(
      languageName: language,
      units: unitList.map((u) => Unit.fromJson(u as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languageName': languageName,
      'units': units.map((u) => u.toJson()).toList(),
    };
  }
}
