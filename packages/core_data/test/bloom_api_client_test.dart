import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

BloomApiClient _client(
  Future<http.Response> Function(http.Request request) handler,
) => BloomApiClient(httpClient: MockClient(handler), baseUrl: '/api/');

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('BloomApiClient error mapping', () {
    test('502 confidential_route_unavailable maps to routeRefused', () async {
      final api = _client(
        (_) async => _json({'error': 'confidential_route_unavailable'}, 502),
      );
      final result = await api.sendMessage('s1', 'synthetic text');
      expect(result.failureOrNull, isA<RouteRefusedFailure>());
    });

    test('502 refusal inside FastAPI detail maps to routeRefused', () {
      final failure = BloomApiClient.mapHttpError(
        502,
        jsonEncode({
          'detail': {'error': 'confidential_route_unavailable'},
        }),
      );
      expect(failure, isA<RouteRefusedFailure>());
    });

    test('other 502 maps to server', () {
      final failure = BloomApiClient.mapHttpError(502, 'Bad Gateway');
      expect(failure, const ServerFailure(statusCode: 502));
    });

    test('409 maps to locked', () async {
      final api = _client(
        (_) async => _json({
          'error': 'session_locked',
          'detail': 'Session status is ready',
        }, 409),
      );
      final result = await api.sendMessage('s1', 'synthetic text');
      expect(result.failureOrNull, const AppFailure.locked('session_locked'));
    });

    test('502 model_error maps to server with the code', () {
      final failure = BloomApiClient.mapHttpError(
        502,
        jsonEncode({'error': 'model_error', 'detail': 'x'}),
      );
      expect(
        failure,
        const AppFailure.server(statusCode: 502, message: 'model_error'),
      );
    });

    test('404 maps to notFound', () async {
      final api = _client(
        (_) async => _json({'error': 'brief_not_found', 'detail': 'x'}, 404),
      );
      final result = await api.getBrief('s1');
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('ClientException maps to network', () async {
      final api = _client((_) async => throw http.ClientException('offline'));
      final result = await api.listSessions();
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('unreadable body maps to server, without throwing', () async {
      final api = _client((_) async => http.Response('not json', 200));
      final result = await api.health();
      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('BloomApiClient requests', () {
    test('sendMessage posts JSON to the session and parses the turn', () async {
      late http.Request seen;
      final api = _client((request) async {
        seen = request;
        return _json({
          'reply': 'How long has this been going on?',
          'status': 'in_progress',
          'progress': 0.25,
        });
      });
      final result = await api.sendMessage('s 1', 'synthetic text');

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/sessions/s%201/messages');
      expect(jsonDecode(seen.body), {'text': 'synthetic text'});
      expect(result.valueOrNull?.status, SessionStatus.inProgress);
    });

    test('login stores the token and sends it as a bearer header', () async {
      final headers = <Map<String, String>>[];
      final api = _client((request) async {
        headers.add(request.headers);
        return request.url.path.endsWith('/login')
            ? _json({'token': 'demo-token'})
            : _json(<Object>[]);
      });

      expect((await api.login(BloomRole.doctor)).isOk, isTrue);
      final sessions = await api.listSessions();

      expect(sessions.valueOrNull, isEmpty);
      expect(headers.last['Authorization'], 'Bearer demo-token');
    });

    test('createSession omits a null scenario_id', () async {
      late http.Request seen;
      final api = _client((request) async {
        seen = request;
        return _json({
          'session_id': 'abc',
          'mode': 'dev',
          'status': 'in_progress',
          'reply': 'Hi',
          'progress': 0.0,
        });
      });
      final result = await api.createSession();
      expect(jsonDecode(seen.body), <String, dynamic>{});
      expect(result.valueOrNull?.sessionId, 'abc');
    });

    test('decideBrief sends the wire decision', () async {
      late http.Request seen;
      final api = _client((request) async {
        seen = request;
        return _json({
          'brief_id': 'b1',
          'session_id': 's1',
          'edited': false,
          'brief': {
            'subjective': 's',
            'objective': 'o',
            'assessment_considerations': 'a',
            'plan_considerations': 'p',
          },
          'provenance': {
            'generated_by': 'm (dev)',
            'review_status': 'approved',
          },
        });
      });
      final result = await api.decideBrief(
        'b1',
        decision: BriefDecision.approve,
        reviewer: 'Dr Synthetic',
      );
      expect(seen.url.path, '/api/briefs/b1/decision');
      expect(jsonDecode(seen.body), {
        'decision': 'approve',
        'reviewer': 'Dr Synthetic',
      });
      expect(
        result.valueOrNull?.provenance.reviewStatus,
        ReviewStatus.approved,
      );
    });
  });

  group('Api repositories', () {
    test('ApiIntakeRepository returns routeRefused as a value', () async {
      final repo = ApiIntakeRepository(
        _client(
          (_) async => _json({'error': 'confidential_route_unavailable'}, 502),
        ),
      );
      final result = await repo.sendMessage(sessionId: 's1', text: 'x');
      expect(
        result,
        const Result<IntakeTurn>.err(
          AppFailure.routeRefused('confidential_route_unavailable'),
        ),
      );
    });
  });

  group('Fake repositories', () {
    test('FakeBriefRepository locks after one decision', () async {
      final repo = FakeBriefRepository();
      final first = await repo.decide(
        briefId: 'brief-s1',
        decision: BriefDecision.reject,
        reviewer: 'Dr Synthetic',
      );
      final second = await repo.decide(
        briefId: 'brief-s1',
        decision: BriefDecision.approve,
        reviewer: 'Dr Synthetic',
      );
      expect(first.valueOrNull?.provenance.reviewStatus, ReviewStatus.rejected);
      expect(second.failureOrNull, isA<LockedFailure>());
    });

    test(
      'fallback sessions get a no-AI draft and no-model trust rows',
      () async {
        final brief = await FakeBriefRepository().getBrief('fake-fallback');
        final bundle = brief.valueOrNull!;
        expect(bundle.provenance.isFallback, isTrue);
        expect(
          bundle.provenance.generatedBy,
          startsWith('deterministic-fallback'),
        );
        expect(
          bundle.brief.subjective,
          startsWith('DRAFT (automatic fallback'),
        );
        final normal = await FakeBriefRepository().getBrief('fake-ready');
        expect(normal.valueOrNull!.provenance.source, BriefSource.model);

        final trust = await FakeTrustRepository().getTrust('fake-fallback');
        final nodes = trust.valueOrNull!.events
            .where((e) => e.isNoModelCall)
            .map((e) => e.node);
        expect(nodes, [TrustNodes.intakeFallback, TrustNodes.briefFallback]);
        final plain = await FakeTrustRepository().getTrust('fake-ready');
        expect(
          plain.valueOrNull!.events.where((e) => e.isNoModelCall),
          isEmpty,
        );
      },
    );

    test('FakeIntakeRepository runs to ready, then locks', () async {
      final repo = FakeIntakeRepository(questions: const ['Q1', 'Q2']);
      final started = (await repo.startSession()).valueOrNull!;
      final turn = await repo.sendMessage(
        sessionId: started.sessionId,
        text: 'synthetic',
      );
      final locked = await repo.sendMessage(
        sessionId: started.sessionId,
        text: 'synthetic',
      );
      expect(turn.valueOrNull?.status, SessionStatus.ready);
      expect(locked.failureOrNull, isA<LockedFailure>());
    });
  });

  group('resend safety', () {
    test('sendMessage puts client_message_id on the wire', () async {
      late http.Request seen;
      final api = _client((request) async {
        seen = request;
        return _json({'reply': 'Next?', 'status': 'in_progress'});
      });
      await api.sendMessage('s1', 'synthetic text', clientMessageId: 'm-1');
      expect(jsonDecode(seen.body), {
        'text': 'synthetic text',
        'client_message_id': 'm-1',
      });
    });

    test('409 session_locked carries status and the urgent message', () {
      final failure = BloomApiClient.mapHttpError(
        409,
        jsonEncode({
          'error': 'session_locked',
          'detail': 'Session status is urgent',
          'status': 'urgent',
          'urgent': {
            'rule_id': 'R2',
            'title': 'Please get care now',
            'body': 'Synthetic body.',
            'actions': [
              {'label': 'Call 911', 'tel': 'tel:911'},
            ],
            'support': null,
          },
        }),
      );
      expect(failure, isA<LockedFailure>());
      final locked = failure as LockedFailure;
      expect(locked.status, SessionStatus.urgent);
      expect(locked.urgent?.ruleId, RedFlagRule.r2);
    });

    test('409 without status (already_decided) still maps to locked', () {
      final failure = BloomApiClient.mapHttpError(
        409,
        jsonEncode({'error': 'already_decided', 'detail': 'x'}),
      );
      expect(failure, const AppFailure.locked('already_decided'));
    });

    test('model calls get the long timeout, reads the short one', () {
      expect(
        BloomApiClient.modelTimeout,
        greaterThan(const Duration(seconds: 140)),
      );
      expect(
        BloomApiClient.modelTimeout,
        lessThan(const Duration(seconds: 180)),
      );
      expect(BloomApiClient.shortTimeout, const Duration(seconds: 30));
    });
  });
}
