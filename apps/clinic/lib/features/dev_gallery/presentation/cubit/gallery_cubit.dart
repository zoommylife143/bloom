import 'package:bloc/bloc.dart';
import 'package:bloom_ui/bloom_ui.dart';

/// Holds the DecisionBar demo decision on the gallery page. Dev only.
class GalleryCubit extends Cubit<BloomDecision?> {
  new() : super(null);

  void decide(BloomDecision decision) {
    if (state != null) return;
    emit(decision);
  }

  void reset() => emit(null);
}
