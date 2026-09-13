// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get examPracticePreview => 'Exam practice preview';

  @override
  String get scoredExamPracticeInDevelopment =>
      'Scored exam practice is in development';

  @override
  String get examPreviewAvailability =>
      'Spark Lingo does not currently administer, time, score, or estimate results for this exam. No readiness level or practice score has been calculated for your account.';

  @override
  String get examPreviewNextStep =>
      'Continue with course practice while we complete reviewed content, audio, answer capture, and a transparent scoring process.';

  @override
  String get returnToLearning => 'Return to learning';

  @override
  String get examPreviewSemantics =>
      'Exam practice preview. Scored exam practice is not available.';

  @override
  String get mockExamPreview => 'Mock exam preview';

  @override
  String get mockExamsUnavailable => 'Mock exams are not available yet';

  @override
  String get mockExamPreviewAvailability =>
      'This preview does not record answers, use a timer, play exam audio, send recordings, submit work, or calculate a score. We will make these capabilities available only after they are complete and clearly explained.';

  @override
  String get returnToExamPreview => 'Return to exam preview';

  @override
  String get mockExamPreviewSemantics =>
      'Mock exam preview. A scored mock exam is unavailable.';

  @override
  String get sessionReportTitle => 'Session report';

  @override
  String get sessionReportUnavailable =>
      'Your session report is temporarily unavailable. Try again later.';

  @override
  String get retry => 'Retry';

  @override
  String get sessionReportNoDataTitle => 'No saved corrections yet';

  @override
  String get sessionReportNoDataBody =>
      'Sparky has no saved corrections for this language yet.';

  @override
  String get sessionReportFocusAreas => 'Focus areas';

  @override
  String get sessionReportCorrections => 'Recent corrections';

  @override
  String get addToReview => 'Add to review';

  @override
  String get addedToReview => 'Added to your correction review deck';

  @override
  String get alreadyInReview => 'Already in your review deck';

  @override
  String get signInToSaveCorrections =>
      'Sign in to save corrections to your review deck';
}
