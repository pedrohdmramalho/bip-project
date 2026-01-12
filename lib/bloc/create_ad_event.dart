part of 'create_ad_bloc.dart';

sealed class CreateAdEvent extends Equatable {
  const CreateAdEvent();
  @override
  List<Object?> get props => [];
}

class TitleChanged extends CreateAdEvent {
  final String value;
  const TitleChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class DescriptionChanged extends CreateAdEvent {
  final String value;
  const DescriptionChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class SubmitPressed extends CreateAdEvent {
  final String authorId;
  const SubmitPressed({required this.authorId});
  @override
  List<Object?> get props => [authorId];
}
