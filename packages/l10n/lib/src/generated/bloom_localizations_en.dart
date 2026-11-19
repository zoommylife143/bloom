// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'bloom_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class BloomLocalizationsEn extends BloomLocalizations {
  BloomLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get patientAppTitle => 'Bloom';

  @override
  String get patientBrandName => 'Bloom';

  @override
  String get patientDemoBanner => 'Demo · do not enter real health information';

  @override
  String get patientErrorGeneric =>
      'Something went wrong on our side. Please try again.';

  @override
  String get patientErrorNetwork =>
      'We couldn’t reach Bloom. Check your connection and try again.';

  @override
  String get patientNotFoundHome => 'Go to the start';

  @override
  String get patientSignInTitle => 'Sign in to the demo';

  @override
  String get patientSignInAsPatient => 'Continue as patient';

  @override
  String get patientSignInAsPatientDetail => 'Start the pre-visit intake';

  @override
  String get patientSignInAsClinician => 'Continue as clinician';

  @override
  String get patientSignInAsClinicianDetail => 'Open the doctor dashboard';

  @override
  String get patientSignInSigningIn => 'Signing in…';

  @override
  String get patientSignInFootnote =>
      'Demo login only. This is not production authentication. Synthetic data only.';

  @override
  String get patientSignInExpired =>
      'Your demo sign-in ended. Please sign in again.';

  @override
  String get patientWelcomeTitle => 'Before your gynecology visit';

  @override
  String get patientWelcomeIntro =>
      'Answer a few questions so your doctor can spend your visit on what matters most. It takes about 5 minutes.';

  @override
  String get patientWelcomePrivacyTitle => 'How this conversation is protected';

  @override
  String get patientWelcomePrivacyRoutePrivate =>
      'Your answers are processed on confidential AI infrastructure.';

  @override
  String get patientWelcomePrivacyRouteDev =>
      'Your answers go to an AI service that says it does not keep them (zero data retention, operator-declared).';

  @override
  String get patientWelcomePrivacySearch =>
      'Guideline lookups never include your name or personal details.';

  @override
  String get patientWelcomePrivacyReview =>
      'Your doctor reviews everything. Bloom never diagnoses.';

  @override
  String get patientWelcomeSkipNote =>
      'Some questions are about sexual health. You can skip any of them.';

  @override
  String get patientWelcomeConsent =>
      'I understand this is a demo. I will use made-up answers, not my real health information.';

  @override
  String get patientWelcomeStart => 'Start';

  @override
  String get patientWelcomeStarting => 'Starting…';

  @override
  String patientChatProgress(int current, int total) {
    return 'Question $current of about $total';
  }

  @override
  String patientChatProgressSemantics(int percent) {
    return 'Intake $percent percent done';
  }

  @override
  String get patientChatInputHint => 'Type your answer';

  @override
  String get patientChatInputPaused => 'Paused';

  @override
  String get patientChatSend => 'Send answer';

  @override
  String get patientChatTyping => 'Bloom is writing the next question';

  @override
  String get patientChatSlowReply =>
      'Still working on it. This can take up to a minute.';

  @override
  String get patientChatOptional => 'Optional question';

  @override
  String get patientChatQuickReplies => 'Quick answers';

  @override
  String get patientChatRefusedTitle => 'Paused to protect your privacy';

  @override
  String get patientChatRefusedBody =>
      'We couldn\'t reach a confidential AI route, so we paused instead of using a less private one. Your answers so far are saved.';

  @override
  String get patientChatErrorTitle => 'Something went wrong on our side';

  @override
  String get patientChatErrorBody =>
      'Your answers are saved. Please try again in a moment.';

  @override
  String get patientChatNetworkErrorBody =>
      'We couldn’t reach Bloom. Your answers are saved. Check your connection and try again.';

  @override
  String get patientChatSessionLostTitle => 'This intake can’t continue';

  @override
  String get patientChatSessionLostBody =>
      'Please start again from the beginning.';

  @override
  String get patientChatTryAgain => 'Try again';

  @override
  String get patientChatStartAgain => 'Start again';

  @override
  String get patientChatModePrivate =>
      'Confidential inference · private demo mode';

  @override
  String get patientChatModeDev =>
      'Dev mode · zero-data-retention AI route, not confidential';

  @override
  String get patientUrgentStopped =>
      'Bloom has stopped the questions. Your clinic will see that this intake was paused for urgent care.';

  @override
  String get patientUrgentAcknowledge => 'I understand';

  @override
  String get patientDoneTitle => 'Thank you';

  @override
  String get patientDoneBody =>
      'Your doctor will review your answers before your visit.';

  @override
  String get patientDoneNote =>
      'Bloom doesn\'t give medical advice. If something changes or feels urgent, call 911.';

  @override
  String get clinicAppTitle => 'Bloom Clinic';

  @override
  String get demoBanner => 'Demo only. Do not enter real health information.';

  @override
  String placeholderBody(String screenId) {
    return 'Screen $screenId is not built yet.';
  }

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get screenSignIn => 'Sign in';

  @override
  String get screenWelcome => 'Welcome';

  @override
  String get screenIntakeChat => 'Intake chat';

  @override
  String get screenUrgentCare => 'Urgent care';

  @override
  String get screenDone => 'Done';

  @override
  String get screenQueue => 'Patient queue';

  @override
  String get screenBrief => 'Physician brief';

  @override
  String get screenAudit => 'Audit log';

  @override
  String get screenDemo => 'Demo scenarios';

  @override
  String get screenRedFlag => 'Red-flag summary';

  @override
  String get screenSettings => 'Privacy & data settings';

  @override
  String get screenGallery => 'Component gallery';

  @override
  String get clinicStatusInProgress => 'In progress';

  @override
  String get clinicStatusRedFlag => 'Red flag';

  @override
  String get clinicStatusReady => 'Ready';

  @override
  String get clinicStatusApproved => 'Approved';

  @override
  String get clinicStatusRefused => 'Refused';

  @override
  String get clinicStatusVerified => 'Verified';

  @override
  String get clinicStatusDevMode => 'Dev mode';

  @override
  String get clinicStatusDraft => 'Draft';

  @override
  String get clinicStatusRejected => 'Rejected';

  @override
  String clinicStatusSemantics(String status) {
    return 'Status: $status';
  }

  @override
  String get clinicJustNow => 'just now';

  @override
  String clinicMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String clinicHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String clinicPatientShort(String id) {
    return 'Patient $id';
  }

  @override
  String get clinicRuleR1 => 'Possible ectopic pregnancy pattern';

  @override
  String get clinicRuleR2 => 'Heavy bleeding pattern';

  @override
  String get clinicRuleR3 => 'Possible pelvic infection pattern';

  @override
  String get clinicRuleR4 => 'Pregnancy or postpartum warning pattern';

  @override
  String get clinicRuleR5 => 'Self-harm risk disclosed';

  @override
  String get clinicRuleR6 => 'Sexual assault disclosure';

  @override
  String get clinicErrorNetwork =>
      'Bloom could not reach the server. Check the connection and try again.';

  @override
  String get clinicErrorLocked => 'This item is locked and cannot be changed.';

  @override
  String get clinicErrorNotFound => 'Not found. It may not exist yet.';

  @override
  String get clinicErrorSignedOut =>
      'Your demo sign-in has expired. Sign in again to continue.';

  @override
  String get clinicErrorForbidden =>
      'This demo sign-in cannot open the clinic view. Sign in as a clinician.';

  @override
  String get clinicErrorServer =>
      'The server returned an error. Try again in a moment.';

  @override
  String get clinicRefusedMessage =>
      'Request refused before inference: no route met the confidential privacy floor. No fallback model was called.';

  @override
  String get clinicSignInAgain => 'Sign in again';

  @override
  String get clinicRetry => 'Try again';

  @override
  String get clinicLoading => 'Loading';

  @override
  String get clinicNavQueue => 'Patient queue';

  @override
  String get clinicNavAudit => 'Audit log';

  @override
  String get clinicNavDemo => 'Demo scenarios';

  @override
  String get clinicModePrivateTitle => 'Private demo mode';

  @override
  String get clinicModePrivateNote =>
      'Confidential NYTE route only · fails closed';

  @override
  String get clinicModeDevTitle => 'Dev mode';

  @override
  String get clinicModeDevNote =>
      'GLM route · Zero data retention (operator-declared) · Provider E2EE not verified';

  @override
  String get clinicModeUnknownTitle => 'Mode unknown';

  @override
  String get clinicModeUnknownNote => 'Server mode not reported yet';

  @override
  String get clinicSignInTitle => 'Sign in to the demo';

  @override
  String get clinicDemoBanner => 'Demo · do not enter real health information';

  @override
  String get clinicReviewerLabel => 'Your name on review decisions';

  @override
  String get clinicReviewerHint => 'Dr. Demo';

  @override
  String get clinicRolePatientTitle => 'Continue as patient';

  @override
  String get clinicRolePatientSubtitle => 'Start the pre-visit intake';

  @override
  String get clinicRoleClinicianTitle => 'Continue as clinician';

  @override
  String get clinicRoleClinicianSubtitle => 'Open the doctor dashboard';

  @override
  String get clinicSigningIn => 'Signing in…';

  @override
  String get clinicSignInFooter =>
      'Demo login only. This is not production authentication. Synthetic data only.';

  @override
  String get clinicQueueTitle => 'Pre-visit intakes';

  @override
  String get clinicQueueSubtitle => 'Today · synthetic patients only';

  @override
  String get clinicRefresh => 'Refresh';

  @override
  String get clinicQueueEmptyTitle => 'No intakes yet today';

  @override
  String get clinicQueueEmptyBody =>
      'Start a synthetic scenario from Demo scenarios, or share the intake link with a test patient.';

  @override
  String get clinicColPatient => 'Patient';

  @override
  String get clinicColReason => 'Reason for visit';

  @override
  String get clinicColStatus => 'Status';

  @override
  String get clinicColUpdated => 'Updated';

  @override
  String get clinicColAction => 'Action';

  @override
  String get clinicReasonPending => 'Intake in progress';

  @override
  String get clinicEditedMarker => 'edited';

  @override
  String get clinicViewSummary => 'View summary';

  @override
  String get clinicOpenBrief => 'Open brief';

  @override
  String get clinicNoActionYet => 'No action yet: intake in progress';

  @override
  String get clinicSectionSubjective => 'Subjective';

  @override
  String get clinicSectionObjective => 'Objective';

  @override
  String get clinicSectionAssessment => 'Assessment considerations';

  @override
  String get clinicSectionPlan => 'Plan considerations';

  @override
  String get clinicSectionFlags => 'Flags';

  @override
  String get clinicSectionScreenings => 'Screenings possibly due';

  @override
  String get clinicSectionQuestions => 'Suggested questions';

  @override
  String get clinicSectionDraftMarker => 'Draft, needs your review';

  @override
  String get clinicSectionEmpty => 'Nothing recorded';

  @override
  String clinicEditedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Edited by physician · $count lines changed',
      one: 'Edited by physician · 1 line changed',
    );
    return '$_temp0';
  }

  @override
  String get clinicNoGuidelineCopy =>
      'No guideline retrieved. Guideline search was unavailable, so Bloom made no screening claims. Check screening history manually.';

  @override
  String get clinicGeneratingBanner =>
      'Generating draft · usually under 20 seconds';

  @override
  String get clinicEditingBanner =>
      'Editing the AI draft · saving records your edit and keeps the original draft';

  @override
  String get clinicEditOnePerLine => 'One item per line';

  @override
  String get clinicSaveEdits => 'Save edits';

  @override
  String get clinicCancel => 'Cancel';

  @override
  String clinicBriefTitle(String patient) {
    return '$patient · Pre-visit brief';
  }

  @override
  String get clinicBriefMetaGenerating =>
      'Synthetic patient · drafting the brief';

  @override
  String clinicBriefMeta(String time) {
    return 'Synthetic patient · brief drafted $time';
  }

  @override
  String get clinicBriefMetaPlain => 'Synthetic patient';

  @override
  String get clinicDraftBanner => 'AI draft · needs your review';

  @override
  String clinicApprovedBanner(String reviewer, String time) {
    return 'Approved by $reviewer at $time · final for this visit';
  }

  @override
  String clinicEditedBanner(String reviewer, String time) {
    return 'Edited and approved by $reviewer at $time · original AI draft kept in history';
  }

  @override
  String clinicRejectedBanner(String reviewer, String time) {
    return 'Rejected by $reviewer at $time · this draft is not used for the visit';
  }

  @override
  String get clinicGuidelineUpdatedTitle => 'Guideline updated';

  @override
  String clinicGuidelineUpdatedBody(String host) {
    return 'A cited page on $host changed in the last 7 days. Re-check the guidance before you decide.';
  }

  @override
  String get clinicAlreadyDecided =>
      'This brief already has a decision. Showing the stored decision.';

  @override
  String get clinicRejectTitle => 'Reject this draft?';

  @override
  String get clinicRejectBody =>
      'The draft will not be used for the visit. The original stays in the audit history.';

  @override
  String get clinicRejectConfirm => 'Reject draft';

  @override
  String get clinicDecisionDraftLabel => 'Draft, needs your review';

  @override
  String clinicProvenanceGenerated(String model) {
    return 'Drafted by $model';
  }

  @override
  String clinicProvenanceSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guideline sources',
      one: '1 guideline source',
      zero: 'no guideline sources',
    );
    return '$_temp0';
  }

  @override
  String clinicProvenanceReviewed(String reviewer, String time) {
    return 'reviewed by $reviewer $time';
  }

  @override
  String get clinicProvenanceLabel => 'Provenance';

  @override
  String get clinicTrustTitle => 'Privacy & Trust';

  @override
  String get clinicTrustNote =>
      'Every external call for this session. Fields come from the provider response; nothing is inferred.';

  @override
  String get clinicTrustModeLabel => 'Mode';

  @override
  String get clinicTrustModeDevValue => 'dev';

  @override
  String get clinicTrustDevWarning =>
      'Dev mode: zero data retention (operator-declared), not a confidential route';

  @override
  String get clinicTrustNoCalls => 'No model calls recorded yet.';

  @override
  String get clinicTrustApproval => 'Physician approval';

  @override
  String get clinicTrustTagOk => 'OK';

  @override
  String get clinicTrustTagRefused => 'Refused';

  @override
  String get clinicTrustTagError => 'Error';

  @override
  String get clinicTrustTagDev => 'Dev';

  @override
  String get clinicTrustModePrivate => 'private demo mode';

  @override
  String get clinicTrustModeDev => 'dev mode';

  @override
  String get clinicTrustNoModel => 'none';

  @override
  String get clinicTrustRouteNone => 'Route: none qualified';

  @override
  String clinicTrustRouteZdr(String route) {
    return 'Route: $route · Zero data retention (operator-declared)';
  }

  @override
  String get clinicTrustRouteConfidential => 'Route: confidential';

  @override
  String clinicTrustRouteConfidentialVia(String route) {
    return 'Route: confidential · $route';
  }

  @override
  String clinicTrustRouteOther(String route) {
    return 'Route: $route';
  }

  @override
  String clinicTrustPolicyModel(String policy, String model) {
    return 'Required policy: $policy · model: $model';
  }

  @override
  String get clinicTrustEvidenceNotExposed =>
      'Evidence not exposed by provider';

  @override
  String get clinicTrustEvidenceReceipt =>
      'Evidence: gateway receipt returned (signature not verified by Bloom)';

  @override
  String get clinicTrustRefusedLine =>
      'Request refused · no fallback model called';

  @override
  String get clinicTrustServedWhenShouldRefuse =>
      'Served when it should have been refused';

  @override
  String clinicTrustErrorLine(String error) {
    return 'Call failed: $error';
  }

  @override
  String get clinicTrustUnknownError => 'unknown error';

  @override
  String get clinicTrustDevLine =>
      'Provider E2EE not verified · not confidential · synthetic testing only';

  @override
  String clinicTrustRequestLine(String id, String latency) {
    return 'Request ID $id · $latency';
  }

  @override
  String get clinicTrustNotReturned => 'not returned';

  @override
  String get clinicDeidSearching => 'Context.dev · searching guidelines…';

  @override
  String get clinicDeidSearchingBody =>
      'De-identified queries sent · waiting for passages';

  @override
  String get clinicDeidNone => 'Context.dev · no guideline queries';

  @override
  String get clinicDeidNoneBody => 'No guideline search ran for this session';

  @override
  String clinicDeidFailed(String reason) {
    return 'Context.dev · search failed ($reason)';
  }

  @override
  String get clinicDeidNoResults => 'no results';

  @override
  String get clinicDeidFailedBody =>
      'No passages returned · brief generated without citations';

  @override
  String clinicDeidQueries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Context.dev · $count guideline queries',
      one: 'Context.dev · 1 guideline query',
    );
    return '$_temp0';
  }

  @override
  String clinicDeidQueriesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Built from structured fields only · $count passages returned',
      one: 'Built from structured fields only · 1 passage returned',
    );
    return '$_temp0';
  }

  @override
  String get clinicAttestationTitle => 'Gateway attestation';

  @override
  String get clinicAttestationUnavailable =>
      'Attestation not returned by the gateway';

  @override
  String clinicAttestationIssuer(String value) {
    return 'Issuer: $value';
  }

  @override
  String clinicAttestationAudience(String value) {
    return 'Audience: $value';
  }

  @override
  String clinicAttestationDigest(String value) {
    return 'Image digest: $value';
  }

  @override
  String clinicAttestationCommit(String value) {
    return 'Source commit: $value';
  }

  @override
  String get clinicAttestationSignatureNote =>
      'Claims are decoded only; Bloom does not verify the JWT signature.';

  @override
  String get clinicAttestationClaims => 'Claims';

  @override
  String get clinicAttestationMatch => 'issuer and audience';

  @override
  String get clinicAttestationNoMatch => 'issuer or audience';

  @override
  String get clinicAttestationMatchStatus => 'Claims match';

  @override
  String get clinicAttestationNoMatchStatus => 'Claims do not match';

  @override
  String clinicFlagTitle(String patient) {
    return '$patient · Intake paused for urgent care';
  }

  @override
  String clinicFlagMeta(String time) {
    return 'Synthetic patient · intake stopped $time';
  }

  @override
  String get clinicFlagMetaPlain => 'Synthetic patient · intake stopped';

  @override
  String get clinicFlagBanner =>
      'The patient was shown the urgent-care screen (911 and 988) and the intake was locked.';

  @override
  String get clinicFlagRuleTitle => 'Rule triggered';

  @override
  String clinicFlagRuleLine(String rule, String name) {
    return '$rule · $name (deterministic server rule, not a model judgment)';
  }

  @override
  String clinicFlagMatched(String matched) {
    return 'Matched: $matched';
  }

  @override
  String get clinicFlagMatchedNone => 'Matched: not reported';

  @override
  String get clinicFlagSourceFields => 'Matched on structured intake fields';

  @override
  String get clinicFlagSourceText =>
      'Matched on keywords in the patient\'s message';

  @override
  String get clinicFlagShownTitle => 'What the patient saw';

  @override
  String get clinicFlagShownFallback =>
      'The fixed urgent-care message for this rule.';

  @override
  String get clinicFlagNextTitle => 'What happens next';

  @override
  String get clinicFlagNext1 =>
      'No AI brief was generated for this session. This summary is not a diagnosis.';

  @override
  String get clinicFlagNext2 =>
      'Follow your clinic’s protocol for contacting the patient.';

  @override
  String get clinicBackToQueue => 'Back to queue';

  @override
  String get clinicDemoTitle => 'Demo scenarios';

  @override
  String get clinicDemoSubtitle =>
      'Ten scripted synthetic patients · run through the live server';

  @override
  String get clinicRun => 'Run';

  @override
  String get clinicRunAgain => 'Run again';

  @override
  String clinicRunScenario(String id) {
    return 'Run scenario $id';
  }

  @override
  String get clinicScenarioRunning =>
      'Running · real model calls, up to a minute';

  @override
  String clinicScenarioDoneUrgent(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: 'Red flag after $turns turns',
      one: 'Red flag after 1 turn',
    );
    return '$_temp0';
  }

  @override
  String clinicScenarioDoneReady(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: 'Brief ready after $turns turns',
      one: 'Brief ready after 1 turn',
    );
    return '$_temp0';
  }

  @override
  String clinicScenarioDoneOther(int turns) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: 'Stopped after $turns turns',
      one: 'Stopped after 1 turn',
    );
    return '$_temp0';
  }

  @override
  String get clinicRunNegativeTest => 'Run negative test';

  @override
  String get clinicNegativeTitle =>
      'Negative test: confidential route unavailable';

  @override
  String get clinicNegativeBody =>
      'Forces the gateway to find no qualifying confidential route. Expected: the request is refused, no fallback model is called, and the refusal appears in the Privacy & Trust panel.';

  @override
  String get clinicNegativeRunning =>
      'Asking the gateway for a confidential route…';

  @override
  String get clinicNegativeServed =>
      'Unexpected: the gateway served this request when it should have refused it. Do not use private mode until this is fixed.';

  @override
  String get clinicNegativeUnexpected =>
      'Unexpected result: the request was not refused. Check the row below.';

  @override
  String get clinicAuditTitle => 'Audit log';

  @override
  String get clinicAuditSubtitle =>
      'Newest first · metadata only, no clinical text';

  @override
  String get clinicAuditColTime => 'Time';

  @override
  String get clinicAuditColActor => 'Actor';

  @override
  String get clinicAuditColAction => 'Action';

  @override
  String get clinicAuditColSession => 'Session';

  @override
  String get clinicAuditEmpty => 'No audit events yet.';

  @override
  String get clinicScenarioRunningLong =>
      'Running · up to 12 real model turns, this can take a minute or two';

  @override
  String clinicScenarioRunningElapsed(int seconds) {
    return 'Running · up to 12 real model turns, this can take a minute or two ($seconds s)';
  }

  @override
  String get clinicScenarioTimeout =>
      'Still running after the app stopped waiting. The server may finish the run anyway: check the patient list, or run it again.';

  @override
  String get clinicNegativeProviderError =>
      'Provider error, not a refusal. The test did not reach a routing decision. Run it again.';

  @override
  String clinicNegativeProviderErrorHttp(int status) {
    return 'Provider error (HTTP $status), not a refusal. The test did not reach a routing decision. Run it again.';
  }

  @override
  String get clinicFallbackDraftTitle =>
      'Automatic draft, written without AI. Check every line.';

  @override
  String get clinicFallbackDraftBody =>
      'The model\'s answer was unusable, so Bloom built this draft from the intake answers. No assessment or plan was drafted. Confirm, Edit or Reject it as usual.';

  @override
  String get clinicTrustTagFallback => 'No model';

  @override
  String get clinicTrustNoModelCall => 'Fallback (no model call)';

  @override
  String get clinicTrustRouteNoModelCall => 'Route: none · no model called';

  @override
  String get clinicTrustFallbackIntake =>
      'Intake fallback: fixed question asked, no AI';

  @override
  String get clinicTrustFallbackBrief =>
      'Brief fallback: deterministic draft built from the intake answers, no AI';

  @override
  String clinicTrustFallbackAfter(String error) {
    return 'Used after: $error';
  }
}
