import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @examPracticePreview.
  ///
  /// In en, this message translates to:
  /// **'Exam practice preview'**
  String get examPracticePreview;

  /// No description provided for @scoredExamPracticeInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Scored exam practice is in development'**
  String get scoredExamPracticeInDevelopment;

  /// No description provided for @examPreviewAvailability.
  ///
  /// In en, this message translates to:
  /// **'Spark Lingo does not currently administer, time, score, or estimate results for this exam. No readiness level or practice score has been calculated for your account.'**
  String get examPreviewAvailability;

  /// No description provided for @examPreviewNextStep.
  ///
  /// In en, this message translates to:
  /// **'Continue with course practice while we complete reviewed content, audio, answer capture, and a transparent scoring process.'**
  String get examPreviewNextStep;

  /// No description provided for @returnToLearning.
  ///
  /// In en, this message translates to:
  /// **'Return to learning'**
  String get returnToLearning;

  /// No description provided for @examPreviewSemantics.
  ///
  /// In en, this message translates to:
  /// **'Exam practice preview. Scored exam practice is not available.'**
  String get examPreviewSemantics;

  /// No description provided for @mockExamPreview.
  ///
  /// In en, this message translates to:
  /// **'Mock exam preview'**
  String get mockExamPreview;

  /// No description provided for @mockExamsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Mock exams are not available yet'**
  String get mockExamsUnavailable;

  /// No description provided for @mockExamPreviewAvailability.
  ///
  /// In en, this message translates to:
  /// **'This preview does not record answers, use a timer, play exam audio, send recordings, submit work, or calculate a score. We will make these capabilities available only after they are complete and clearly explained.'**
  String get mockExamPreviewAvailability;

  /// No description provided for @returnToExamPreview.
  ///
  /// In en, this message translates to:
  /// **'Return to exam preview'**
  String get returnToExamPreview;

  /// No description provided for @mockExamPreviewSemantics.
  ///
  /// In en, this message translates to:
  /// **'Mock exam preview. A scored mock exam is unavailable.'**
  String get mockExamPreviewSemantics;

  /// No description provided for @sessionReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Session report'**
  String get sessionReportTitle;

  /// No description provided for @sessionReportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your session report is temporarily unavailable. Try again later.'**
  String get sessionReportUnavailable;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sessionReportNoDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved corrections yet'**
  String get sessionReportNoDataTitle;

  /// No description provided for @sessionReportNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Sparky has no saved corrections for this language yet.'**
  String get sessionReportNoDataBody;

  /// No description provided for @sessionReportFocusAreas.
  ///
  /// In en, this message translates to:
  /// **'Focus areas'**
  String get sessionReportFocusAreas;

  /// No description provided for @sessionReportCorrections.
  ///
  /// In en, this message translates to:
  /// **'Recent corrections'**
  String get sessionReportCorrections;

  /// No description provided for @addToReview.
  ///
  /// In en, this message translates to:
  /// **'Add to review'**
  String get addToReview;

  /// No description provided for @addedToReview.
  ///
  /// In en, this message translates to:
  /// **'Added to your correction review deck'**
  String get addedToReview;

  /// No description provided for @alreadyInReview.
  ///
  /// In en, this message translates to:
  /// **'Already in your review deck'**
  String get alreadyInReview;

  /// No description provided for @signInToSaveCorrections.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save corrections to your review deck'**
  String get signInToSaveCorrections;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
