import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/call_entity.dart';

class CallModel extends CallEntity {
  const CallModel({
    required super.callId,
    required super.callerId,
    required super.callerName,
    super.callerPhoto,
    required super.receiverId,
    required super.receiverName,
    super.receiverPhoto,
    super.participants,
    required super.type,
    required super.status,
    super.offer,
    super.answer,
    required super.createdAt,
    super.connectedAt,
    super.endedAt,
    super.duration,
  });

  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CallModel.fromMap(data, doc.id);
  }

  factory CallModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final callerId = map['callerId'] ?? '';
    final receiverId = map['receiverId'] ?? '';
    final participantsList = (map['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [callerId, receiverId];

    return CallModel(
      callId: docId ?? map['callId'] ?? '',
      callerId: callerId,
      callerName: map['callerName'] ?? '',
      callerPhoto: map['callerPhoto'],
      receiverId: receiverId,
      receiverName: map['receiverName'] ?? '',
      receiverPhoto: map['receiverPhoto'],
      participants: participantsList,
      type: map['type'] ?? 'voice',
      status: map['status'] ?? 'calling',
      offer: map['offer'] != null ? Map<String, dynamic>.from(map['offer']) : null,
      answer: map['answer'] != null ? Map<String, dynamic>.from(map['answer']) : null,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      connectedAt: _parseDateTime(map['connectedAt']),
      endedAt: _parseDateTime(map['endedAt']),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhoto': receiverPhoto,
      'participants': participants.isNotEmpty ? participants : [callerId, receiverId],
      'type': type,
      'status': status,
      if (offer != null) 'offer': offer,
      if (answer != null) 'answer': answer,
      'createdAt': Timestamp.fromDate(createdAt),
      if (connectedAt != null) 'connectedAt': Timestamp.fromDate(connectedAt!),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
      'duration': duration,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
