import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/call_entity.dart';
import '../models/call_model.dart';

abstract class CallRemoteDataSource {
  Future<String> makeCall(CallEntity call, Map<String, dynamic> offer);
  Future<void> answerCall(String callId, Map<String, dynamic> answer);
  Future<void> updateCallStatus(String callId, String status, {int? duration});
  Future<void> addCandidate(String callId, String candidateType, Map<String, dynamic> candidate);
  Stream<CallModel?> getCallStream(String callId);
  Stream<List<Map<String, dynamic>>> getCandidatesStream(String callId, String candidateType);
  Stream<List<CallModel>> getIncomingCallsStream(String currentUserId);
  Stream<List<CallModel>> getCallHistoryStream(String currentUserId);
}

class CallRemoteDataSourceImpl implements CallRemoteDataSource {
  final FirebaseFirestore _firestore;

  CallRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _callsCollection =>
      _firestore.collection(FirebaseConstants.callsCollection);

  @override
  Future<String> makeCall(CallEntity call, Map<String, dynamic> offer) async {
    try {
      final docRef = _callsCollection.doc(call.callId);
      final model = CallModel(
        callId: call.callId,
        callerId: call.callerId,
        callerName: call.callerName,
        callerPhoto: call.callerPhoto,
        receiverId: call.receiverId,
        receiverName: call.receiverName,
        receiverPhoto: call.receiverPhoto,
        participants: [call.callerId, call.receiverId],
        type: call.type,
        status: 'calling',
        offer: offer,
        createdAt: DateTime.now(),
      );

      await docRef.set(model.toMap());
      return call.callId;
    } catch (e) {
      throw ServerException('Failed to initiate call: $e');
    }
  }

  @override
  Future<void> answerCall(String callId, Map<String, dynamic> answer) async {
    try {
      await _callsCollection.doc(callId).update({
        'answer': answer,
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to answer call: $e');
    }
  }

  @override
  Future<void> updateCallStatus(String callId, String status, {int? duration}) async {
    try {
      final data = <String, dynamic>{
        'status': status,
      };

      if (status == 'ended' || status == 'rejected' || status == 'missed' || status == 'busy') {
        data['endedAt'] = FieldValue.serverTimestamp();
      }

      if (duration != null) {
        data['duration'] = duration;
      }

      await _callsCollection.doc(callId).update(data);
    } catch (e) {
      // Best-effort update, ignore if doc already deleted
    }
  }

  @override
  Future<void> addCandidate(
    String callId,
    String candidateType,
    Map<String, dynamic> candidate,
  ) async {
    try {
      await _callsCollection
          .doc(callId)
          .collection(candidateType)
          .add(candidate);
    } catch (e) {
      // Best-effort candidate addition
    }
  }

  @override
  Stream<CallModel?> getCallStream(String callId) {
    return _callsCollection.doc(callId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return CallModel.fromFirestore(snapshot);
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getCandidatesStream(
    String callId,
    String candidateType,
  ) {
    return _callsCollection
        .doc(callId)
        .collection(candidateType)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Stream<List<CallModel>> getIncomingCallsStream(String currentUserId) {
    return _callsCollection
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CallModel.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<CallModel>> getCallHistoryStream(String currentUserId) {
    // Single where query to avoid composite index requirement
    return _callsCollection
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CallModel.fromFirestore(doc))
          .toList();
      // Sort descending by createdAt in Dart memory
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
