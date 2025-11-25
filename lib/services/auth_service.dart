import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      return AuthResult.failure('Sign in failed, try again');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      return AuthResult.failure('Sign up failed, try again');
    }
  }

  Future<AuthResult> signInAnon() async {
    try {
      await _auth.signInAnonymously();
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      return AuthResult.failure('Anonymous sign-in failed');
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email';
      case 'weak-password':
        return 'Password too weak';
      default:
        return e.message ?? 'Authentication error';
    }
  }
}

class AuthResult {
  final bool ok;
  final String? message;

  const AuthResult({
    required this.ok,
    this.message,
  });

  const AuthResult.success() : this(ok: true);
  const AuthResult.failure(String message) : this(ok: false, message: message);
}
