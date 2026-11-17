import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Mengurus Firebase Authentication dan profil pengguna di Firestore.
class AuthService {
  static const String userRole = 'user';
  static const String ownerRole = 'owner';
  static const String ownerAdminCode = '301210';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Register: buat akun lalu simpan profil ke users/{uid}.
  Future<void> register({
    required String name,
    required String kelas,
    required String email,
    required String password,
    required String role,
    String? adminCode,
  }) async {
    if (role != userRole && role != ownerRole) {
      throw ArgumentError.value(role, 'role', 'Role tidak valid.');
    }
    if (role == ownerRole && adminCode != ownerAdminCode) {
      throw StateError('Kode admin owner tidak valid.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    await _db.collection('users').doc(uid).set({
      'user_id': uid,
      'name': name.trim(),
      'email': email.trim(),
      'kelas': kelas.trim(),
      'role': role,
      'created_at': FieldValue.serverTimestamp(),
      'foto':
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name.trim())}&background=DE7272&color=fff&size=256',
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Data profil pengguna (real-time).
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Mengubah kode error Firebase menjadi pesan bahasa Indonesia.
  static String pesanError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan ($code).';
    }
  }
}
