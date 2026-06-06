import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream perubahan status login user
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User yang sedang login (null jika belum login)
  static User? get currentUser => _auth.currentUser;

  /// Muat ulang data user dari server (mis. memastikan displayName terbaru).
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {
      // Abaikan bila offline — pakai data yang ada.
    }
  }

  /// Login dengan email & password
  /// Melempar [AuthException] jika gagal
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Daftar akun baru dengan email & password
  static Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Simpan nama ke displayName
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Konversi FirebaseAuthException ke pesan Indonesia yang user-friendly
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar. Silakan daftar terlebih dahulu.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 8 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi dukungan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet. Periksa jaringanmu.';
      default:
        return 'Terjadi kesalahan: ${e.message ?? e.code}';
    }
  }
}