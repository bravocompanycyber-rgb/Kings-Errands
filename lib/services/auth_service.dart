import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': fullName,
          'email': email,
          'phoneNumber': phone,
          'role': 'customer',
          'isBlocked': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Initialize wallet
        await _firestore.collection('wallets').doc(user.uid).set({
          'balance': 0.0,
        });
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Invalid email or password. Please try again.';
      } else if (e.code == 'user-disabled') {
        throw 'This account has been disabled. Please contact support.';
      } else if (e.code == 'too-many-requests') {
        throw 'Too many attempts. Please try again later.';
      } else {
        throw 'An error occurred. Please try again.';
      }
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      // Check if email exists in our Firestore users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'This email is not registered in our system.';
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw 'Please enter a valid email address.';
      } else if (e.code == 'user-not-found') {
        throw 'This email is not registered in our system.';
      } else {
        throw 'Failed to send reset email. Please try again later.';
      }
    } catch (e) {
      if (e is String) rethrow;
      throw 'An error occurred while trying to reset your password.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .withConverter<AppUser>(
            fromFirestore: AppUser.fromFirestore,
            toFirestore: (user, _) => user.toFirestore(),
          )
          .get();
      return doc.data();
    }
    return null;
  }

  Stream<AppUser?> get currentUserDataStream {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .withConverter<AppUser>(
          fromFirestore: AppUser.fromFirestore,
          toFirestore: (user, _) => user.toFirestore(),
        )
        .snapshots()
        .map((doc) => doc.data());
  }
}
