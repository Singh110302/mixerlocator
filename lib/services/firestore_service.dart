import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  Stream<List<UserModel>> getAllFriends() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> updateLocation(UserModel user) async {
    await _users.doc(user.id).set(user.toJson());
  }
}
