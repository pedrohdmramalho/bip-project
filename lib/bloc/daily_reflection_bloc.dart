import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/daily_reflection_repository.dart';
import 'daily_reflection_event.dart';
import 'daily_reflection_state.dart';

class DailyReflectionBloc
    extends Bloc<DailyReflectionEvent, DailyReflectionState> {
  final DailyReflectionRepository repo;

  DailyReflectionBloc({required this.repo})
      : super(const DailyReflectionState()) {
    on<MoodChanged>((e, emit) {
      emit(state.copyWith(mood: e.mood));
    });

    on<TextChanged>((e, emit) {
      emit(state.copyWith(text: e.text));
    });

    on<SubmitPressed>((e, emit) async {
      if (state.mood == null || state.text.isEmpty) return;

      emit(state.copyWith(status: DailyReflectionStatus.loading));

      try {
        await repo.saveReflection(
          mood: state.mood!,
          text: state.text,
        );

        emit(state.copyWith(status: DailyReflectionStatus.success));
      } catch (e) {
        emit(state.copyWith(
          status: DailyReflectionStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    });
  }
}