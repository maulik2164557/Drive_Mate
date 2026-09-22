import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          fullName: fullName,
          email: email,
          mobileNumber: mobileNumber,
          role: role,
          kycStatus: 'Pending',
          createdAt: DateTime.now(),
        );

        await _db.collection('users').doc(user.uid).set(userModel.toMap());
        return userModel;
      }
    } catch (e) {
      print(e.toString());
      rethrow;
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // First check if user exists in Firestore with the specified role
      var userDoc = await _db.collection('users').where('email', isEqualTo: email).where('role', isEqualTo: role).get();
      
      if (userDoc.docs.isEmpty) {
        throw Exception('User with this role not found. Please register first.');
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return UserModel.fromMap(userDoc.docs.first.data());
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
