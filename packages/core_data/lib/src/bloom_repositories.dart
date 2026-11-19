import 'package:core_data/src/api/bloom_api_client.dart';
import 'package:core_data/src/fakes/fake_repositories.dart';
import 'package:core_data/src/repositories/api_repositories.dart';
import 'package:core_domain/core_domain.dart';

/// The four repositories an app provides at its root.
class BloomRepositories {
  const new({
    required this.intake,
    required this.brief,
    required this.trust,
    required this.session,
  });

  /// Repositories over one shared [BloomApiClient].
  factory api([BloomApiClient? client]) {
    final api = client ?? BloomApiClient();
    return BloomRepositories(
      intake: ApiIntakeRepository(api),
      brief: ApiBriefRepository(api),
      trust: ApiTrustRepository(api),
      session: ApiSessionRepository(api),
    );
  }

  /// In-memory synthetic repositories.
  factory fake() => BloomRepositories(
    intake: FakeIntakeRepository(),
    brief: FakeBriefRepository(),
    trust: FakeTrustRepository(),
    session: FakeSessionRepository(),
  );

  /// Fakes when built with `--dart-define=BLOOM_FAKE_API=true`, else the API.
  factory fromEnvironment() =>
      useFakeApi ? BloomRepositories.fake() : BloomRepositories.api();

  static const useFakeApi = bool.fromEnvironment('BLOOM_FAKE_API');

  final IntakeRepository intake;
  final BriefRepository brief;
  final TrustRepository trust;
  final SessionRepository session;
}
