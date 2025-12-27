import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserProfile {
  final String uid;
  final String? email;
  final String displayName;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
  });
}

class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Fallback to default Firestore instance if specific databaseId fails,
  // or use instanceFor if you are sure about the database ID.
  // For debugging, let's try using the default instance first as it's the most common cause of error
  // when 'flashcard' database doesn't exist or isn't accessible.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; 
  /* 
  // Old code that might be causing issues if the 'flashcard' database doesn't exist:
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'flashcard',
  );
  */

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _userDoc(user.uid).get();
    final data = doc.data();
    final displayName = data != null && data['displayName'] is String && (data['displayName'] as String).isNotEmpty
        ? data['displayName'] as String
        : (user.displayName ?? user.email ?? '');
    final photoUrl = data != null && data['photoUrl'] is String && (data['photoUrl'] as String).isNotEmpty
        ? data['photoUrl'] as String
        : user.photoURL;
    return UserProfile(
      uid: user.uid,
      displayName: displayName,
      email: user.email,
      photoUrl: photoUrl,
    );
  }

  Future<void> createUserProfile({
    required String uid,
    required String displayName,
    required String? email,
  }) async {
    await _userDoc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': _auth.currentUser?.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await user.updateDisplayName(newName);
    await _userDoc(user.uid).set({
      'displayName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePhotoUrl(String url) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    await user.updatePhotoURL(url);
    await _userDoc(user.uid).set({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
