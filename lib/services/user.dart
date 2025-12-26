import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);

    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'google',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),

      'role': 'resident',
      'isActive': false,
    });
  }

  Future<void> updateLastLogin(User user) async {
    await _db.collection('users').doc(user.uid).set(
      {'lastLoginAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<bool> isUserActive(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['isActive'] as bool?) ?? false;
  }

  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return (data?['role'] as bool?) ?? false;
  }
}
