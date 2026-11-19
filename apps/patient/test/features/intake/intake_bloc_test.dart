import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_patient/features/intake/domain/intake_conversation.dart';
import 'package:bloom_patient/features/intake/presentation/bloc/intake_bloc.dart';
import 'package:core_domain/core_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

// Synthetic data only.
const _sessionId = 'synthetic-session';
const _opening = 'Hi, I am Bloom. What brings you in today?';
const _answer = 'I would like a checkup.';
const _next = 'Which age group are you in?';

const _started = StartedSession(
  sessionId: _sessionId,
  mode: RouteMode.private,
  reply: _opening,
);

const _r5 = UrgentMessage(
  ruleId: RedFlagRule.r5,
  title: 'You are not alone',
  body: 'Synthetic support message.',
  actions: [
    UrgentAction(label: 'Call or text 988', tel: 'tel:988'),
    UrgentAction(label: 'Call 911', tel: 'tel:911'),
  ],
);

const _chatting = IntakeConversation(
  sessionId: _sessionId,
  mode: RouteMode.private,
  messages: [IntakeMessage.bloom(_opening)],
);

final IntakeConversation _afterAnswer = _chatting.addMessage(
  const IntakeMessage.patient(_answer),
);

void main() {
  late MockIntakeRepository repository;

  setUp(() {
    repository = MockIntakeRepository();
    when(() => repository.startSession(scenarioId: any(named: 'scenarioId')))
        .thenAnswer((_) async => const Result.ok(_started));
  });

  void reply(Result<IntakeTurn> result) => when(
    () => repository.sendMessage(
      sessionId: any(named: 'sessionId'),
      text: any(named: 'text'),
      clientMessageId: any(named: 'clientMessageId'),
    ),
  ).thenAnswer((_) async => result);

  IntakeBloc build() => IntakeBloc(repository: repository);

  test('starts idle with no session', () {
    final bloc = build();
    expect(bloc.state, const IntakeState.idle());
    expect(bloc.state.conversation.hasSession, isFalse);
    bloc.close().ignore();
  });

  group('IntakeStarted', () {
    blocTest<IntakeBloc, IntakeState>(
      'sending → idle with Bloom’s first question',
      build: build,
      act: (bloc) => bloc.add(const IntakeStarted()),
      expect: () => const [
        IntakeState.sending(),
        IntakeState.idle(conversation: _chatting),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      'start failure → error without a session; retry starts again',
      setUp: () {
        var calls = 0;
        when(
          () => repository.startSession(scenarioId: any(named: 'scenarioId')),
        ).thenAnswer(
          (_) async => calls++ == 0
              ? const Result.err(AppFailure.network('timeout'))
              : const Result.ok(_started),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const IntakeStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeRetried());
      },
      expect: () => const [
        IntakeState.sending(),
        IntakeState.error(
          conversation: IntakeConversation.empty,
          failure: AppFailure.network('timeout'),
        ),
        IntakeState.sending(),
        IntakeState.idle(conversation: _chatting),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      'ignored once a session exists',
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeStarted()),
      expect: () => const <IntakeState>[],
    );
  });

  group('IntakeMessageSubmitted', () {
    blocTest<IntakeBloc, IntakeState>(
      'send → waiting → reply',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(
            reply: _next,
            status: SessionStatus.inProgress,
            progress: 0.2,
          ),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted('  $_answer ')),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.idle(
          conversation: _afterAnswer
              .addMessage(const IntakeMessage.bloom(_next))
              .copyWith(progress: 0.2),
        ),
      ],
      verify: (_) => verify(
        () => repository.sendMessage(
          sessionId: _sessionId,
          text: _answer,
          clientMessageId: any(named: 'clientMessageId'),
        ),
      ).called(1),
    );

    blocTest<IntakeBloc, IntakeState>(
      'blank text and sends while waiting are ignored',
      build: build,
      seed: () =>
          IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
      act: (bloc) => bloc
        ..add(const IntakeMessageSubmitted('   '))
        ..add(const IntakeMessageSubmitted('again')),
      expect: () => const <IntakeState>[],
    );

    blocTest<IntakeBloc, IntakeState>(
      '502 confidential_route_unavailable → routeRefused, answer kept',
      setUp: () => reply(
        const Result.err(
          AppFailure.routeRefused('confidential_route_unavailable'),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.routeRefused(
          conversation: _afterAnswer,
          pendingText: _answer,
        ),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      '502 model_error → error with the answer to resend',
      setUp: () => reply(
        const Result.err(
          AppFailure.server(statusCode: 502, message: 'model_error'),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.error(
          conversation: _afterAnswer,
          failure: const AppFailure.server(
            statusCode: 502,
            message: 'model_error',
          ),
          pendingText: _answer,
        ),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      '409 session_locked → locked',
      setUp: () => reply(const Result.err(AppFailure.locked('session_locked'))),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.locked(conversation: _afterAnswer),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      'urgent payload → urgent with the server message (finished)',
      setUp: () => reply(
        Result.ok(
          IntakeTurn(
            reply: _r5.body,
            status: SessionStatus.urgent,
            progress: 1,
            done: true,
            urgent: _r5,
          ),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.urgent(
          conversation: _afterAnswer.copyWith(progress: 1),
          message: _r5,
        ),
      ],
      verify: (bloc) => expect(bloc.state.isFinished, isTrue),
    );

    blocTest<IntakeBloc, IntakeState>(
      'urgent status without a payload falls back to fixed copy',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(reply: 'x', status: SessionStatus.urgent, done: true),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      skip: 1,
      expect: () => [
        isA<IntakeUrgent>().having(
          (s) => s.message,
          'message',
          IntakeBloc.fallbackUrgent,
        ),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      'ready → done with the closing line',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(
            reply: 'Thank you.',
            status: SessionStatus.ready,
            progress: 1,
            done: true,
          ),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      skip: 1,
      expect: () => [
        IntakeState.done(
          conversation: _afterAnswer
              .addMessage(const IntakeMessage.bloom('Thank you.'))
              .copyWith(progress: 1),
        ),
      ],
    );
  });

  group('IntakeRetried', () {
    blocTest<IntakeBloc, IntakeState>(
      'after routeRefused resends the same answer without repeating it',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(reply: _next, status: SessionStatus.inProgress),
        ),
      ),
      build: build,
      seed: () => IntakeState.routeRefused(
        conversation: _afterAnswer,
        pendingText: _answer,
      ),
      act: (bloc) => bloc.add(const IntakeRetried()),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.idle(
          conversation: _afterAnswer.addMessage(
            const IntakeMessage.bloom(_next),
          ),
        ),
      ],
      verify: (_) => verify(
        () => repository.sendMessage(
          sessionId: _sessionId,
          text: _answer,
          clientMessageId: any(named: 'clientMessageId'),
        ),
      ).called(1),
    );

    blocTest<IntakeBloc, IntakeState>(
      'does nothing outside error states',
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeRetried()),
      expect: () => const <IntakeState>[],
    );
  });

  group('live demo robustness', () {
    for (final (name, failure) in const [
      ('429 rate limited', AppFailure.server(statusCode: 429)),
      ('503 unavailable', AppFailure.server(statusCode: 503)),
      ('504 gateway timeout', AppFailure.server(statusCode: 504)),
      ('network failure', AppFailure.network('XMLHttpRequest error')),
      ('client timeout', AppFailure.network('timeout')),
    ]) {
      blocTest<IntakeBloc, IntakeState>(
        '$name → error (no spinner left) → Try again resends the answer',
        setUp: () {
          var calls = 0;
          when(
            () => repository.sendMessage(
              sessionId: any(named: 'sessionId'),
              text: any(named: 'text'),
              clientMessageId: any(named: 'clientMessageId'),
            ),
          ).thenAnswer(
            (_) async => calls++ == 0
                ? Result<IntakeTurn>.err(failure)
                : const Result.ok(
                    IntakeTurn(reply: _next, status: SessionStatus.inProgress),
                  ),
          );
        },
        build: build,
        seed: () => const IntakeState.idle(conversation: _chatting),
        act: (bloc) async {
          bloc.add(const IntakeMessageSubmitted(_answer));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const IntakeRetried());
        },
        expect: () => [
          IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
          IntakeState.error(
            conversation: _afterAnswer,
            failure: failure,
            pendingText: _answer,
          ),
          IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
          IntakeState.idle(
            conversation: _afterAnswer.addMessage(
              const IntakeMessage.bloom(_next),
            ),
          ),
        ],
        verify: (_) => verify(
          () => repository.sendMessage(
            sessionId: _sessionId,
            text: _answer,
            clientMessageId: any(named: 'clientMessageId'),
          ),
        ).called(2),
      );
    }

    blocTest<IntakeBloc, IntakeState>(
      'a slow reply keeps waiting until it arrives, then continues',
      setUp: () =>
          when(
            () => repository.sendMessage(
              sessionId: any(named: 'sessionId'),
              text: any(named: 'text'),
              clientMessageId: any(named: 'clientMessageId'),
            ),
          ).thenAnswer(
            (_) => Future.delayed(
              const Duration(milliseconds: 50),
              () => const Result.ok(
                IntakeTurn(reply: _next, status: SessionStatus.inProgress),
              ),
            ),
          ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.idle(
          conversation: _afterAnswer.addMessage(
            const IntakeMessage.bloom(_next),
          ),
        ),
      ],
    );

    blocTest<IntakeBloc, IntakeState>(
      'double submit in the same frame sends once',
      // Real replies take longer than one event-loop turn; the second tap
      // lands while the first answer is in flight.
      setUp: () =>
          when(
            () => repository.sendMessage(
              sessionId: any(named: 'sessionId'),
              text: any(named: 'text'),
              clientMessageId: any(named: 'clientMessageId'),
            ),
          ).thenAnswer(
            (_) => Future.delayed(
              const Duration(milliseconds: 10),
              () => const Result.ok(
                IntakeTurn(reply: _next, status: SessionStatus.inProgress),
              ),
            ),
          ),
      wait: const Duration(milliseconds: 50),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc
        ..add(const IntakeMessageSubmitted(_answer))
        ..add(const IntakeMessageSubmitted(_answer))
        ..add(const IntakeMessageSubmitted('Yes')),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.idle(
          conversation: _afterAnswer.addMessage(
            const IntakeMessage.bloom(_next),
          ),
        ),
      ],
      verify: (_) => verify(
        () => repository.sendMessage(
          sessionId: any(named: 'sessionId'),
          text: any(named: 'text'),
          clientMessageId: any(named: 'clientMessageId'),
        ),
      ).called(1),
    );

    blocTest<IntakeBloc, IntakeState>(
      'double Try again sends once',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(reply: _next, status: SessionStatus.inProgress),
        ),
      ),
      build: build,
      seed: () => IntakeState.error(
        conversation: _afterAnswer,
        failure: const AppFailure.server(statusCode: 502),
        pendingText: _answer,
      ),
      act: (bloc) => bloc
        ..add(const IntakeRetried())
        ..add(const IntakeRetried()),
      skip: 1,
      expect: () => [isA<IntakeIdle>()],
      verify: (_) => verify(
        () => repository.sendMessage(
          sessionId: any(named: 'sessionId'),
          text: any(named: 'text'),
          clientMessageId: any(named: 'clientMessageId'),
        ),
      ).called(1),
    );

    blocTest<IntakeBloc, IntakeState>(
      'double Start creates one session',
      build: build,
      act: (bloc) => bloc
        ..add(const IntakeStarted())
        ..add(const IntakeStarted()),
      expect: () => const [
        IntakeState.sending(),
        IntakeState.idle(conversation: _chatting),
      ],
      verify: (_) => verify(
        () => repository.startSession(scenarioId: any(named: 'scenarioId')),
      ).called(1),
    );

    final late = Completer<Result<IntakeTurn>>();
    blocTest<IntakeBloc, IntakeState>(
      'a reply that lands after Reset and a new answer is dropped',
      setUp: () {
        var calls = 0;
        when(
          () => repository.sendMessage(
            sessionId: any(named: 'sessionId'),
            text: any(named: 'text'),
            clientMessageId: any(named: 'clientMessageId'),
          ),
        ).thenAnswer(
          (_) => calls++ == 0
              ? late.future
              : Completer<Result<IntakeTurn>>().future,
        );
      },
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) async {
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeReset());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeMessageSubmitted('Second session answer'));
        await Future<void>.delayed(Duration.zero);
        late.complete(
          const Result.ok(
            IntakeTurn(
              reply: 'stale',
              status: SessionStatus.urgent,
              done: true,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state, isA<IntakeWaiting>());
        expect(
          bloc.state.conversation.messages.map((m) => m.text),
          isNot(contains('stale')),
        );
      },
    );

    final lateStart = Completer<Result<StartedSession>>();
    blocTest<IntakeBloc, IntakeState>(
      'a session that starts after Reset is dropped',
      setUp: () => when(
        () => repository.startSession(scenarioId: any(named: 'scenarioId')),
      ).thenAnswer((_) => lateStart.future),
      build: build,
      act: (bloc) async {
        bloc.add(const IntakeStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeReset());
        await Future<void>.delayed(Duration.zero);
        lateStart.complete(const Result.ok(_started));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const [IntakeState.sending(), IntakeState.idle()],
    );

    blocTest<IntakeBloc, IntakeState>(
      'an empty in-progress reply adds no blank bubble',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(reply: '  ', status: SessionStatus.inProgress),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      skip: 1,
      expect: () => [IntakeState.idle(conversation: _afterAnswer)],
    );
  });

  group('clientMessageId', () {
    late List<String> issued;

    IntakeBloc buildWithIds() {
      var next = 0;
      issued = [];
      return IntakeBloc(
        repository: repository,
        clientMessageIdFactory: () {
          final id = 'turn-${next++}';
          issued.add(id);
          return id;
        },
      );
    }

    void verifySent(String text, String id, int times) => verify(
      () => repository.sendMessage(
        sessionId: _sessionId,
        text: text,
        clientMessageId: id,
      ),
    ).called(times);

    blocTest<IntakeBloc, IntakeState>(
      'client timeout → Try again resends with the same id; next turn gets a '
      'new one',
      setUp: () {
        var calls = 0;
        when(
          () => repository.sendMessage(
            sessionId: any(named: 'sessionId'),
            text: any(named: 'text'),
            clientMessageId: any(named: 'clientMessageId'),
          ),
        ).thenAnswer(
          (_) async => calls++ == 0
              ? const Result<IntakeTurn>.err(AppFailure.network('timeout'))
              : const Result.ok(
                  IntakeTurn(reply: _next, status: SessionStatus.inProgress),
                ),
        );
      },
      build: buildWithIds,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) async {
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeRetried());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeMessageSubmitted('Yes'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifySent(_answer, 'turn-0', 2);
        verifySent('Yes', 'turn-1', 1);
        expect(issued, ['turn-0', 'turn-1']);
      },
    );

    blocTest<IntakeBloc, IntakeState>(
      'route refused → Try again reuses the id',
      setUp: () {
        var calls = 0;
        when(
          () => repository.sendMessage(
            sessionId: any(named: 'sessionId'),
            text: any(named: 'text'),
            clientMessageId: any(named: 'clientMessageId'),
          ),
        ).thenAnswer(
          (_) async => calls++ == 0
              ? const Result<IntakeTurn>.err(
                  AppFailure.routeRefused('confidential_route_unavailable'),
                )
              : const Result.ok(
                  IntakeTurn(reply: _next, status: SessionStatus.inProgress),
                ),
        );
      },
      build: buildWithIds,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) async {
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeRetried());
      },
      verify: (_) {
        verifySent(_answer, 'turn-0', 2);
        expect(issued, ['turn-0']);
      },
    );

    blocTest<IntakeBloc, IntakeState>(
      'Try again on a seeded error (no id yet) makes one id',
      setUp: () => reply(
        const Result.ok(
          IntakeTurn(reply: _next, status: SessionStatus.inProgress),
        ),
      ),
      build: buildWithIds,
      seed: () => IntakeState.error(
        conversation: _afterAnswer,
        failure: const AppFailure.network('timeout'),
        pendingText: _answer,
      ),
      act: (bloc) => bloc.add(const IntakeRetried()),
      verify: (_) => verifySent(_answer, 'turn-0', 1),
    );

    blocTest<IntakeBloc, IntakeState>(
      'Reset drops the pending id',
      setUp: () => reply(const Result.err(AppFailure.network('timeout'))),
      build: buildWithIds,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) async {
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeReset());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifySent(_answer, 'turn-0', 1);
        verifySent(_answer, 'turn-1', 1);
      },
    );

    test('default ids are unique, short and carry no answer text', () async {
      final ids = <String?>[];
      when(
        () => repository.sendMessage(
          sessionId: any(named: 'sessionId'),
          text: any(named: 'text'),
          clientMessageId: any(named: 'clientMessageId'),
        ),
      ).thenAnswer((invocation) async {
        ids.add(invocation.namedArguments[#clientMessageId] as String?);
        return const Result.ok(
          IntakeTurn(reply: _next, status: SessionStatus.inProgress),
        );
      });
      final bloc = build()..add(const IntakeStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const IntakeMessageSubmitted(_answer));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const IntakeMessageSubmitted(_answer));
      await Future<void>.delayed(Duration.zero);
      await bloc.close();

      expect(ids, hasLength(2));
      expect(ids.toSet(), hasLength(2));
      for (final id in ids) {
        expect(id, isNotNull);
        expect(id!.length, inInclusiveRange(1, 64));
        expect(id, isNot(contains('checkup')));
      }
    });
  });

  group('409 session_locked', () {
    blocTest<IntakeBloc, IntakeState>(
      'status urgent with payload → P03 with that payload, never P04',
      setUp: () => reply(
        const Result.err(
          AppFailure.locked('session_locked', SessionStatus.urgent, _r5),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      expect: () => [
        IntakeState.waiting(conversation: _afterAnswer, pendingText: _answer),
        IntakeState.urgent(conversation: _afterAnswer, message: _r5),
      ],
      verify: (bloc) {
        expect(bloc.state, isNot(isA<IntakeLocked>()));
        expect(bloc.state, isNot(isA<IntakeDone>()));
      },
    );

    blocTest<IntakeBloc, IntakeState>(
      'status urgent without payload → P03 with the fixed fallback',
      setUp: () => reply(
        const Result.err(
          AppFailure.locked('session_locked', SessionStatus.urgent),
        ),
      ),
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
      skip: 1,
      expect: () => [
        IntakeState.urgent(
          conversation: _afterAnswer,
          message: IntakeBloc.fallbackUrgent,
        ),
      ],
    );

    for (final status in [
      SessionStatus.ready,
      SessionStatus.approved,
      SessionStatus.edited,
      SessionStatus.rejected,
    ]) {
      blocTest<IntakeBloc, IntakeState>(
        'status ${status.wire} → locked (P04)',
        setUp: () =>
            reply(Result.err(AppFailure.locked('session_locked', status))),
        build: build,
        seed: () => const IntakeState.idle(conversation: _chatting),
        act: (bloc) => bloc.add(const IntakeMessageSubmitted(_answer)),
        skip: 1,
        expect: () => [IntakeState.locked(conversation: _afterAnswer)],
      );
    }

    blocTest<IntakeBloc, IntakeState>(
      'on Try again after a timeout (the lost reply was urgent) → P03',
      setUp: () {
        var calls = 0;
        when(
          () => repository.sendMessage(
            sessionId: any(named: 'sessionId'),
            text: any(named: 'text'),
            clientMessageId: any(named: 'clientMessageId'),
          ),
        ).thenAnswer(
          (_) async => calls++ == 0
              ? const Result<IntakeTurn>.err(AppFailure.network('timeout'))
              : const Result<IntakeTurn>.err(
                  AppFailure.locked(
                    'session_locked',
                    SessionStatus.urgent,
                    _r5,
                  ),
                ),
        );
      },
      build: build,
      seed: () => const IntakeState.idle(conversation: _chatting),
      act: (bloc) async {
        bloc.add(const IntakeMessageSubmitted(_answer));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const IntakeRetried());
      },
      skip: 3,
      expect: () => [
        IntakeState.urgent(conversation: _afterAnswer, message: _r5),
      ],
    );
  });

  blocTest<IntakeBloc, IntakeState>(
    'IntakeReset forgets the session',
    build: build,
    seed: () => const IntakeState.done(conversation: _chatting),
    act: (bloc) => bloc.add(const IntakeReset()),
    expect: () => const [IntakeState.idle()],
  );

  test('progress never goes backwards', () {
    final c = _chatting.copyWith(progress: 0.5).copyWith(progress: 0.3);
    expect(c.progress, 0.5);
  });
}
