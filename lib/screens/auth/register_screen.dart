import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../services/api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      toast(context, 'Nama, email, dan password wajib diisi');
      return;
    }
    if (_pass.text.length < 6) {
      toast(context, 'Password minimal 6 karakter');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await Api.signUp(
        email: _email.text.trim(),
        password: _pass.text,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      if (res.session == null) {
        // Konfirmasi email aktif di Supabase.
        toast(context, 'Akun dibuat. Cek email untuk konfirmasi, lalu masuk.');
        Navigator.of(context).pop();
      } else {
        // Sudah login, kembali ke halaman utama.
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
      return;
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) toast(context, 'Gagal mendaftar. Cek koneksi internet.');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar member')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: AppColors.navy),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Jadi member MICHELIN MyXpert dan kumpulkan poin dari setiap pembelian.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration:
                  inputDeco('Nama lengkap', icon: Icons.person_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: inputDeco('Nomor HP', icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: inputDeco('Email', icon: Icons.mail_outline),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  textInputAction: TextInputAction.done,
                  decoration:
                  inputDeco('Password (min. 6 karakter)', icon: Icons.lock_outline)
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
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}