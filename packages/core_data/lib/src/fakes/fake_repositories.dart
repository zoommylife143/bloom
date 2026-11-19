import 'package:core_domain/core_domain.dart';

// In-memory repositories with synthetic data, for UI work before the API
// contract is final and for widget tests. Run an app with
// `--dart-define=BLOOM_FAKE_API=true` to use them. No real patient data.

const _syntheticBrief = Brief(
  subjective:
      'Synthetic patient, age band 30-39, reports pelvic pain for 3 days, '
      'severity 4/10. Not pregnant.',
  objective: 'No vitals captured in pre-visit intake.',
  assessmentConsiderations:
      'Considerations for the physician only; not a diagnosis.',
  planConsiderations: 'Physician to decide after examination.',
  screeningsPossiblyDue: [
    ScreeningLine(
      text: 'Cervical cancer screening may be due (last test 2019).',
      sourceUrl: 'https://www.uspreventiveservicestaskforce.org/',
    ),
    ScreeningLine(text: 'Mammography timing to discuss.'),
  ],
  suggestedQuestions: ['Any change in cycle length?'],
);

const _fallbackDraftPrefix =
    "DRAFT (automatic fallback, written without AI: the model's answer was "
    'unusable).';

/// Shaped like the server's deterministic fallback brief: no assessment or
/// plan drafted, every narrative section starts with the DRAFT marker.
const _syntheticFallbackBrief = Brief(
  subjective:
      '$_fallbackDraftPrefix Synthetic patient, age band 30-39, reason for '
      'visit: annual visit.',
  objective: 'Patient-reported data only; no exam yet.',
  assessmentConsiderations:
      '$_fallbackDraftPrefix No assessment drafted. Physician to review the '
      'intake answers.',
  planConsiderations: '$_fallbackDraftPrefix No plan drafted.',
  flags: ['Not recorded: last_cervical_screening'],
  screeningsPossiblyDue: [
    ScreeningLine(
      text:
          'Retrieved guideline passage for physician review: Cervical cancer '
          'screening',
      sourceUrl: 'https://www.uspreventiveservicestaskforce.org/',
    ),
  ],
);

/// Sessions whose ID contains this marker get the deterministic fallback
/// brief (`source: fallback`) and `*_fallback` trust rows.
const fakeFallbackMarker = 'fallback';

/// Scripted intake: a fixed list of Bloom questions, then done.
class FakeIntakeRepository implements IntakeRepository {
  new({List<String>? questions})
    : _questions =
          questions ??
          const [
            'Hello, I am Bloom. What brings you in today?',
            'How long has this been going on?',
            'Is there any chance you could be pregnant?',
            'Thank you. Your doctor will review this before your visit.',
          ];

  /// Fake-only stand-in for a server red flag: an answer containing this
  /// phrase returns [syntheticUrgent] and locks the session. The real rules
  /// live only in server/app/safety.py. Null disables it.
  String? urgentTrigger = 'dizzy';

  /// Synthetic copy shaped like the server's R1 `UrgentMessage`.
  static const syntheticUrgent = UrgentMessage(
    ruleId: RedFlagRule.r1,
    title: 'Please get care now',
    body:
        'Thank you for telling me. This needs to be checked by a doctor '
        'right away. Call 911 or go to the nearest emergency department now.',
    actions: [
      UrgentAction(label: 'Call 911', tel: 'tel:911'),
      UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
    ],
  );

  final List<String> _questions;
  final Map<String, int> _turns = {};
  var _next = 0;

  @override
  Future<Result<StartedSession>> startSession({String? scenarioId}) async {
    final id = 'fake-${++_next}';
    _turns[id] = 0;
    return Result.ok(
      StartedSession(
        sessionId: id,
        mode: RouteMode.dev,
        reply: _questions.first,
      ),
    );
  }

  @override
  Future<Result<IntakeTurn>> sendMessage({
    required String sessionId,
    required String text,
    String? clientMessageId,
  }) async {
    final key = clientMessageId == null ? null : '$sessionId/$clientMessageId';
    if (_sent[key] case final previous?) return previous; // idempotent resend
    final result = _sendMessage(sessionId, text);
    if (key != null && result is Ok<IntakeTurn>) _sent[key] = result;
    return result;
  }

  final Map<String?, Result<IntakeTurn>> _sent = {};
  final Set<String> _urgentSessions = {};

  Result<IntakeTurn> _sendMessage(String sessionId, String text) {
    final turn = _turns[sessionId];
    if (turn == null) return const Result.err(AppFailure.notFound());
    if (_urgentSessions.contains(sessionId)) {
      return const Result.err(
        AppFailure.locked(
          'session_locked',
          SessionStatus.urgent,
          syntheticUrgent,
        ),
      );
    }
    if (urgentTrigger != null &&
        text.toLowerCase().contains(urgentTrigger!.toLowerCase())) {
      _turns[sessionId] = _questions.length; // locked from now on
      _urgentSessions.add(sessionId);
      return Result.ok(
        IntakeTurn(
          reply: syntheticUrgent.body,
          status: SessionStatus.urgent,
          progress: 1,
          done: true,
          urgent: syntheticUrgent,
        ),
      );
    }
    final last = _questions.length - 1;
    if (turn >= last) {
      return const Result.err(
        AppFailure.locked('session_locked', SessionStatus.ready),
      );
    }
    final next = turn + 1;
    _turns[sessionId] = next;
    return Result.ok(
      IntakeTurn(
        reply: _questions[next],
        status: next == last ? SessionStatus.ready : SessionStatus.inProgress,
        progress: next / last,
        done: next == last,
      ),
    );
  }
}

/// One synthetic draft brief per session (brief ID = `brief-<session>`); a
/// second decision returns locked.
class FakeBriefRepository implements BriefRepository {
  final Map<String, BriefBundle> _decided = {};

  static BriefBundle _draft(String sessionId) => BriefBundle(
    briefId: 'brief-$sessionId',
    sessionId: sessionId,
    brief: sessionId.contains(fakeFallbackMarker)
        ? _syntheticFallbackBrief
        : _syntheticBrief,
    provenance: sessionId.contains(fakeFallbackMarker)
        ? const Provenance(
            generatedBy: 'deterministic-fallback (dev)',
            source: BriefSource.fallback,
          )
        : const Provenance(
            generatedBy: 'fake-model (dev)',
            source: BriefSource.model,
          ),
    evidence: const [
      EvidenceItem(
        url: 'https://www.uspreventiveservicestaskforce.org/',
        title: 'Cervical cancer screening',
      ),
    ],
  );

  /// Sessions whose ID contains this marker have no brief yet (404).
  static const notGeneratedMarker = 'progress';

  @override
  Future<Result<BriefBundle>> getBrief(String sessionId) async {
    if (sessionId.contains(notGeneratedMarker)) {
      return const Result.err(AppFailure.notFound('brief_not_found'));
    }
    return Result.ok(_decided['brief-$sessionId'] ?? _draft(sessionId));
  }

  @override
  Future<Result<BriefBundle>> decide({
    required String briefId,
    required BriefDecision decision,
    required String reviewer,
    Brief? edited,
  }) async {
    if (_decided.containsKey(briefId)) {
      return const Result.err(AppFailure.locked('already_decided'));
    }
    final draft = _draft(briefId.replaceFirst('brief-', ''));
    final isEdit = decision == BriefDecision.edit && edited != null;
    final bundle = draft.copyWith(
      brief: isEdit ? edited : draft.brief,
      originalBrief: draft.brief,
      edited: isEdit,
      provenance: draft.provenance.copyWith(
        reviewStatus: switch (decision) {
          BriefDecision.approve => ReviewStatus.approved,
          BriefDecision.edit => ReviewStatus.edited,
          BriefDecision.reject => ReviewStatus.rejected,
        },
        reviewedBy: reviewer,
        reviewedAt: DateTime.now(),
      ),
    );
    _decided[briefId] = bundle;
    return Result.ok(bundle);
  }
}

/// Synthetic trust rows, including the refused negative test.
class FakeTrustRepository implements TrustRepository {
  @override
  Future<Result<TrustReport>> getTrust(String sessionId) async => Result.ok(
    TrustReport(
      sessionId: sessionId,
      mode: RouteMode.dev,
      events: [
        TrustEvent(
          sessionId: sessionId,
          node: 'intake',
          mode: RouteMode.dev,
          modelId: 'fake-model',
          policyRequired: 'zdr',
          outcome: TrustOutcome.ok,
          requestId: 'req-fake-0001',
          latencyMs: 820,
        ),
        if (sessionId.contains(fakeFallbackMarker))
          TrustEvent(
            sessionId: sessionId,
            node: TrustNodes.intakeFallback,
            mode: RouteMode.dev,
            policyRequired: TrustNodes.noModelCallPolicy,
            outcome: TrustOutcome.ok,
            evidence: const {
              'parse_path': 'fallback',
              'after_error': 'schema_validation_failed',
            },
            latencyMs: 0,
          ),
        TrustEvent(
          sessionId: sessionId,
          node: 'retrieve',
          mode: RouteMode.dev,
          route: 'context.dev',
          policyRequired: 'deidentified_query',
          outcome: TrustOutcome.ok,
          evidence: const {'cache': 'fixture', 'result_count': 1},
          latencyMs: 340,
        ),
        if (sessionId.contains(fakeFallbackMarker))
          TrustEvent(
            sessionId: sessionId,
            node: TrustNodes.briefFallback,
            mode: RouteMode.dev,
            policyRequired: TrustNodes.noModelCallPolicy,
            outcome: TrustOutcome.ok,
            evidence: const {
              'parse_path': 'fallback',
              'after_error': 'json_parse_failed',
            },
            latencyMs: 0,
          )
        else
          TrustEvent(
            sessionId: sessionId,
            node: 'brief',
            mode: RouteMode.dev,
            modelId: 'fake-model',
            route: 'fake-provider',
            policyRequired: 'zdr',
            outcome: TrustOutcome.ok,
            evidence: const {
              'receipt': {
                'signature_verified': false,
                'claims': {'jti': 'rcpt-fake-0002'},
              },
            },
            requestId: 'req-fake-0002',
            latencyMs: 1800,
          ),
      ],
      attestation: const {
        'status': 'unavailable',
        'issuer': null,
        'audience': null,
        'verified_claims': false,
      },
    ),
  );

  @override
  Future<Result<List<AuditRow>>> getAudit() async => const Result.ok([
    AuditRow(action: 'session_created', sessionId: 'fake-1', actor: 'patient'),
  ]);

  @override
  Future<Result<TrustEvent>> runNegativeTest({String? sessionId}) async =>
      Result.ok(
        TrustEvent(
          sessionId: sessionId,
          node: 'negative_test',
          mode: RouteMode.private,
          policyRequired: 'confidential',
          outcome: TrustOutcome.refused,
          evidence: const {
            'http_status': 400,
            'error_code': 'confidential_privacy_required',
          },
          latencyMs: 0,
          createdAt: DateTime.now().toUtc(),
        ),
      );
}

/// Synthetic queue: one ready, one urgent, one in progress.
class FakeSessionRepository implements SessionRepository {
  @override
  Future<Result<void>> login(BloomRole role) async => const Result.ok(null);

  @override
  Future<Result<List<SessionSummary>>> listSessions() async => const Result.ok([
    SessionSummary(
      id: 'fake-urgent',
      status: SessionStatus.urgent,
      redFlag: RedFlagRule.r1,
      scenarioId: 'S6',
      ageBand: '25-29',
      reasonForVisit: 'Pelvic pain',
    ),
    SessionSummary(
      id: 'fake-ready',
      status: SessionStatus.ready,
      scenarioId: 'S1',
      ageBand: '30-39',
      reasonForVisit: 'Annual visit',
      briefId: 'brief-fake-ready',
      reviewStatus: ReviewStatus.draft,
    ),
    SessionSummary(
      id: 'fake-progress',
      status: SessionStatus.inProgress,
      scenarioId: 'S3',
      ageBand: '25-29',
      reasonForVisit: 'Painful periods, contraception question',
    ),
  ]);

  @override
  Future<Result<RedFlagSummary>> getRedFlag(String sessionId) async =>
      Result.ok(
        RedFlagSummary(
          sessionId: sessionId,
          ruleId: RedFlagRule.r1,
          matched: const ['pregnancy_possible', 'severe pain'],
          source: 'fields',
          title: 'Please get care now',
          body:
              'Some of what you told me needs a doctor to check you today. '
              'Please call 911 or go to an emergency department now.',
          createdAt: DateTime.now().toUtc(),
        ),
      );

  @override
  Future<Result<ScenarioRun>> runScenario(String scenarioId) async => Result.ok(
    ScenarioRun(
      sessionId: 'fake-$scenarioId',
      scenarioId: scenarioId,
      status: SessionStatus.ready,
      briefId: 'brief-fake-$scenarioId',
    ),
  );

  @override
  Future<Result<HealthStatus>> health() async =>
      const Result.ok(HealthStatus(ok: true, mode: RouteMode.dev));
}
