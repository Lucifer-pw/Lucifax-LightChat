import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object?> get props => [];
}

class LoadStatusesEvent extends StatusEvent {
  final String userId;

  const LoadStatusesEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AddTextStatusEvent extends StatusEvent {
  final String text;
  final int backgroundColor;
  final String? fontFamily;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const AddTextStatusEvent({
    required this.text,
    required this.backgroundColor,
    this.fontFamily,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  List<Object?> get props => [text, backgroundColor, fontFamily, userId, userName, userPhotoUrl];
}

class AddMediaStatusEvent extends StatusEvent {
  final File file;
  final String type;
  final String? caption;
  final String userId;
  final String userName;
  final String? userPhotoUrl;

  const AddMediaStatusEvent({
    required this.file,
    required this.type,
    this.caption,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
  });

  @override
  List<Object?> get props => [file, type, caption, userId, userName, userPhotoUrl];
}

class ViewStatusItemEvent extends StatusEvent {
  final String statusOwnerId;
  final String statusItemId;
  final String viewerId;
  final String viewerName;
  final String? viewerPhotoUrl;

  const ViewStatusItemEvent({
    required this.statusOwnerId,
    required this.statusItemId,
    required this.viewerId,
    required this.viewerName,
    this.viewerPhotoUrl,
  });

  @override
  List<Object?> get props => [statusOwnerId, statusItemId, viewerId, viewerName, viewerPhotoUrl];
}

class DeleteStatusItemEvent extends StatusEvent {
  final String statusOwnerId;
  final String statusItemId;

  const DeleteStatusItemEvent({
    required this.statusOwnerId,
    required this.statusItemId,
  });

  @override
  List<Object?> get props => [statusOwnerId, statusItemId];
}

class StatusUpdatedInternalEvent extends StatusEvent {
  final dynamic myStatus;
  final dynamic otherStatuses;

  const StatusUpdatedInternalEvent({this.myStatus, this.otherStatuses});

  @override
  List<Object?> get props => [myStatus, otherStatuses];
}

