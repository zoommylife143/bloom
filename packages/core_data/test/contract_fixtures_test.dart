// Contract check: every JSON response captured from a running Bloom server
// (server/scripts/contract_capture.py) is replayed through the real
// BloomApiClient and decoded with the real fromJson code. Synthetic data only.
//
// fixtures/contract/fake     offline fake model (BLOOM_FAKE_MODEL=1), every endpoint
// fixtures/contract/private  private mode with no confidential route (502 refusal)
// fixtures/contract/live     real TrustedRouter + Context.dev (2026-11-19)
// fixtures/contract/fallback hand-written from docs/api-contract.md (2026-11-19):
//                            fallback brief, parse_path, *_fallback trust nodes
import 'dart:convert';
import 'dart:io';

import 'package:core_data/core_data.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Fixture {
  new(this.file)
    : json = (jsonDecode(file.readAsStringSync()) as Map)
          .cast<String, dynamic>();

  final File file;
  final Map<String, dynamic> json;

  String get name => file.uri.pathSegments.last.replaceAll('.json', '');
  String get method => json['method'] as String;
  String get path => json['path'] as String;
  int get status => json['status'] as int;
  Object? get body => json['body'];
  Map<String, dynamic> get map => (body! as Map).cast<String, dynamic>();
  bool get ok => status >= 200 && status < 300;
  List<String> get segments => Uri.parse(path).pathSegments;
}

List<_Fixture> _load(String dir) {
  final directory = Directory('test/fixtures/contract/$dir');
  if (!directory.existsSync()) return const [];
  return (directory
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .map(_Fixture.new)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name)));
}

/// A client whose transport serves [f]'s body and checks the request the
/// client built: method, exact path under `/api` (no double slash), JSON body
/// and the bearer token.
BloomApiClient _serve(_Fixture f, {String? token = 'fixture-token'}) {
  final client = MockClient((request) async {
    expect(request.method, f.method, reason: f.name);
    expect(request.url.toString(), f.path, reason: '${f.name}: URL');
    expect(request.url.path, isNot(contains('//')), reason: f.name);
    if (token != null) {
      expect(request.headers['Authorization'], 'Bearer $token');
    }
    if (request.body.isNotEmpty) {
      expect(jsonDecode(request.body), isA<Map<String, dynamic>>());
    }
    return http.Response(
      jsonEncode(f.body),
      f.status,
      headers: {'content-type': 'application/json'},
    );
  });
  return BloomApiClient(httpClient: client, baseUrl: '/api')..token = token;
}

/// Calls the client method that owns [f]'s endpoint. Null when the client has
/// no method for it.
Future<Result<Object?>>? _call(_Fixture f) {
  final s = f.segments; // ['api', ...]
  final api = _serve(f, token: s[1] == 'login' ? null : 'fixture-token');
  return switch ((f.method, s.sublist(1))) {
    ('GET', ['healthz']) => api.health(),
    ('POST', ['login']) => api.login(BloomRole.patient),
    ('POST', ['sessions']) => api.createSession(),
    ('GET', ['sessions']) => api.listSessions(),
    ('POST', ['sessions', final id, 'messages']) => api.sendMessage(
      id,
      'synthetic text',
      clientMessageId: f.name.startsWith('resend') ? 'contract-check-1' : null,
    ),
    ('GET', ['sessions', final id, 'brief']) => api.getBrief(id),
    ('GET', ['sessions', final id, 'trust']) => api.getTrust(id),
    ('GET', ['sessions', final id, 'flag']) => api.getRedFlag(id),
    ('POST', ['briefs', final id, 'decision']) => api.decideBrief(
      id,
      decision: BriefDecision.approve,
      reviewer: 'Dr. Demo',
    ),
    ('GET', ['audit']) => api.getAudit(),
    ('POST', ['demo', 'negative-test']) => api.runNegativeTest(
      sessionId: (f.name == 'negative_test_no_session') ? null : 'x',
    ),
    ('POST', ['demo', 'scenarios', final id, 'run']) => api.runScenario(id),
    _ => null,
  };
}

void _expectFailure(_Fixture f, AppFailure failure) {
  final code = f.body is Map ? f.map['error'] : null;
  switch (f.status) {
    case 404:
      expect(failure, isA<NotFoundFailure>(), reason: f.name);
      expect(failure.message, code);
    case 409:
      expect(failure, isA<LockedFailure>(), reason: f.name);
      expect(failure.message, code);
      final locked = failure as LockedFailure;
      if (code == 'session_locked') {
        expect(locked.status?.wire, f.map['status'], reason: f.name);
        if (f.map['status'] == 'urgent') {
          expect(locked.urgent, isNotNull, reason: f.name);
          expect(locked.urgent!.actions, isNotEmpty);
        }
      }
    case 502 when code == BloomApiClient.routeRefusedCode:
      expect(failure, isA<RouteRefusedFailure>(), reason: f.name);
    default:
      expect(failure, isA<ServerFailure>(), reason: f.name);
      expect((failure as ServerFailure).statusCode, f.status);
      // FastAPI's own 422 has a list in `detail`; ours has a string `error`.
      expect(failure.message, code);
  }
}

/// Field-level checks on decoded values beyond "it parsed".
void _expectValue(_Fixture f, Object? value) {
  switch (value) {
    case HealthStatus(:final mode):
      expect(mode.name, f.map['mode']);
    case StartedSession(:final sessionId, :final reply, :final status):
      expect(sessionId, f.map['session_id']);
      expect(reply, isNotEmpty);
      expect(status, SessionStatus.inProgress);
    case IntakeTurn(
      :final status,
      :final urgent,
      :final done,
      :final parsePath,
      :final briefParsePath,
    ):
      expect(status.wire, f.map['status']);
      expect(done, f.map['done']);
      expect(_parsePathWire(parsePath), f.map['parse_path'], reason: f.name);
      expect(
        _parsePathWire(briefParsePath),
        f.map['brief_parse_path'],
        reason: f.name,
      );
      if (status == SessionStatus.urgent) {
        expect(urgent, isNotNull, reason: f.name);
        expect(urgent!.ruleId?.id, (f.map['urgent'] as Map)['rule_id']);
        expect(urgent.actions.first.tel, startsWith('tel:'));
      } else {
        expect(urgent, isNull);
      }
    case BriefBundle(:final brief, :final provenance, :final evidence):
      final urls = evidence.map((e) => e.url).toSet();
      for (final line in brief.screeningsPossiblyDue) {
        expect(line.sourceUrl == null || urls.contains(line.sourceUrl), isTrue);
      }
      final wire = f.map['provenance'] as Map;
      expect(provenance.reviewStatus.name, wire['review_status']);
      // `source` is new: absent on older captures, where it means model.
      expect(provenance.source?.name, wire['source'], reason: f.name);
      if (provenance.isFallback) {
        expect(provenance.generatedBy, startsWith('deterministic-fallback'));
        expect(brief.subjective, startsWith('DRAFT (automatic fallback'));
      }
      if (f.name.startsWith('decision_')) {
        expect(provenance.reviewedBy, 'Dr. Demo');
        expect(provenance.reviewedAt, isNotNull);
      }
    case TrustReport(:final events):
      expect(events.length, (f.map['events'] as List).length);
      expect(events.every((e) => e.createdAt != null), isTrue);
      for (final e in events.where((e) => e.isNoModelCall)) {
        expect(e.node, endsWith('_fallback'), reason: f.name);
        expect(e.modelId, isNull, reason: f.name);
        expect(e.outcome, TrustOutcome.ok, reason: f.name);
        expect(e.evidence['parse_path'], 'fallback', reason: f.name);
      }
    case RedFlagSummary(:final ruleId, :final title):
      expect(ruleId.id, f.map['rule_id']);
      expect(title, isNotEmpty);
    case TrustEvent(:final outcome, :final node):
      expect(node, 'negative_test');
      // D05 shows "Refused" for any 400 from the gateway, whatever its code.
      expect(outcome, TrustOutcome.refused, reason: f.name);
    case ScenarioRun(:final status):
      expect(status.wire, f.map['status']);
    case final List<SessionSummary> rows:
      expect(rows.length, (f.map['sessions'] as List).length);
      expect(rows.every((r) => r.id.isNotEmpty), isTrue);
    case final List<AuditRow> rows:
      expect(rows.length, (f.map['rows'] as List).length);
  }
}

/// The server's value for [p] (`first_pass`, ...); null stays null.
String? _parsePathWire(ParsePath? p) => switch (p) {
  null => null,
  ParsePath.firstPass => 'first_pass',
  final p => p.name,
};

void main() {
  for (final dir in ['fake', 'private', 'live', 'fallback']) {
    final fixtures = _load(dir);
    group('contract fixtures ($dir)', () {
      test('were captured', () {
        if (dir != 'live') expect(fixtures, isNotEmpty);
      });
      for (final f in fixtures) {
        test(f.name, () async {
          final call = _call(f);
          if (call == null) {
            // No client method (e.g. GET /guideline-updates): shape only.
            expect(f.body, isA<Map<String, dynamic>>());
            return;
          }
          final result = await call;
          if (f.ok) {
            expect(
              result.failureOrNull,
              isNull,
              reason: '${f.name}: ${result.failureOrNull}',
            );
            _expectValue(f, result.valueOrNull);
          } else {
            expect(result.failureOrNull, isNotNull, reason: f.name);
            _expectFailure(f, result.failureOrNull!);
          }
        });
      }
    });
  }

  test('fixtures hold no tokens or receipts', () {
    for (final f in [
      for (final dir in ['fake', 'private', 'live', 'fallback']) ..._load(dir),
    ]) {
      final text = f.file.readAsStringSync();
      if (f.name.startsWith('login')) expect(f.map['token'], '<redacted>');
      expect(text, isNot(contains('"signature"')), reason: f.name);
      // A real demo token is `<base64url>.<base64url>`.
      expect(
        RegExp(r'[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}').hasMatch(text),
        isFalse,
        reason: f.name,
      );
    }
  });

  test('the fallback fixtures cover every new field', () {
    final fixtures = {for (final f in _load('fallback')) f.name: f};
    final brief = BriefBundle.fromJson(fixtures['brief_fallback']!.map);
    expect(brief.provenance.source, BriefSource.fallback);
    final ready = IntakeTurn.fromJson(fixtures['fallback_turn_ready']!.map);
    expect(ready.parsePath, ParsePath.repair);
    expect(ready.briefParsePath, ParsePath.fallback);
    final trust = TrustReport.fromJson(fixtures['trust_fallback']!.map);
    expect(trust.events.where((e) => e.isNoModelCall).map((e) => e.node), [
      TrustNodes.intakeFallback,
      TrustNodes.briefFallback,
    ]);
    expect(trust.events.map((e) => e.evidence['repair_skipped']).nonNulls, [
      'turn_budget_low',
    ]);
  });

  test('resend with the same client_message_id returns the same turn', () {
    final fixtures = {for (final f in _load('fake')) f.name: f};
    expect(fixtures['resend_again']!.body, fixtures['resend_first']!.body);
  });
}
