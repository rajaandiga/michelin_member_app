import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../services/api.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  final _passFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      toast(context, 'Email dan password wajib diisi');
      return;
    }
    setState(() => _loading = true);
    try {
      await Api.signIn(_email.text.trim(), _pass.text);
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) toast(context, 'Gagal masuk. Cek koneksi internet.');
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _ring(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: alpha),
          width: 16,
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navy, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Stack(
                children: [
                  Positioned(right: -80, top: -60, child: _ring(260, 0.05)),
                  Positioned(right: 10, bottom: -50, child: _ring(140, 0.06)),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 6, color: AppColors.yellow),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        28, MediaQuery.of(context).padding.top + 48, 24, 64),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tire_repair,
                              size: 32, color: AppColors.navy),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'MICHELIN',
                          style: TextStyle(
                            color: AppColors.yellow,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'MyXpert',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kartu member, poin, dan layanan ban dalam satu aplikasi.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Panel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat datang kembali',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text('Masuk untuk melihat poin dan riwayat belanja.',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passFocus.requestFocus(),
                        decoration:
                        inputDeco('Email', icon: Icons.mail_outline),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _pass,
                        focusNode: _passFocus,
                        obscureText: _hide,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_loading) _login();
                        },
                        decoration:
                        inputDeco('Password', icon: Icons.lock_outline)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _hide ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun?',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                            child: const Text('Daftar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _feature(Icons.stars_rounded, 'Kumpulkan\npoin'),
                  _feature(Icons.local_offer_outlined, 'Tukar\nvoucher'),
                  _feature(Icons.receipt_long_outlined, 'Riwayat\nbelanja'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}