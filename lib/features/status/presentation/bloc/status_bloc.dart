import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_status_group.dart';
import '../../domain/usecases/create_media_status.dart';
import '../../domain/usecases/create_text_status.dart';
import '../../domain/usecases/delete_status_item.dart';
import '../../domain/usecases/get_my_status.dart';
import '../../domain/usecases/get_recent_statuses.dart';
import '../../domain/usecases/mark_status_viewed.dart';
import 'status_event.dart';
import 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final GetRecentStatuses getRecentStatuses;
  final GetMyStatus getMyStatus;
  final CreateTextStatus createTextStatus;
  final CreateMediaStatus createMediaStatus;
  final MarkStatusViewed markStatusViewed;
  final DeleteStatusItem deleteStatusItem;

  StreamSubscription? _recentStatusesSub;
  StreamSubscription? _myStatusSub;

  UserStatusGroup? _cachedMyStatus;
  List<UserStatusGroup> _cachedOtherStatuses = [];
  String? _currentUserId;

  StatusBloc({
    required this.getRecentStatuses,
    required this.getMyStatus,
    required this.createTextStatus,
    required this.createMediaStatus,
    required this.markStatusViewed,
    required this.deleteStatusItem,
  }) : super(StatusInitial()) {
    on<LoadStatusesEvent>(_onLoadStatuses);
    on<StatusUpdatedInternalEvent>(_onStatusUpdatedInternal);
    on<AddTextStatusEvent>(_onAddTextStatus);
    on<AddMediaStatusEvent>(_onAddMediaStatus);
    on<ViewStatusItemEvent>(_onViewStatusItem);
    on<DeleteStatusItemEvent>(_onDeleteStatusItem);
  }

  Future<void> _onLoadStatuses(
    LoadStatusesEvent event,
    Emitter<StatusState> emit,
  ) async {
    _currentUserId = event.userId;
    emit(StatusLoading());

    await _recentStatusesSub?.cancel();
    await _myStatusSub?.cancel();

    _myStatusSub = getMyStatus(event.userId).listen((myStatus) {
      add(StatusUpdatedInternalEvent(myStatus: myStatus));
    });

    _recentStatusesSub = getRecentStatuses(event.userId).listen((allOthers) {
      add(StatusUpdatedInternalEvent(otherStatuses: allOthers));
    });
  }

  void _onStatusUpdatedInternal(
    StatusUpdatedInternalEvent event,
    Emitter<StatusState> emit,
  ) {
    if (event.myStatus != null || (event.myStatus == null && event.otherStatuses == null)) {
      _cachedMyStatus = event.myStatus as UserStatusGroup?;
    }
    if (event.otherStatuses != null) {
      _cachedOtherStatuses = List<UserStatusGroup>.from(event.otherStatuses as List);
    }

    if (_currentUserId == null) return;

    final recent = <UserStatusGroup>[];
    final viewed = <UserStatusGroup>[];

    for (var group in _cachedOtherStatuses) {
      if (group.hasUnviewed(_currentUserId!)) {
        recent.add(group);
      } else {
        viewed.add(group);
      }
    }

    emit(StatusLoaded(
      myStatus: _cachedMyStatus,
      recentStatuses: recent,
      viewedStatuses: viewed,
    ));
  }

  Future<void> _onAddTextStatus(
    AddTextStatusEvent event,
    Emitter<StatusState> emit,
  ) async {
    final result = await createTextStatus(
      text: event.text,
      backgroundColor: event.backgroundColor,
      fontFamily: event.fontFamily,
      userId: event.userId,
      userName: event.userName,
      userPhotoUrl: event.userPhotoUrl,
    );

    result.fold(
      (failure) => emit(StatusError(failure.message)),
      (_) => emit(const StatusActionSuccess('Status updated successfully')),
    );
  }

  Future<void> _onAddMediaStatus(
    AddMediaStatusEvent event,
    Emitter<StatusState> emit,
  ) async {
    emit(StatusLoading());
    final result = await createMediaStatus(
      file: event.file,
      type: event.type,
      caption: event.caption,
      userId: event.userId,
      userName: event.userName,
      userPhotoUrl: event.userPhotoUrl,
    );

    result.fold(
      (failure) => emit(StatusError(failure.message)),
      (_) => emit(const StatusActionSuccess('Media status posted successfully')),
    );
  }

  Future<void> _onViewStatusItem(
    ViewStatusItemEvent event,
    Emitter<StatusState> emit,
  ) async {
    await markStatusViewed(
      statusOwnerId: event.statusOwnerId,
      statusItemId: event.statusItemId,
      viewerId: event.viewerId,
      viewerName: event.viewerName,
      viewerPhotoUrl: event.viewerPhotoUrl,
    );
  }

  Future<void> _onDeleteStatusItem(
    DeleteStatusItemEvent event,
    Emitter<StatusState> emit,
  ) async {
    await deleteStatusItem(
      statusOwnerId: event.statusOwnerId,
      statusItemId: event.statusItemId,
    );
  }

  @override
  Future<void> close() {
    _recentStatusesSub?.cancel();
    _myStatusSub?.cancel();
    return super.close();
  }
}
