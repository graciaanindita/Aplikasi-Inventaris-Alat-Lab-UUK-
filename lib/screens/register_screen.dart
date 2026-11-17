import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kelas = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _adminCode = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hide = true;
  bool _hideAdminCode = true;
  String _role = AuthService.userRole;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _kelas.dispose();
    _email.dispose();
    _password.dispose();
    _adminCode.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.register(
        name: _name.text,
        kelas: _kelas.text,
        email: _email.text,
        password: _password.text,
        role: _role,
        adminCode: _role == AuthService.ownerRole ? _adminCode.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = AuthService.pesanError(e.code));
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _wajib(String? v, String label) =>
      (v ?? '').trim().isEmpty ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(
              title: 'Buat Akun',
              subtitle: 'Pilih tipe akun untuk mendaftar',
              showBack: true,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SegmentedButton<String>(
                          expandedInsets: EdgeInsets.zero,
                          segments: const [
                            ButtonSegment(
                              value: AuthService.userRole,
                              label: Text('User'),
                              icon: Icon(Icons.person_outline_rounded),
                            ),
                            ButtonSegment(
                              value: AuthService.ownerRole,
                              label: Text('Owner'),
                              icon: Icon(Icons.admin_panel_settings_outlined),
                            ),
                          ],
                          selected: {_role},
                          onSelectionChanged: _loading
                              ? null
                              : (selection) =>
                                    setState(() => _role = selection.first),
                        ),
                        if (_role == AuthService.ownerRole) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _adminCode,
                            obscureText: _hideAdminCode,
                            keyboardType: TextInputType.number,
                            decoration: appInput(
                              'Kode Admin Owner',
                              Icons.admin_panel_settings_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _hideAdminCode
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppColors.muted,
                                ),
                                onPressed: () => setState(
                                  () => _hideAdminCode = !_hideAdminCode,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (_role != AuthService.ownerRole) return null;
                              if ((value ?? '').isEmpty) {
                                return 'Kode admin wajib diisi untuk owner';
                              }
                              if (value != AuthService.ownerAdminCode) {
                                return 'Kode admin owner tidak valid';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: appInput(
                            'Nama Lengkap',
                            Icons.person_rounded,
                          ),
                          validator: (v) => _wajib(v, 'Nama'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _kelas,
                          decoration: appInput(
                            'Kelas (contoh: XI RPL 1)',
                            Icons.school_rounded,
                          ),
                          validator: (v) => _wajib(v, 'Kelas'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: appInput('Email', Icons.email_rounded),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Email wajib diisi';
                            if (!t.contains('@') || !t.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _hide,
                          decoration: appInput(
                            'Password',
                            Icons.lock_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _hide
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.muted,
                              ),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                          ),
                          validator: (v) {
                            if ((v ?? '').isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (v!.length < 6) return 'Minimal 6 karakter';
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.borrowed.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.borrowed,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.borrowed,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sudah punya akun?',
                              style: TextStyle(color: AppColors.muted),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
