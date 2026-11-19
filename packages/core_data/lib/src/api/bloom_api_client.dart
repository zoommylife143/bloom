import 'dart:async';
import 'dart:convert';

import 'package:core_domain/core_domain.dart';
import 'package:http/http.dart' as http;

/// Decodes a JSON response body into a domain value.
typedef JsonDecoder<T> = T Function(Object? json);

/// Thin client for the Bloom FastAPI server (plan section 6). Every method
/// returns a [Result]; nothing throws into blocs. Only repositories call it;
/// widgets never do.
///
/// Endpoint shapes follow docs/api-contract.md. Keep contract changes inside
/// this file and the entities in core_domain.
class BloomApiClient {
  new({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      baseUrl = _trimSlash(baseUrl ?? defaultBaseUrl);

  /// `--dart-define=API_BASE_URL=...`, default `/api` (same origin behind
  /// nginx).
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '/api',
  );

  /// The error code the server returns with HTTP 502 when private mode
  /// refuses.
  static const routeRefusedCode = 'confidential_route_unavailable';

  /// Cheap calls (no model): reads, login, decisions.
  static const shortTimeout = Duration(seconds: 30);

  /// Calls that may wait on the model. The server bounds one patient turn to
  /// about 110 s of model time plus retrieval (`turn_budget_s`), nginx allows
  /// 180 s, so this sits between the two and the server answers first.
  static const modelTimeout = Duration(seconds: 160);

  /// D05 scenario replay: up to 12 model turns in one request. nginx allows
  /// 900 s on `/api/demo/`, so this sits just under it.
  static const scenarioRunTimeout = Duration(seconds: 840);

  final http.Client _http;
  final String baseUrl;

  /// Demo role token from [login]. Not production auth.
  String? token;

  // ---- Auth ---------------------------------------------------------------

  /// `POST /login {role}`. Stores the token for later calls.
  Future<Result<void>> login(BloomRole role) async {
    final result = await _send<String?>(
      'POST',
      '/login',
      body: {'role': role.name},
      decode: (json) {
        final map = _asMap(json);
        return (map['token'] ?? map['access_token']) as String?;
      },
    );
    return result.map((value) {
      token = value;
    });
  }

  // ---- Patient intake -----------------------------------------------------

  /// `POST /sessions {scenario_id?}`.
  Future<Result<StartedSession>> createSession({String? scenarioId}) => _send(
    'POST',
    '/sessions',
    body: {'scenario_id': ?scenarioId},
    timeout: modelTimeout,
    decode: (json) => StartedSession.fromJson(_asMap(json)),
  );

  /// `POST /sessions/{id}/messages {text, client_message_id?}`.
  /// 409 → [LockedFailure] with `status` (and `urgent` when urgent);
  /// 502 refused → [RouteRefusedFailure].
  ///
  /// Reuse the same [clientMessageId] when resending a turn after a timeout
  /// or network error: the server returns the stored result of the first
  /// request instead of running the turn again.
  Future<Result<IntakeTurn>> sendMessage(
    String sessionId,
    String text, {
    String? clientMessageId,
  }) => _send(
    'POST',
    '/sessions/${Uri.encodeComponent(sessionId)}/messages',
    body: {'text': text, 'client_message_id': ?clientMessageId},
    timeout: modelTimeout,
    decode: (json) => IntakeTurn.fromJson(_asMap(json)),
  );

  // ---- Clinic -------------------------------------------------------------

  /// `GET /sessions`: newest first, red flags first.
  Future<Result<List<SessionSummary>>> listSessions() => _send(
    'GET',
    '/sessions',
    decode: (json) =>
        _asList(json, 'sessions').map(SessionSummary.fromJson).toList(),
  );

  /// `GET /sessions/{id}/brief`. 404 until generated.
  Future<Result<BriefBundle>> getBrief(String sessionId) => _send(
    'GET',
    '/sessions/${Uri.encodeComponent(sessionId)}/brief',
    decode: (json) => BriefBundle.fromJson(_asMap(json)),
  );

  /// `POST /briefs/{brief_id}/decision`. 409 `already_decided`.
  Future<Result<BriefBundle>> decideBrief(
    String briefId, {
    required BriefDecision decision,
    required String reviewer,
    Brief? edited,
  }) => _send(
    'POST',
    '/briefs/${Uri.encodeComponent(briefId)}/decision',
    body: {
      'decision': decision.wire,
      'reviewer': reviewer,
      'edited': ?edited?.toJson(),
    },
    decode: (json) => BriefBundle.fromJson(_asMap(json)),
  );

  /// `GET /sessions/{id}/trust` (D03).
  Future<Result<TrustReport>> getTrust(String sessionId) => _send(
    'GET',
    '/sessions/${Uri.encodeComponent(sessionId)}/trust',
    decode: (json) => TrustReport.fromJson(_asMap(json)),
  );

  /// `GET /sessions/{id}/flag` (D06).
  Future<Result<RedFlagSummary>> getRedFlag(String sessionId) => _send(
    'GET',
    '/sessions/${Uri.encodeComponent(sessionId)}/flag',
    decode: (json) =>
        RedFlagSummary.fromJson({'session_id': sessionId, ..._asMap(json)}),
  );

  /// `GET /audit` (D04).
  Future<Result<List<AuditRow>>> getAudit() => _send(
    'GET',
    '/audit',
    decode: (json) => _asList(json, 'rows').map(AuditRow.fromJson).toList(),
  );

  /// `POST /demo/negative-test {session_id?}`: HTTP 200 with
  /// outcome=refused is the expected result.
  Future<Result<TrustEvent>> runNegativeTest({String? sessionId}) => _send(
    'POST',
    '/demo/negative-test',
    body: {'session_id': ?sessionId},
    timeout: modelTimeout,
    decode: (json) => TrustEvent.fromJson(_asMap(json)),
  );

  /// `POST /demo/scenarios/{id}/run`.
  Future<Result<ScenarioRun>> runScenario(String scenarioId) => _send(
    'POST',
    '/demo/scenarios/${Uri.encodeComponent(scenarioId)}/run',
    // Replays up to 12 model turns; nginx gives /api/demo/ 900 s.
    timeout: scenarioRunTimeout,
    decode: (json) => ScenarioRun.fromJson(_asMap(json)),
  );

  /// `GET /healthz`.
  Future<Result<HealthStatus>> health() => _send(
    'GET',
    '/healthz',
    decode: (json) => HealthStatus.fromJson(_asMap(json)),
  );

  void close() => _http.close();

  // ---- Plumbing -----------------------------------------------------------

  Future<Result<T>> _send<T>(
    String method,
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    Duration timeout = shortTimeout,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    if (token case final token?) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _http.send(request).timeout(timeout),
      );
    } on TimeoutException {
      return const Result.err(AppFailure.network('timeout'));
    } on http.ClientException catch (e) {
      return Result.err(AppFailure.network(e.message));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return Result.err(mapHttpError(response.statusCode, response.body));
    }
    try {
      final json = response.body.isEmpty ? null : jsonDecode(response.body);
      return Result.ok(decode(json));
    } on Object catch (e) {
      // Bad JSON or a contract mismatch. Report the type only, never the body.
      return Result.err(
        AppFailure.server(
          statusCode: response.statusCode,
          message: 'unreadable response (${e.runtimeType})',
        ),
      );
    }
  }

  /// Maps a non-2xx response to an [AppFailure]:
  /// 502 `confidential_route_unavailable` → routeRefused, 409 → locked
  /// (with the session status and urgent message when sent), 404 → notFound,
  /// anything else (401, 403, 422, 429, other 5xx) → server with the code.
  static AppFailure mapHttpError(int statusCode, String body) {
    final code = _errorCode(body);
    if (statusCode == 502 && code == routeRefusedCode) {
      return AppFailure.routeRefused(code);
    }
    return switch (statusCode) {
      409 => _locked(code, body),
      404 => AppFailure.notFound(code),
      _ => AppFailure.server(statusCode: statusCode, message: code),
    };
  }

  // 409 `session_locked` carries `status` and `urgent`; tolerate their absence.
  static AppFailure _locked(String? code, String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      decoded = null;
    }
    if (decoded is! Map) return AppFailure.locked(code);
    final status = SessionStatus.tryParse(decoded['status']);
    UrgentMessage? urgent;
    if (decoded['urgent'] case final Map<dynamic, dynamic> u) {
      try {
        urgent = UrgentMessage.fromJson(u.cast<String, dynamic>());
      } on Object {
        urgent = null; // malformed: status alone still routes to P03
      }
    }
    return AppFailure.locked(code, status, urgent);
  }

  // Reads `{"error": "..."}` or FastAPI's `{"detail": "..." | {"error": ...}}`.
  static String? _errorCode(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return null;
      final detail = json['detail'];
      final value = json['error'] ?? (detail is Map ? detail['error'] : detail);
      return value is String ? value : null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic> _asMap(Object? json) =>
      (json! as Map).cast<String, dynamic>();

  // Accepts a bare list or `{key: [...]}`.
  static Iterable<Map<String, dynamic>> _asList(Object? json, String key) {
    final list = json is Map ? json[key] : json;
    return (list! as List).map((e) => (e as Map).cast<String, dynamic>());
  }

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
