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

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> sendAnswer(String roomId, Map<String, dynamic> answer) async {
    await _firestore.collection('rooms').doc(roomId).update({'sdp': answer});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCandidatesStream({
    required String roomId,
    required bool isCaller,
  }) {
    final collectionName = isCaller ? 'guestCandidates' : 'callerCandidates';

    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection(collectionName)
        .snapshots();
  }
}
