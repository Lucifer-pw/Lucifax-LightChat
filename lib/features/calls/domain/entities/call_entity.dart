import 'package:equatable/equatable.dart';

class CallEntity extends Equatable {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final List<String> participants;
  final String type; // 'voice' | 'video'
  final String status; // 'calling', 'ringing', 'connected', 'rejected', 'ended', 'busy', 'missed'
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final DateTime createdAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int duration; // in seconds

  const CallEntity({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    this.participants = const [],
    required this.type,
    required this.status,
    this.offer,
    this.answer,
    required this.createdAt,
    this.connectedAt,
    this.endedAt,
    this.duration = 0,
  });

  bool get isVideo => type == 'video';
  bool get isVoice => type == 'voice';
  bool get isConnected => status == 'connected';
  bool get isEnded => status == 'ended' || status == 'rejected' || status == 'missed' || status == 'busy';

  String getOtherUserName(String currentUserId) {
    return currentUserId == callerId ? receiverName : callerName;
  }

  String? getOtherUserPhoto(String currentUserId) {
    return currentUserId == callerId ? receiverPhoto : callerPhoto;
  }

  CallEntity copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerPhoto,
    String? receiverId,
    String? receiverName,
    String? receiverPhoto,
    List<String>? participants,
    String? type,
    String? status,
    Map<String, dynamic>? offer,
    Map<String, dynamic>? answer,
    DateTime? createdAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? duration,
  }) {
    return CallEntity(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhoto: callerPhoto ?? this.callerPhoto,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhoto: receiverPhoto ?? this.receiverPhoto,
      participants: participants ?? this.participants,
      type: type ?? this.type,
      status: status ?? this.status,
      offer: offer ?? this.offer,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
        callId,
        callerId,
        callerName,
        callerPhoto,
        receiverId,
        receiverName,
        receiverPhoto,
        participants,
        type,
        status,
        offer,
        answer,
        createdAt,
        connectedAt,
        endedAt,
        duration,
      ];
}
