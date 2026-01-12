import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starteu/data/repositories/project_ads_repository.dart';
import 'package:uuid/uuid.dart';

import '../data/models/project_ad.dart';

part 'create_ad_event.dart';
part 'create_ad_state.dart';

class CreateAdBloc extends Bloc<CreateAdEvent, CreateAdState> {
  final ProjectAdsRepository repo;
  final Uuid uuid;

  CreateAdBloc({
    required this.repo,
    Uuid? uuid,
  })  : uuid = uuid ?? const Uuid(),
        super(const CreateAdState()) {
    on<TitleChanged>((e, emit) => emit(state.copyWith(title: e.value)));
    on<DescriptionChanged>((e, emit) => emit(state.copyWith(description: e.value)));

    on<SubmitPressed>(_onSubmit);
  }

  Future<void> _onSubmit(SubmitPressed event, Emitter<CreateAdState> emit) async {
    if (state.title.trim().isEmpty || state.description.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Add title and description'));
      return;
    }

    emit(state.copyWith(status: CreateAdStatus.loading, errorMessage: null));

    try {
      final ad = ProjectAd(
        id: uuid.v4(),
        title: state.title.trim(),
        description: state.description.trim(),
        authorId: event.authorId,
        createdAt: DateTime.now(),
      );

      await repo.createAd(ad);

      emit(state.copyWith(status: CreateAdStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: CreateAdStatus.failure,
        errorMessage: 'Advert not added: $e',
      ));
    }
  }
}
