import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';
import 'login_screen.dart';

/// Profil: nama, kelas, email (dari Firestore), riwayat peminjaman, Logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  final InventoryService _service = InventoryService();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  Stream<List<Map<String, dynamic>>>? _borrowStream;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _userStream = _auth.userStream(user.uid);
      _borrowStream = _service.borrowingsStream(user.uid);
    }
  }

  //pop up konfirmasi logout
  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final ya = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.borrowed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ya != true) return;

    await _auth.logout();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _info(IconData ikon, String label, String nilai, Color warna) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: warna, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  nilai,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null || _userStream == null) {
      return const Scaffold(body: Center(child: Text('Belum login')));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat profil.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final nama = (data['name'] ?? '-').toString();
          final kelas = (data['kelas'] ?? '-').toString();
          final email = (data['email'] ?? user.email ?? '-').toString();
          final role = data['role'] == AuthService.ownerRole ? 'Owner' : 'User';
          final foto = (data['foto'] ?? '').toString();
          final inisial = nama.isNotEmpty && nama != '-'
              ? nama.characters.first.toUpperCase()
              : '?';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 28,
                  24,
                  32,
                ),
                decoration: const BoxDecoration(
                  gradient: appGradient,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.accent,
                        foregroundImage: foto.isNotEmpty
                            ? NetworkImage(foto)
                            : null,
                        onForegroundImageError: foto.isNotEmpty
                            ? (error, stack) {}
                            : null,
                        child: Text(
                          inisial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      nama,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info(
                          Icons.person_rounded,
                          'Nama',
                          nama,
                          AppColors.primary,
                        ),
                        _info(
                          Icons.school_rounded,
                          'Kelas',
                          kelas,
                          AppColors.roseDark,
                        ),
                        _info(
                          Icons.email_rounded,
                          'Email',
                          email,
                          AppColors.accent,
                        ),
                        _info(
                          Icons.badge_rounded,
                          'Tipe Akun',
                          role,
                          AppColors.primary,
                        ),
                        if (role == 'User') ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Riwayat Pinjam & Kembali',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _borrowStream,
                            builder: (context, snap) {
                              final list = snap.data ?? [];
                              if (list.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'Belum ada riwayat peminjaman',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                );
                              }
                              return Column(
                                children: list
                                    .map(
                                      (b) => Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.history_rounded,
                                              color: AppColors.accent,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    (b['item_name'] ?? '-')
                                                        .toString(),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.text,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Dipinjam: ${formatTanggal(b['borrow_date'])}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.muted,
                                                    ),
                                                  ),
                                                  Text(
                                                    b['return_date'] == null
                                                        ? 'Belum dikembalikan'
                                                        : 'Dikembalikan: ${formatTanggal(b['return_date'])}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          b['return_date'] ==
                                                              null
                                                          ? const Color.fromARGB(255, 189, 56, 56)
                                                          : AppColors.muted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.borrowed,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
