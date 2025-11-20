import 'package:cloud_firestore/cloud_firestore.dart';

class SignalingFirebaseService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> createRoomAndSendOffer(Map<String, dynamic> offer) async {
    try {
      final DocumentReference roomRef = _firestore.collection('rooms').doc();

      await roomRef.set({'sdp': offer});

      return roomRef.id;
    } catch (e) {
      rethrow;
    }
  }
}
