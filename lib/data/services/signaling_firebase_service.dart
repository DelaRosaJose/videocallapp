import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> createRoomAndSendOffer(
    String roomId,
    Map<String, dynamic> offer,
  ) async {
    try {
      final DocumentReference roomRef = _firestore
          .collection('rooms')
          .doc(roomId);

      await roomRef.set({'sdp': offer});

      return roomRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addIceCandidate({
    required String roomId,
    required Map<String, dynamic> candidate,
    required bool isCaller,
  }) async {
    try {
      final collectionName = isCaller ? 'callerCandidates' : 'guestCandidates';

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection(collectionName)
          .add(candidate);
    } catch (e) {
      rethrow;
    }
  }
}
