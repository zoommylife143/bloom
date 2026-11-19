import 'package:bloc_test/bloc_test.dart';
import 'package:bloom_clinic/features/dev_gallery/presentation/cubit/gallery_cubit.dart';
import 'package:bloom_ui/bloom_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GalleryCubit', () {
    test('starts undecided', () {
      expect(GalleryCubit().state, isNull);
    });

    blocTest<GalleryCubit, BloomDecision?>(
      'keeps the first decision only',
      build: GalleryCubit.new,
      act: (cubit) => cubit
        ..decide(BloomDecision.edited)
        ..decide(BloomDecision.rejected),
      expect: () => [BloomDecision.edited],
    );

    blocTest<GalleryCubit, BloomDecision?>(
      'reset clears the decision',
      build: GalleryCubit.new,
      seed: () => BloomDecision.confirmed,
      act: (cubit) => cubit.reset(),
      expect: () => [null],
    );
  });
}
