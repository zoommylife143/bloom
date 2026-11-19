import 'package:core_domain/core_domain.dart';

/// Synthetic demo scenarios S1-S10 (repo `scenarios/*.json`), with the D05
/// card copy from Figma. All data is synthetic.
class DemoScenario {
  const new({
    required this.id,
    required this.summary,
    required this.expected,
    required this.redFlag,
  });

  final String id;
  final String summary;
  final String expected;

  /// Expected to stop at a red flag (urgent) rather than a ready brief.
  final bool redFlag;
}

const demoScenarios = <DemoScenario>[
  DemoScenario(
    id: 'S1',
    summary: '34 · overdue cervical screening',
    expected: 'Expected: Brief + citation',
    redFlag: false,
  ),
  DemoScenario(
    id: 'S2',
    summary: '52 · postmenopausal spotting',
    expected: 'Expected: Brief flags bleeding',
    redFlag: false,
  ),
  DemoScenario(
    id: 'S3',
    summary: '27 · painful periods',
    expected: 'Expected: Brief, no flags',
    redFlag: false,
  ),
  DemoScenario(
    id: 'S4',
    summary: '45 · heavy periods, fatigue',
    expected: 'Expected: Brief, no urgent',
    redFlag: false,
  ),
  DemoScenario(
    id: 'S5',
    summary: '30 · declines sexual-health Qs',
    expected: 'Expected: Respects "declined"',
    redFlag: false,
  ),
  DemoScenario(
    id: 'S6',
    summary: '29 · missed period + pain + dizzy',
    expected: 'Expected: R1 interrupt',
    redFlag: true,
  ),
  DemoScenario(
    id: 'S7',
    summary: '38 · soaking a pad per hour',
    expected: 'Expected: R2 interrupt',
    redFlag: true,
  ),
  DemoScenario(
    id: 'S8',
    summary: '24 · fever + pelvic pain',
    expected: 'Expected: R3 interrupt',
    redFlag: true,
  ),
  DemoScenario(
    id: 'S9',
    summary: '33 · postpartum headache',
    expected: 'Expected: R4 interrupt',
    redFlag: true,
  ),
  DemoScenario(
    id: 'S10',
    summary: '41 · self-harm thoughts',
    expected: 'Expected: R5 interrupt, 988',
    redFlag: true,
  ),
];

/// The scenario run outlasted the client timeout or the proxy (504). The
/// server replays turns synchronously, so it may still finish the run.
bool isRunTimeout(AppFailure failure) => switch (failure) {
  NetworkFailure(message: 'timeout') => true,
  ServerFailure(statusCode: 504) => true,
  _ => false,
};
