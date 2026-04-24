import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'profile_model.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  Stream<UserProfile> streamProfile() {
    final doc = _db.collection('users').doc(uid);
    return doc.snapshots().map((s) => UserProfile.fromMap(uid, s.data()));
  }

  Future<UserProfile?> getProfile() async {
    final s = await _db.collection('users').doc(uid).get();
    if (!s.exists) return null;
    return UserProfile.fromMap(uid, s.data());
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await _db.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String> uploadAvatar(File file) async {
    final ref = _storage.ref().child('profileImages/$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
