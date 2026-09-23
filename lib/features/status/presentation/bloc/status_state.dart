import 'package:equatable/equatable.dart';
import '../../domain/entities/user_status_group.dart';

abstract class StatusState extends Equatable {
  const StatusState();

  @override
  List<Object?> get props => [];
}

class StatusInitial extends StatusState {}

class StatusLoading extends StatusState {}

class StatusLoaded extends StatusState {
  final UserStatusGroup? myStatus;
  final List<UserStatusGroup> recentStatuses; // Has unviewed items
  final List<UserStatusGroup> viewedStatuses; // All items already viewed

  const StatusLoaded({
    this.myStatus,
    this.recentStatuses = const [],
    this.viewedStatuses = const [],
  });

  @override
  List<Object?> get props => [myStatus, recentStatuses, viewedStatuses];
}

class StatusActionSuccess extends StatusState {
  final String message;

  const StatusActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class StatusError extends StatusState {
  final String message;

  const StatusError(this.message);

  @override
  List<Object?> get props => [message];
}
