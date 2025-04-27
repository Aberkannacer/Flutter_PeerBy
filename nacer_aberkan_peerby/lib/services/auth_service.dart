import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // 🔥 Signup methode
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 🔥 Login methode
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 🔥 Logout methode
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // 🔥 Stream om te luisteren of user ingelogd is
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
