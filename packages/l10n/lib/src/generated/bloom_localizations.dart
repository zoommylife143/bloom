import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'bloom_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of BloomLocalizations
/// returned by `BloomLocalizations.of(context)`.
///
/// Applications need to include `BloomLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/bloom_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: BloomLocalizations.localizationsDelegates,
///   supportedLocales: BloomLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the BloomLocalizations.supportedLocales
/// property.
abstract class BloomLocalizations {
  BloomLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static BloomLocalizations of(BuildContext context) {
    return Localizations.of<BloomLocalizations>(context, BloomLocalizations)!;
  }

  static const LocalizationsDelegate<BloomLocalizations> delegate =
      _BloomLocalizationsDelegate();

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

  /// Browser tab title of the patient app.
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get patientAppTitle;

  /// Wordmark next to the sparkle logo (A01, P01, P02).
  ///
  /// In en, this message translates to:
  /// **'Bloom'**
  String get patientBrandName;

  /// Figma Banner Type=Demo on A01 and P01.
  ///
  /// In en, this message translates to:
  /// **'Demo · do not enter real health information'**
  String get patientDemoBanner;

  /// Generic error when no answers are at stake (A01, P01).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get patientErrorGeneric;

  /// No connection or timeout (A01, P01).
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach Bloom. Check your connection and try again.'**
  String get patientErrorNetwork;

  /// Button on the not-found page.
  ///
  /// In en, this message translates to:
  /// **'Go to the start'**
  String get patientNotFoundHome;

  /// A01 title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the demo'**
  String get patientSignInTitle;

  /// A01 patient role tile title.
  ///
  /// In en, this message translates to:
  /// **'Continue as patient'**
  String get patientSignInAsPatient;

  /// A01 patient role tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start the pre-visit intake'**
  String get patientSignInAsPatientDetail;

  /// A01 clinician role tile title; opens the clinic app.
  ///
  /// In en, this message translates to:
  /// **'Continue as clinician'**
  String get patientSignInAsClinician;

  /// A01 clinician role tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the doctor dashboard'**
  String get patientSignInAsClinicianDetail;

  /// A01 patient tile subtitle while signing in.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get patientSignInSigningIn;

  /// A01 footer disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Demo login only. This is not production authentication. Synthetic data only.'**
  String get patientSignInFootnote;

  /// A01 note after the server rejected the token (401).
  ///
  /// In en, this message translates to:
  /// **'Your demo sign-in ended. Please sign in again.'**
  String get patientSignInExpired;

  /// P01 headline.
  ///
  /// In en, this message translates to:
  /// **'Before your gynecology visit'**
  String get patientWelcomeTitle;

  /// P01 intro.
  ///
  /// In en, this message translates to:
  /// **'Answer a few questions so your doctor can spend your visit on what matters most. It takes about 5 minutes.'**
  String get patientWelcomeIntro;

  /// P01 privacy card title.
  ///
  /// In en, this message translates to:
  /// **'How this conversation is protected'**
  String get patientWelcomePrivacyTitle;

  /// P01 privacy point 1 when the server runs in private mode.
  ///
  /// In en, this message translates to:
  /// **'Your answers are processed on confidential AI infrastructure.'**
  String get patientWelcomePrivacyRoutePrivate;

  /// P01 privacy point 1 in dev mode or when the mode is unknown. Literal: ZDR, not confidential.
  ///
  /// In en, this message translates to:
  /// **'Your answers go to an AI service that does not keep them (zero data retention).'**
  String get patientWelcomePrivacyRouteDev;

  /// P01 privacy point 2 (de-identified guideline search).
  ///
  /// In en, this message translates to:
  /// **'Guideline lookups never include your name or personal details.'**
  String get patientWelcomePrivacySearch;

  /// P01 privacy point 3 (physician review).
  ///
  /// In en, this message translates to:
  /// **'Your doctor reviews everything. Bloom never diagnoses.'**
  String get patientWelcomePrivacyReview;

  /// P01 caption under the privacy card.
  ///
  /// In en, this message translates to:
  /// **'Some questions are about sexual health. You can skip any of them.'**
  String get patientWelcomeSkipNote;

  /// P01 consent checkbox; Start stays disabled until it is ticked.
  ///
  /// In en, this message translates to:
  /// **'I understand this is a demo. I will use made-up answers, not my real health information.'**
  String get patientWelcomeConsent;

  /// P01 primary button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get patientWelcomeStart;

  /// P01 button while the session is created (loading 23:33).
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get patientWelcomeStarting;

  /// P02 header progress label.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of about {total}'**
  String patientChatProgress(int current, int total);

  /// Screen-reader value of the P02 progress bar.
  ///
  /// In en, this message translates to:
  /// **'Intake {percent} percent done'**
  String patientChatProgressSemantics(int percent);

  /// P02 composer placeholder.
  ///
  /// In en, this message translates to:
  /// **'Type your answer'**
  String get patientChatInputHint;

  /// P02 composer placeholder while paused (refused, error).
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get patientChatInputPaused;

  /// Screen-reader label of the P02 send button.
  ///
  /// In en, this message translates to:
  /// **'Send answer'**
  String get patientChatSend;

  /// Screen-reader label of the typing indicator (waiting 10:23).
  ///
  /// In en, this message translates to:
  /// **'Bloom is writing the next question'**
  String get patientChatTyping;

  /// P02 note shown when Bloom's reply is taking a long time (slow model call).
  ///
  /// In en, this message translates to:
  /// **'Still working on it. This can take up to a minute.'**
  String get patientChatSlowReply;

  /// Marker above a Bloom question the patient may skip.
  ///
  /// In en, this message translates to:
  /// **'Optional question'**
  String get patientChatOptional;

  /// Screen-reader label of the quick reply chips.
  ///
  /// In en, this message translates to:
  /// **'Quick answers'**
  String get patientChatQuickReplies;

  /// P02 route refused card title (6:87).
  ///
  /// In en, this message translates to:
  /// **'Paused to protect your privacy'**
  String get patientChatRefusedTitle;

  /// P02 route refused card body.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach a confidential AI route, so we paused instead of using a less private one. Your answers so far are saved.'**
  String get patientChatRefusedBody;

  /// P02 model error card title (23:71).
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side'**
  String get patientChatErrorTitle;

  /// P02 model error card body.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved. Please try again in a moment.'**
  String get patientChatErrorBody;

  /// P02 error card body when the server could not be reached.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t reach Bloom. Your answers are saved. Check your connection and try again.'**
  String get patientChatNetworkErrorBody;

  /// P02 error card title when the server no longer knows the session (404).
  ///
  /// In en, this message translates to:
  /// **'This intake can’t continue'**
  String get patientChatSessionLostTitle;

  /// P02 error card body when the session is gone.
  ///
  /// In en, this message translates to:
  /// **'Please start again from the beginning.'**
  String get patientChatSessionLostBody;

  /// P02 refused and error card button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get patientChatTryAgain;

  /// P02 error card button when the session is gone.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get patientChatStartAgain;

  /// P02 trust note in private mode.
  ///
  /// In en, this message translates to:
  /// **'Confidential inference · private demo mode'**
  String get patientChatModePrivate;

  /// P02 trust note in dev mode. Literal: never claim confidential here.
  ///
  /// In en, this message translates to:
  /// **'Dev mode · zero-data-retention AI route, not confidential'**
  String get patientChatModeDev;

  /// P03 caption under the server's urgent message.
  ///
  /// In en, this message translates to:
  /// **'Bloom has stopped the questions. Your clinic will see that this intake was paused for urgent care.'**
  String get patientUrgentStopped;

  /// P03 ghost button; goes to P04.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get patientUrgentAcknowledge;

  /// P04 headline.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get patientDoneTitle;

  /// P04 body.
  ///
  /// In en, this message translates to:
  /// **'Your doctor will review your answers before your visit.'**
  String get patientDoneBody;

  /// P04 caption.
  ///
  /// In en, this message translates to:
  /// **'Bloom doesn\'t give medical advice. If something changes or feels urgent, call 911.'**
  String get patientDoneNote;

  /// Browser tab title of the clinic app.
  ///
  /// In en, this message translates to:
  /// **'Bloom Clinic'**
  String get clinicAppTitle;

  /// Banner on every patient screen.
  ///
  /// In en, this message translates to:
  /// **'Demo only. Do not enter real health information.'**
  String get demoBanner;

  /// Body of a placeholder page.
  ///
  /// In en, this message translates to:
  /// **'Screen {screenId} is not built yet.'**
  String placeholderBody(String screenId);

  /// Title of the router error page.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @screenSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get screenSignIn;

  /// No description provided for @screenWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get screenWelcome;

  /// No description provided for @screenIntakeChat.
  ///
  /// In en, this message translates to:
  /// **'Intake chat'**
  String get screenIntakeChat;

  /// No description provided for @screenUrgentCare.
  ///
  /// In en, this message translates to:
  /// **'Urgent care'**
  String get screenUrgentCare;

  /// No description provided for @screenDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get screenDone;

  /// No description provided for @screenQueue.
  ///
  /// In en, this message translates to:
  /// **'Patient queue'**
  String get screenQueue;

  /// No description provided for @screenBrief.
  ///
  /// In en, this message translates to:
  /// **'Physician brief'**
  String get screenBrief;

  /// No description provided for @screenAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get screenAudit;

  /// No description provided for @screenDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo scenarios'**
  String get screenDemo;

  /// No description provided for @screenRedFlag.
  ///
  /// In en, this message translates to:
  /// **'Red-flag summary'**
  String get screenRedFlag;

  /// No description provided for @screenSettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data settings'**
  String get screenSettings;

  /// No description provided for @screenGallery.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get screenGallery;

  /// No description provided for @clinicStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get clinicStatusInProgress;

  /// No description provided for @clinicStatusRedFlag.
  ///
  /// In en, this message translates to:
  /// **'Red flag'**
  String get clinicStatusRedFlag;

  /// No description provided for @clinicStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get clinicStatusReady;

  /// No description provided for @clinicStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clinicStatusApproved;

  /// No description provided for @clinicStatusRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get clinicStatusRefused;

  /// No description provided for @clinicStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get clinicStatusVerified;

  /// No description provided for @clinicStatusDevMode.
  ///
  /// In en, this message translates to:
  /// **'Dev mode'**
  String get clinicStatusDevMode;

  /// No description provided for @clinicStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get clinicStatusDraft;

  /// No description provided for @clinicStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get clinicStatusRejected;

  /// No description provided for @clinicStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String clinicStatusSemantics(String status);

  /// No description provided for @clinicJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get clinicJustNow;

  /// No description provided for @clinicMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String clinicMinutesAgo(int minutes);

  /// No description provided for @clinicHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String clinicHoursAgo(int hours);

  /// No description provided for @clinicPatientShort.
  ///
  /// In en, this message translates to:
  /// **'Patient {id}'**
  String clinicPatientShort(String id);

  /// No description provided for @clinicRuleR1.
  ///
  /// In en, this message translates to:
  /// **'Possible ectopic pregnancy pattern'**
  String get clinicRuleR1;

  /// No description provided for @clinicRuleR2.
  ///
  /// In en, this message translates to:
  /// **'Heavy bleeding pattern'**
  String get clinicRuleR2;

  /// No description provided for @clinicRuleR3.
  ///
  /// In en, this message translates to:
  /// **'Possible pelvic infection pattern'**
  String get clinicRuleR3;

  /// No description provided for @clinicRuleR4.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy or postpartum warning pattern'**
  String get clinicRuleR4;

  /// No description provided for @clinicRuleR5.
  ///
  /// In en, this message translates to:
  /// **'Self-harm risk disclosed'**
  String get clinicRuleR5;

  /// No description provided for @clinicRuleR6.
  ///
  /// In en, this message translates to:
  /// **'Sexual assault disclosure'**
  String get clinicRuleR6;

  /// No description provided for @clinicErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Bloom could not reach the server. Check the connection and try again.'**
  String get clinicErrorNetwork;

  /// No description provided for @clinicErrorLocked.
  ///
  /// In en, this message translates to:
  /// **'This item is locked and cannot be changed.'**
  String get clinicErrorLocked;

  /// No description provided for @clinicErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found. It may not exist yet.'**
  String get clinicErrorNotFound;

  /// No description provided for @clinicErrorSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Your demo sign-in has expired. Sign in again to continue.'**
  String get clinicErrorSignedOut;

  /// No description provided for @clinicErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This demo sign-in cannot open the clinic view. Sign in as a clinician.'**
  String get clinicErrorForbidden;

  /// No description provided for @clinicErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The server returned an error. Try again in a moment.'**
  String get clinicErrorServer;

  /// No description provided for @clinicRefusedMessage.
  ///
  /// In en, this message translates to:
  /// **'Request refused before inference: no route met the confidential privacy floor. No fallback model was called.'**
  String get clinicRefusedMessage;

  /// No description provided for @clinicSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get clinicSignInAgain;

  /// No description provided for @clinicRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get clinicRetry;

  /// No description provided for @clinicLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get clinicLoading;

  /// No description provided for @clinicNavQueue.
  ///
  /// In en, this message translates to:
  /// **'Patient queue'**
  String get clinicNavQueue;

  /// No description provided for @clinicNavAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get clinicNavAudit;

  /// No description provided for @clinicNavDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo scenarios'**
  String get clinicNavDemo;

  /// No description provided for @clinicModePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Private demo mode'**
  String get clinicModePrivateTitle;

  /// No description provided for @clinicModePrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Confidential NYTE route only · fails closed'**
  String get clinicModePrivateNote;

  /// No description provided for @clinicModeDevTitle.
  ///
  /// In en, this message translates to:
  /// **'Dev mode'**
  String get clinicModeDevTitle;

  /// No description provided for @clinicModeDevNote.
  ///
  /// In en, this message translates to:
  /// **'GLM route · Zero data retention (operator-declared) · Provider E2EE not verified'**
  String get clinicModeDevNote;

  /// No description provided for @clinicModeUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Mode unknown'**
  String get clinicModeUnknownTitle;

  /// No description provided for @clinicModeUnknownNote.
  ///
  /// In en, this message translates to:
  /// **'Server mode not reported yet'**
  String get clinicModeUnknownNote;

  /// No description provided for @clinicSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to the demo'**
  String get clinicSignInTitle;

  /// No description provided for @clinicDemoBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo · do not enter real health information'**
  String get clinicDemoBanner;

  /// No description provided for @clinicReviewerLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name on review decisions'**
  String get clinicReviewerLabel;

  /// No description provided for @clinicReviewerHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Demo'**
  String get clinicReviewerHint;

  /// No description provided for @clinicRolePatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue as patient'**
  String get clinicRolePatientTitle;

  /// No description provided for @clinicRolePatientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start the pre-visit intake'**
  String get clinicRolePatientSubtitle;

  /// No description provided for @clinicRoleClinicianTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue as clinician'**
  String get clinicRoleClinicianTitle;

  /// No description provided for @clinicRoleClinicianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the doctor dashboard'**
  String get clinicRoleClinicianSubtitle;

  /// No description provided for @clinicSigningIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get clinicSigningIn;

  /// No description provided for @clinicSignInFooter.
  ///
  /// In en, this message translates to:
  /// **'Demo login only. This is not production authentication. Synthetic data only.'**
  String get clinicSignInFooter;

  /// No description provided for @clinicQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-visit intakes'**
  String get clinicQueueTitle;

  /// No description provided for @clinicQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today · synthetic patients only'**
  String get clinicQueueSubtitle;

  /// No description provided for @clinicRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get clinicRefresh;

  /// No description provided for @clinicQueueEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No intakes yet today'**
  String get clinicQueueEmptyTitle;

  /// No description provided for @clinicQueueEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start a synthetic scenario from Demo scenarios, or share the intake link with a test patient.'**
  String get clinicQueueEmptyBody;

  /// No description provided for @clinicColPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get clinicColPatient;

  /// No description provided for @clinicColReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for visit'**
  String get clinicColReason;

  /// No description provided for @clinicColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get clinicColStatus;

  /// No description provided for @clinicColUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get clinicColUpdated;

  /// No description provided for @clinicColAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get clinicColAction;

  /// No description provided for @clinicReasonPending.
  ///
  /// In en, this message translates to:
  /// **'Intake in progress'**
  String get clinicReasonPending;

  /// No description provided for @clinicEditedMarker.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get clinicEditedMarker;

  /// No description provided for @clinicViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View summary'**
  String get clinicViewSummary;

  /// No description provided for @clinicOpenBrief.
  ///
  /// In en, this message translates to:
  /// **'Open brief'**
  String get clinicOpenBrief;

  /// No description provided for @clinicNoActionYet.
  ///
  /// In en, this message translates to:
  /// **'No action yet: intake in progress'**
  String get clinicNoActionYet;

  /// No description provided for @clinicSectionSubjective.
  ///
  /// In en, this message translates to:
  /// **'Subjective'**
  String get clinicSectionSubjective;

  /// No description provided for @clinicSectionObjective.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get clinicSectionObjective;

  /// No description provided for @clinicSectionAssessment.
  ///
  /// In en, this message translates to:
  /// **'Assessment considerations'**
  String get clinicSectionAssessment;

  /// No description provided for @clinicSectionPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan considerations'**
  String get clinicSectionPlan;

  /// No description provided for @clinicSectionFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get clinicSectionFlags;

  /// No description provided for @clinicSectionScreenings.
  ///
  /// In en, this message translates to:
  /// **'Screenings possibly due'**
  String get clinicSectionScreenings;

  /// No description provided for @clinicSectionQuestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested questions'**
  String get clinicSectionQuestions;

  /// No description provided for @clinicSectionDraftMarker.
  ///
  /// In en, this message translates to:
  /// **'Draft, needs your review'**
  String get clinicSectionDraftMarker;

  /// No description provided for @clinicSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded'**
  String get clinicSectionEmpty;

  /// No description provided for @clinicEditedLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Edited by physician · 1 line changed} other{Edited by physician · {count} lines changed}}'**
  String clinicEditedLines(int count);

  /// No description provided for @clinicNoGuidelineCopy.
  ///
  /// In en, this message translates to:
  /// **'No guideline retrieved. Guideline search was unavailable, so Bloom made no screening claims. Check screening history manually.'**
  String get clinicNoGuidelineCopy;

  /// No description provided for @clinicGeneratingBanner.
  ///
  /// In en, this message translates to:
  /// **'Generating draft · usually under 20 seconds'**
  String get clinicGeneratingBanner;

  /// No description provided for @clinicEditingBanner.
  ///
  /// In en, this message translates to:
  /// **'Editing the AI draft · saving records your edit and keeps the original draft'**
  String get clinicEditingBanner;

  /// No description provided for @clinicEditOnePerLine.
  ///
  /// In en, this message translates to:
  /// **'One item per line'**
  String get clinicEditOnePerLine;

  /// No description provided for @clinicSaveEdits.
  ///
  /// In en, this message translates to:
  /// **'Save edits'**
  String get clinicSaveEdits;

  /// No description provided for @clinicCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get clinicCancel;

  /// No description provided for @clinicBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'{patient} · Pre-visit brief'**
  String clinicBriefTitle(String patient);

  /// No description provided for @clinicBriefMetaGenerating.
  ///
  /// In en, this message translates to:
  /// **'Synthetic patient · drafting the brief'**
  String get clinicBriefMetaGenerating;

  /// No description provided for @clinicBriefMeta.
  ///
  /// In en, this message translates to:
  /// **'Synthetic patient · brief drafted {time}'**
  String clinicBriefMeta(String time);

  /// No description provided for @clinicBriefMetaPlain.
  ///
  /// In en, this message translates to:
  /// **'Synthetic patient'**
  String get clinicBriefMetaPlain;

  /// No description provided for @clinicDraftBanner.
  ///
  /// In en, this message translates to:
  /// **'AI draft · needs your review'**
  String get clinicDraftBanner;

  /// No description provided for @clinicApprovedBanner.
  ///
  /// In en, this message translates to:
  /// **'Approved by {reviewer} at {time} · final for this visit'**
  String clinicApprovedBanner(String reviewer, String time);

  /// No description provided for @clinicEditedBanner.
  ///
  /// In en, this message translates to:
  /// **'Edited and approved by {reviewer} at {time} · original AI draft kept in history'**
  String clinicEditedBanner(String reviewer, String time);

  /// No description provided for @clinicRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Rejected by {reviewer} at {time} · this draft is not used for the visit'**
  String clinicRejectedBanner(String reviewer, String time);

  /// No description provided for @clinicGuidelineUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Guideline updated'**
  String get clinicGuidelineUpdatedTitle;

  /// No description provided for @clinicGuidelineUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'A cited page on {host} changed in the last 7 days. Re-check the guidance before you decide.'**
  String clinicGuidelineUpdatedBody(String host);

  /// No description provided for @clinicAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'This brief already has a decision. Showing the stored decision.'**
  String get clinicAlreadyDecided;

  /// No description provided for @clinicRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this draft?'**
  String get clinicRejectTitle;

  /// No description provided for @clinicRejectBody.
  ///
  /// In en, this message translates to:
  /// **'The draft will not be used for the visit. The original stays in the audit history.'**
  String get clinicRejectBody;

  /// No description provided for @clinicRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject draft'**
  String get clinicRejectConfirm;

  /// No description provided for @clinicDecisionDraftLabel.
  ///
  /// In en, this message translates to:
  /// **'Draft, needs your review'**
  String get clinicDecisionDraftLabel;

  /// No description provided for @clinicProvenanceGenerated.
  ///
  /// In en, this message translates to:
  /// **'Drafted by {model}'**
  String clinicProvenanceGenerated(String model);

  /// No description provided for @clinicProvenanceSources.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no guideline sources} =1{1 guideline source} other{{count} guideline sources}}'**
  String clinicProvenanceSources(int count);

  /// No description provided for @clinicProvenanceReviewed.
  ///
  /// In en, this message translates to:
  /// **'reviewed by {reviewer} {time}'**
  String clinicProvenanceReviewed(String reviewer, String time);

  /// No description provided for @clinicProvenanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Provenance'**
  String get clinicProvenanceLabel;

  /// No description provided for @clinicTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Trust'**
  String get clinicTrustTitle;

  /// No description provided for @clinicTrustNote.
  ///
  /// In en, this message translates to:
  /// **'Every external call for this session. Fields come from the provider response; nothing is inferred.'**
  String get clinicTrustNote;

  /// No description provided for @clinicTrustModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get clinicTrustModeLabel;

  /// No description provided for @clinicTrustModeDevValue.
  ///
  /// In en, this message translates to:
  /// **'dev'**
  String get clinicTrustModeDevValue;

  /// No description provided for @clinicTrustDevWarning.
  ///
  /// In en, this message translates to:
  /// **'Dev mode: zero data retention (operator-declared), not a confidential route'**
  String get clinicTrustDevWarning;

  /// No description provided for @clinicTrustNoCalls.
  ///
  /// In en, this message translates to:
  /// **'No model calls recorded yet.'**
  String get clinicTrustNoCalls;

  /// No description provided for @clinicTrustApproval.
  ///
  /// In en, this message translates to:
  /// **'Physician approval'**
  String get clinicTrustApproval;

  /// No description provided for @clinicTrustTagOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get clinicTrustTagOk;

  /// No description provided for @clinicTrustTagRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get clinicTrustTagRefused;

  /// No description provided for @clinicTrustTagError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get clinicTrustTagError;

  /// No description provided for @clinicTrustTagDev.
  ///
  /// In en, this message translates to:
  /// **'Dev'**
  String get clinicTrustTagDev;

  /// No description provided for @clinicTrustModePrivate.
  ///
  /// In en, this message translates to:
  /// **'private demo mode'**
  String get clinicTrustModePrivate;

  /// No description provided for @clinicTrustModeDev.
  ///
  /// In en, this message translates to:
  /// **'dev mode'**
  String get clinicTrustModeDev;

  /// No description provided for @clinicTrustNoModel.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get clinicTrustNoModel;

  /// No description provided for @clinicTrustRouteNone.
  ///
  /// In en, this message translates to:
  /// **'Route: none qualified'**
  String get clinicTrustRouteNone;

  /// No description provided for @clinicTrustRouteZdr.
  ///
  /// In en, this message translates to:
  /// **'Route: {route} · Zero data retention (operator-declared)'**
  String clinicTrustRouteZdr(String route);

  /// No description provided for @clinicTrustRouteConfidential.
  ///
  /// In en, this message translates to:
  /// **'Route: confidential'**
  String get clinicTrustRouteConfidential;

  /// No description provided for @clinicTrustRouteConfidentialVia.
  ///
  /// In en, this message translates to:
  /// **'Route: confidential · {route}'**
  String clinicTrustRouteConfidentialVia(String route);

  /// No description provided for @clinicTrustRouteOther.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String clinicTrustRouteOther(String route);

  /// No description provided for @clinicTrustPolicyModel.
  ///
  /// In en, this message translates to:
  /// **'Required policy: {policy} · model: {model}'**
  String clinicTrustPolicyModel(String policy, String model);

  /// No description provided for @clinicTrustEvidenceNotExposed.
  ///
  /// In en, this message translates to:
  /// **'Evidence not exposed by provider'**
  String get clinicTrustEvidenceNotExposed;

  /// No description provided for @clinicTrustEvidenceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Evidence: gateway receipt returned (signature not verified by Bloom)'**
  String get clinicTrustEvidenceReceipt;

  /// No description provided for @clinicTrustRefusedLine.
  ///
  /// In en, this message translates to:
  /// **'Request refused · no fallback model called'**
  String get clinicTrustRefusedLine;

  /// No description provided for @clinicTrustServedWhenShouldRefuse.
  ///
  /// In en, this message translates to:
  /// **'Served when it should have been refused'**
  String get clinicTrustServedWhenShouldRefuse;

  /// No description provided for @clinicTrustErrorLine.
  ///
  /// In en, this message translates to:
  /// **'Call failed: {error}'**
  String clinicTrustErrorLine(String error);

  /// No description provided for @clinicTrustUnknownError.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get clinicTrustUnknownError;

  /// No description provided for @clinicTrustDevLine.
  ///
  /// In en, this message translates to:
  /// **'Provider E2EE not verified · not confidential · synthetic testing only'**
  String get clinicTrustDevLine;

  /// No description provided for @clinicTrustRequestLine.
  ///
  /// In en, this message translates to:
  /// **'Request ID {id} · {latency}'**
  String clinicTrustRequestLine(String id, String latency);

  /// No description provided for @clinicTrustNotReturned.
  ///
  /// In en, this message translates to:
  /// **'not returned'**
  String get clinicTrustNotReturned;

  /// No description provided for @clinicDeidSearching.
  ///
  /// In en, this message translates to:
  /// **'Context.dev · searching guidelines…'**
  String get clinicDeidSearching;

  /// No description provided for @clinicDeidSearchingBody.
  ///
  /// In en, this message translates to:
  /// **'De-identified queries sent · waiting for passages'**
  String get clinicDeidSearchingBody;

  /// No description provided for @clinicDeidNone.
  ///
  /// In en, this message translates to:
  /// **'Context.dev · no guideline queries'**
  String get clinicDeidNone;

  /// No description provided for @clinicDeidNoneBody.
  ///
  /// In en, this message translates to:
  /// **'No guideline search ran for this session'**
  String get clinicDeidNoneBody;

  /// No description provided for @clinicDeidFailed.
  ///
  /// In en, this message translates to:
  /// **'Context.dev · search failed ({reason})'**
  String clinicDeidFailed(String reason);

  /// No description provided for @clinicDeidNoResults.
  ///
  /// In en, this message translates to:
  /// **'no results'**
  String get clinicDeidNoResults;

  /// No description provided for @clinicDeidFailedBody.
  ///
  /// In en, this message translates to:
  /// **'No passages returned · brief generated without citations'**
  String get clinicDeidFailedBody;

  /// No description provided for @clinicDeidQueries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Context.dev · 1 guideline query} other{Context.dev · {count} guideline queries}}'**
  String clinicDeidQueries(int count);

  /// No description provided for @clinicDeidQueriesBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Built from structured fields only · 1 passage returned} other{Built from structured fields only · {count} passages returned}}'**
  String clinicDeidQueriesBody(int count);

  /// No description provided for @clinicAttestationTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway attestation'**
  String get clinicAttestationTitle;

  /// No description provided for @clinicAttestationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Attestation not returned by the gateway'**
  String get clinicAttestationUnavailable;

  /// No description provided for @clinicAttestationIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer: {value}'**
  String clinicAttestationIssuer(String value);

  /// No description provided for @clinicAttestationAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience: {value}'**
  String clinicAttestationAudience(String value);

  /// No description provided for @clinicAttestationDigest.
  ///
  /// In en, this message translates to:
  /// **'Image digest: {value}'**
  String clinicAttestationDigest(String value);

  /// No description provided for @clinicAttestationCommit.
  ///
  /// In en, this message translates to:
  /// **'Source commit: {value}'**
  String clinicAttestationCommit(String value);

  /// No description provided for @clinicAttestationSignatureNote.
  ///
  /// In en, this message translates to:
  /// **'Claims are decoded only; Bloom does not verify the JWT signature.'**
  String get clinicAttestationSignatureNote;

  /// No description provided for @clinicAttestationClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get clinicAttestationClaims;

  /// No description provided for @clinicAttestationMatch.
  ///
  /// In en, this message translates to:
  /// **'issuer and audience'**
  String get clinicAttestationMatch;

  /// No description provided for @clinicAttestationNoMatch.
  ///
  /// In en, this message translates to:
  /// **'issuer or audience'**
  String get clinicAttestationNoMatch;

  /// No description provided for @clinicAttestationMatchStatus.
  ///
  /// In en, this message translates to:
  /// **'Claims match'**
  String get clinicAttestationMatchStatus;

  /// No description provided for @clinicAttestationNoMatchStatus.
  ///
  /// In en, this message translates to:
  /// **'Claims do not match'**
  String get clinicAttestationNoMatchStatus;

  /// No description provided for @clinicFlagTitle.
  ///
  /// In en, this message translates to:
  /// **'{patient} · Intake paused for urgent care'**
  String clinicFlagTitle(String patient);

  /// No description provided for @clinicFlagMeta.
  ///
  /// In en, this message translates to:
  /// **'Synthetic patient · intake stopped {time}'**
  String clinicFlagMeta(String time);

  /// No description provided for @clinicFlagMetaPlain.
  ///
  /// In en, this message translates to:
  /// **'Synthetic patient · intake stopped'**
  String get clinicFlagMetaPlain;

  /// No description provided for @clinicFlagBanner.
  ///
  /// In en, this message translates to:
  /// **'The patient was shown the urgent-care screen (911 and 988) and the intake was locked.'**
  String get clinicFlagBanner;

  /// No description provided for @clinicFlagRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule triggered'**
  String get clinicFlagRuleTitle;

  /// No description provided for @clinicFlagRuleLine.
  ///
  /// In en, this message translates to:
  /// **'{rule} · {name} (deterministic server rule, not a model judgment)'**
  String clinicFlagRuleLine(String rule, String name);

  /// No description provided for @clinicFlagMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched: {matched}'**
  String clinicFlagMatched(String matched);

  /// No description provided for @clinicFlagMatchedNone.
  ///
  /// In en, this message translates to:
  /// **'Matched: not reported'**
  String get clinicFlagMatchedNone;

  /// No description provided for @clinicFlagSourceFields.
  ///
  /// In en, this message translates to:
  /// **'Matched on structured intake fields'**
  String get clinicFlagSourceFields;

  /// No description provided for @clinicFlagSourceText.
  ///
  /// In en, this message translates to:
  /// **'Matched on keywords in the patient\'s message'**
  String get clinicFlagSourceText;

  /// No description provided for @clinicFlagShownTitle.
  ///
  /// In en, this message translates to:
  /// **'What the patient saw'**
  String get clinicFlagShownTitle;

  /// No description provided for @clinicFlagShownFallback.
  ///
  /// In en, this message translates to:
  /// **'The fixed urgent-care message for this rule.'**
  String get clinicFlagShownFallback;

  /// No description provided for @clinicFlagNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get clinicFlagNextTitle;

  /// No description provided for @clinicFlagNext1.
  ///
  /// In en, this message translates to:
  /// **'No AI brief was generated for this session. This summary is not a diagnosis.'**
  String get clinicFlagNext1;

  /// No description provided for @clinicFlagNext2.
  ///
  /// In en, this message translates to:
  /// **'Follow your clinic’s protocol for contacting the patient.'**
  String get clinicFlagNext2;

  /// No description provided for @clinicBackToQueue.
  ///
  /// In en, this message translates to:
  /// **'Back to queue'**
  String get clinicBackToQueue;

  /// No description provided for @clinicDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo scenarios'**
  String get clinicDemoTitle;

  /// No description provided for @clinicDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ten scripted synthetic patients · run through the live server'**
  String get clinicDemoSubtitle;

  /// No description provided for @clinicRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get clinicRun;

  /// No description provided for @clinicRunAgain.
  ///
  /// In en, this message translates to:
  /// **'Run again'**
  String get clinicRunAgain;

  /// No description provided for @clinicRunScenario.
  ///
  /// In en, this message translates to:
  /// **'Run scenario {id}'**
  String clinicRunScenario(String id);

  /// No description provided for @clinicScenarioRunning.
  ///
  /// In en, this message translates to:
  /// **'Running · real model calls, up to a minute'**
  String get clinicScenarioRunning;

  /// No description provided for @clinicScenarioDoneUrgent.
  ///
  /// In en, this message translates to:
  /// **'{turns, plural, =1{Red flag after 1 turn} other{Red flag after {turns} turns}}'**
  String clinicScenarioDoneUrgent(int turns);

  /// No description provided for @clinicScenarioDoneReady.
  ///
  /// In en, this message translates to:
  /// **'{turns, plural, =1{Brief ready after 1 turn} other{Brief ready after {turns} turns}}'**
  String clinicScenarioDoneReady(int turns);

  /// No description provided for @clinicScenarioDoneOther.
  ///
  /// In en, this message translates to:
  /// **'{turns, plural, =1{Stopped after 1 turn} other{Stopped after {turns} turns}}'**
  String clinicScenarioDoneOther(int turns);

  /// No description provided for @clinicRunNegativeTest.
  ///
  /// In en, this message translates to:
  /// **'Run negative test'**
  String get clinicRunNegativeTest;

  /// No description provided for @clinicNegativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Negative test: confidential route unavailable'**
  String get clinicNegativeTitle;

  /// No description provided for @clinicNegativeBody.
  ///
  /// In en, this message translates to:
  /// **'Forces the gateway to find no qualifying confidential route. Expected: the request is refused, no fallback model is called, and the refusal appears in the Privacy & Trust panel.'**
  String get clinicNegativeBody;

  /// No description provided for @clinicNegativeRunning.
  ///
  /// In en, this message translates to:
  /// **'Asking the gateway for a confidential route…'**
  String get clinicNegativeRunning;

  /// No description provided for @clinicNegativeServed.
  ///
  /// In en, this message translates to:
  /// **'Unexpected: the gateway served this request when it should have refused it. Do not use private mode until this is fixed.'**
  String get clinicNegativeServed;

  /// No description provided for @clinicNegativeUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected result: the request was not refused. Check the row below.'**
  String get clinicNegativeUnexpected;

  /// No description provided for @clinicAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get clinicAuditTitle;

  /// No description provided for @clinicAuditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Newest first · metadata only, no clinical text'**
  String get clinicAuditSubtitle;

  /// No description provided for @clinicAuditColTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get clinicAuditColTime;

  /// No description provided for @clinicAuditColActor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get clinicAuditColActor;

  /// No description provided for @clinicAuditColAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get clinicAuditColAction;

  /// No description provided for @clinicAuditColSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get clinicAuditColSession;

  /// No description provided for @clinicAuditEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audit events yet.'**
  String get clinicAuditEmpty;

  /// No description provided for @clinicScenarioRunningLong.
  ///
  /// In en, this message translates to:
  /// **'Running · up to 12 real model turns, this can take a minute or two'**
  String get clinicScenarioRunningLong;

  /// No description provided for @clinicScenarioRunningElapsed.
  ///
  /// In en, this message translates to:
  /// **'Running · up to 12 real model turns, this can take a minute or two ({seconds} s)'**
  String clinicScenarioRunningElapsed(int seconds);

  /// No description provided for @clinicScenarioTimeout.
  ///
  /// In en, this message translates to:
  /// **'Still running after the app stopped waiting. The server may finish the run anyway: check the patient list, or run it again.'**
  String get clinicScenarioTimeout;

  /// No description provided for @clinicNegativeProviderError.
  ///
  /// In en, this message translates to:
  /// **'Provider error, not a refusal. The test did not reach a routing decision. Run it again.'**
  String get clinicNegativeProviderError;

  /// No description provided for @clinicNegativeProviderErrorHttp.
  ///
  /// In en, this message translates to:
  /// **'Provider error (HTTP {status}), not a refusal. The test did not reach a routing decision. Run it again.'**
  String clinicNegativeProviderErrorHttp(int status);

  /// No description provided for @clinicFallbackDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic draft, written without AI. Check every line.'**
  String get clinicFallbackDraftTitle;

  /// No description provided for @clinicFallbackDraftBody.
  ///
  /// In en, this message translates to:
  /// **'The model\'s answer was unusable, so Bloom built this draft from the intake answers. No assessment or plan was drafted. Confirm, Edit or Reject it as usual.'**
  String get clinicFallbackDraftBody;

  /// No description provided for @clinicTrustTagFallback.
  ///
  /// In en, this message translates to:
  /// **'No model'**
  String get clinicTrustTagFallback;

  /// No description provided for @clinicTrustNoModelCall.
  ///
  /// In en, this message translates to:
  /// **'Fallback (no model call)'**
  String get clinicTrustNoModelCall;

  /// No description provided for @clinicTrustRouteNoModelCall.
  ///
  /// In en, this message translates to:
  /// **'Route: none · no model called'**
  String get clinicTrustRouteNoModelCall;

  /// No description provided for @clinicTrustFallbackIntake.
  ///
  /// In en, this message translates to:
  /// **'Intake fallback: fixed question asked, no AI'**
  String get clinicTrustFallbackIntake;

  /// No description provided for @clinicTrustFallbackBrief.
  ///
  /// In en, this message translates to:
  /// **'Brief fallback: deterministic draft built from the intake answers, no AI'**
  String get clinicTrustFallbackBrief;

  /// No description provided for @clinicTrustFallbackAfter.
  ///
  /// In en, this message translates to:
  /// **'Used after: {error}'**
  String clinicTrustFallbackAfter(String error);
}

class _BloomLocalizationsDelegate
    extends LocalizationsDelegate<BloomLocalizations> {
  const _BloomLocalizationsDelegate();

  @override
  Future<BloomLocalizations> load(Locale locale) {
    return SynchronousFuture<BloomLocalizations>(
      lookupBloomLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_BloomLocalizationsDelegate old) => false;
}

BloomLocalizations lookupBloomLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return BloomLocalizationsEn();
  }

  throw FlutterError(
    'BloomLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
