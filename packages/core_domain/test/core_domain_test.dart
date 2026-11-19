import 'package:core_domain/core_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('ok exposes the value', () {
      const result = Result<int>.ok(2);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 2);
      expect(result.map((v) => v * 2), const Result<int>.ok(4));
    });

    test('err exposes the failure', () {
      const result = Result<int>.err(AppFailure.locked());
      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<LockedFailure>());
      expect(result.fold((_) => 'ok', (f) => 'err'), 'err');
    });
  });

  group('JSON', () {
    test('IntakeTurn parses snake_case with an urgent message', () {
      final turn = IntakeTurn.fromJson(const {
        'reply': 'Please get care now',
        'status': 'urgent',
        'progress': 1.0,
        'done': true,
        'urgent': {
          'title': 'Please get care now',
          'body': 'Synthetic body',
          'actions': [
            {'label': 'Call 911', 'tel': 'tel:911'},
          ],
          'rule_id': 'R1',
          'support': null,
        },
      });
      expect(turn.status, SessionStatus.urgent);
      expect(turn.done, isTrue);
      expect(turn.urgent?.ruleId, RedFlagRule.r1);
      expect(turn.urgent?.actions.single.tel, 'tel:911');
    });

    test('SessionSummary accepts id or session_id', () {
      final a = SessionSummary.fromJson(const {
        'id': 's1',
        'status': 'in_progress',
      });
      // Shape from docs/api-contract.md (GET /api/sessions).
      final b = SessionSummary.fromJson(const {
        'session_id': 's2',
        'scenario_id': null,
        'mode': 'dev',
        'status': 'ready',
        'created_at': '2026-11-19T08:19:15.726007Z',
        'updated_at': '2026-11-19T08:19:15.828223Z',
        'red_flag_rule': 'R2',
        'brief_id': 'b2',
        'review_status': 'draft',
        'age_band': '30-39',
        'reason_for_visit': 'routine gynecology visit',
      });
      expect(a.id, 's1');
      expect(a.status, SessionStatus.inProgress);
      expect(b.id, 's2');
      expect(b.redFlag, RedFlagRule.r2);
      expect(b.briefId, 'b2');
      expect(b.reviewStatus, ReviewStatus.draft);
      expect(b.createdAt?.isUtc, isTrue);
    });

    test('BriefBundle round-trips', () {
      const bundle = BriefBundle(
        briefId: 'b1',
        sessionId: 's1',
        brief: Brief(
          subjective: 'Synthetic S',
          objective: 'Synthetic O',
          assessmentConsiderations: 'Synthetic A',
          planConsiderations: 'Synthetic P',
          screeningsPossiblyDue: [ScreeningLine(text: 'Cervical screening')],
        ),
        provenance: Provenance(generatedBy: 'test-model (dev)'),
      );
      final json = bundle.toJson();
      expect(
        (json['brief'] as Map<String, dynamic>)['assessment_considerations'],
        'Synthetic A',
      );
      expect(BriefBundle.fromJson(json), bundle);
      expect(bundle.provenance.reviewStatus, ReviewStatus.draft);
    });

    test('ScenarioRun and RedFlagSummary parse the contract shapes', () {
      final run = ScenarioRun.fromJson(const {
        'session_id': 's8',
        'scenario_id': 'S8',
        'status': 'urgent',
        'turns_run': 3,
        'brief_id': null,
      });
      final flag = RedFlagSummary.fromJson(const {
        'session_id': 's8',
        'rule_id': 'R3',
        'matched': ['fever', 'pelvic pain'],
        'source': 'text',
        'title': 'Please get care today',
        'body': 'Synthetic body',
      });
      expect(run.turnsRun, 3);
      expect(run.status, SessionStatus.urgent);
      expect(flag.ruleId, RedFlagRule.r3);
      expect(flag.matched, ['fever', 'pelvic pain']);
    });

    test('BriefBundle guideline_updates is optional', () {
      const base = {
        'brief_id': 'b1',
        'session_id': 's1',
        'brief': {
          'subjective': 's',
          'objective': 'o',
          'assessment_considerations': 'a',
          'plan_considerations': 'p',
        },
        'provenance': {'generated_by': 'model (dev)'},
      };
      expect(BriefBundle.fromJson(base).guidelineUpdates, isEmpty);
      final updated = BriefBundle.fromJson({
        ...base,
        'guideline_updates': ['https://example.org/guide'],
      });
      expect(updated.guidelineUpdates, ['https://example.org/guide']);
    });

    test('TrustEvent parses a refused row', () {
      final event = TrustEvent.fromJson(const {
        'node': 'negative_test',
        'mode': 'private',
        'policy_required': 'confidential',
        'outcome': 'refused',
      });
      expect(event.outcome, TrustOutcome.refused);
      expect(event.mode, RouteMode.private);
    });

    group('fallback fields (2026-11-19)', () {
      const briefBase = {
        'brief_id': 'b1',
        'session_id': 's1',
        'brief': {
          'subjective': 'DRAFT (automatic fallback, written without AI)',
          'objective': 'o',
          'assessment_considerations': 'a',
          'plan_considerations': 'p',
        },
      };

      test('Provenance.source parses model and fallback', () {
        final fallback = BriefBundle.fromJson({
          ...briefBase,
          'provenance': {
            'generated_by': 'deterministic-fallback (dev)',
            'source': 'fallback',
          },
        });
        expect(fallback.provenance.source, BriefSource.fallback);
        expect(fallback.provenance.isFallback, isTrue);
        final model = Provenance.fromJson(const {
          'generated_by': 'm (dev)',
          'source': 'model',
        });
        expect(model.source, BriefSource.model);
        expect(model.isFallback, isFalse);
        expect(
          fallback.toJson()['provenance'],
          containsPair('source', 'fallback'),
        );
      });

      test('Provenance.source tolerates absence, null and unknown values', () {
        for (final json in [
          {'generated_by': 'g'},
          {'generated_by': 'g', 'source': null},
          {'generated_by': 'g', 'source': 'something_new'},
        ]) {
          final p = Provenance.fromJson(json);
          expect(p.source, isNull, reason: '$json');
          expect(p.isFallback, isFalse);
        }
      });

      test('IntakeTurn parse_path and brief_parse_path', () {
        final turn = IntakeTurn.fromJson(const {
          'reply': 'Thank you.',
          'status': 'ready',
          'done': true,
          'parse_path': 'first_pass',
          'brief_parse_path': 'fallback',
        });
        expect(turn.parsePath, ParsePath.firstPass);
        expect(turn.briefParsePath, ParsePath.fallback);
        expect(turn.toJson()['parse_path'], 'first_pass');
        for (final (wire, value) in [
          ('repair', ParsePath.repair),
          ('fallback', ParsePath.fallback),
          ('rule', ParsePath.rule),
        ]) {
          expect(
            IntakeTurn.fromJson({
              'reply': 'r',
              'status': 'in_progress',
              'parse_path': wire,
            }).parsePath,
            value,
          );
        }
      });

      test('IntakeTurn parse paths tolerate absence and unknown values', () {
        final absent = IntakeTurn.fromJson(const {
          'reply': 'r',
          'status': 'in_progress',
        });
        expect(absent.parsePath, isNull);
        expect(absent.briefParsePath, isNull);
        final unknown = IntakeTurn.fromJson(const {
          'reply': 'r',
          'status': 'in_progress',
          'parse_path': 'teleport',
          'brief_parse_path': null,
        });
        expect(unknown.parsePath, isNull);
        expect(unknown.briefParsePath, isNull);
      });

      test('TrustEvent parses a fallback node with no model', () {
        final event = TrustEvent.fromJson(const {
          'node': 'brief_fallback',
          'mode': 'dev',
          'model_id': null,
          'policy_required': 'no_model_call',
          'outcome': 'ok',
          'evidence': {
            'parse_path': 'fallback',
            'json_mode': 'json_object',
            'attempt': 2,
            'after_error': 'json_parse_failed',
          },
        });
        expect(event.node, TrustNodes.briefFallback);
        expect(event.modelId, isNull);
        expect(event.isNoModelCall, isTrue);
        expect(event.evidence['attempt'], 2);
        final model = TrustEvent.fromJson(const {
          'node': 'intake',
          'mode': 'dev',
          'policy_required': 'zdr',
          'outcome': 'ok',
          'evidence': {'parse_path': 'repair', 'json_mode': 'off'},
        });
        expect(model.isNoModelCall, isFalse);
      });
    });

    test('RedFlagRule id and BriefDecision wire values', () {
      expect(RedFlagRule.r6.id, 'R6');
      expect(BriefDecision.approve.wire, 'approve');
    });
  });

  group('SessionStatus wire values', () {
    test('round-trip every server value', () {
      for (final status in SessionStatus.values) {
        expect(SessionStatus.tryParse(status.wire), status);
      }
      expect(SessionStatus.inProgress.wire, 'in_progress');
      expect(SessionStatus.tryParse('bogus'), isNull);
      expect(SessionStatus.tryParse(null), isNull);
    });
  });

  group('LockedFailure', () {
    test('compares status and urgent message', () {
      expect(
        const AppFailure.locked('session_locked', SessionStatus.ready),
        const AppFailure.locked('session_locked', SessionStatus.ready),
      );
      expect(
        const AppFailure.locked('session_locked', SessionStatus.urgent),
        isNot(const AppFailure.locked('session_locked')),
      );
    });
  });
}
