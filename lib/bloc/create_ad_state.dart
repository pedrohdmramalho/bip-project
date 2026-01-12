part of 'create_ad_bloc.dart';

enum CreateAdStatus { initial, loading, success, failure }

class CreateAdState extends Equatable {
  final String title;
  final String description;
  final CreateAdStatus status;
  final String? errorMessage;

  const CreateAdState({
    this.title = '',
    this.description = '',
    this.status = CreateAdStatus.initial,
    this.errorMessage,
  });

  CreateAdState copyWith({
    String? title,
    String? description,
    CreateAdStatus? status,
    String? errorMessage,
  }) {
    return CreateAdState(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [title, description, status, errorMessage];
}
