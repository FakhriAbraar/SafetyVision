import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import Firestore

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Ambil Role User dari Firestore
  static Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] ?? 'user';
      }
    } catch (e) {
      // Abaikan error, kembalikan default 'user'
    }
    return 'user'; // Default role jika dokumen tidak ditemukan
  }

  static Future<void> updateLastHistoryOpened() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'lastHistoryOpened': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateLastNotifOpened() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'lastNotifOpened': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Login dengan email & password
  /// Melempar [FirebaseAuthException] jika gagal
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Daftar akun baru dengan email & password dan simpan ke Firestore
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

    // SIMPAN DATA KE FIRESTORE (Pendekatan 1)
    if (credential.user != null) {
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': 'user', // <--- Default role saat baru daftar
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

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