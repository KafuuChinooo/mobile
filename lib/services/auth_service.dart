import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_card/services/user_profile_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code} - ${e.message}"); // Log lỗi ra console
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      print("Login Generic Error: $e"); // Log lỗi chung
      return AuthResult.failure('Đăng nhập thất bại, vui lòng thử lại');
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(username);
        await UserProfileService.instance.createUserProfile(
          uid: user.uid,
          displayName: username,
          email: email,
        );
      }
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      print("SignUp Error: ${e.code} - ${e.message}");
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      print("SignUp Generic Error: $e");
      return AuthResult.failure('Đăng ký thất bại, vui lòng thử lại');
    }
  }

  Future<AuthResult> signInAnon() async {
    try {
      print("Starting anonymous sign in..."); // Bắt đầu login ẩn danh
      await _auth.signInAnonymously();
      print("Anonymous sign in success"); // Login ẩn danh thành công
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      print("Anon Error: ${e.code} - ${e.message}");
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      print("Anon Generic Error: $e");
      return AuthResult.failure('Đăng nhập ẩn danh thất bại');
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const AuthResult.success(message: 'Email đặt lại mật khẩu đã được gửi');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapError(e));
    } catch (e) {
      return AuthResult.failure('Gửi email thất bại');
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc password sai, hãy thử lại';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'invalid-email':
        return 'Vui lòng nhập email hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      default:
        return e.message ?? 'Lỗi xác thực';
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

  const AuthResult.success({String? message}) : this(ok: true, message: message);
  const AuthResult.failure(String message) : this(ok: false, message: message);
}
