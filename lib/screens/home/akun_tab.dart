import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../card/member_card_screen.dart';
import 'riwayat_screen.dart';

class AkunTab extends StatefulWidget {
  const AkunTab({super.key});

  @override
  State<AkunTab> createState() => _AkunTabState();
}

class _AkunTabState extends State<AkunTab> {
  late Future<Profile> _future = Api.myProfile();

  @override
  void initState() {
    super.initState();
    Api.refresh.addListener(_reload);
  }

  @override
  void dispose() {
    Api.refresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() { _future = Api.myProfile(); });
  }

  Future<void> _edit(Profile p) async {
    final name = TextEditingController(text: p.fullName);
    final phone = TextEditingController(text: p.phone ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: inputDeco('Nama lengkap')),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: inputDeco('Nomor HP'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final newName = name.text.trim();
    final newPhone = phone.text.trim();
    name.dispose();
    phone.dispose();
    if (ok != true || newName.isEmpty) return;
    try {
      await Api.updateProfile(newName, newPhone);
      Api.notifyChanged();
      if (mounted) toast(context, 'Profil disimpan');
    } catch (_) {
      if (mounted) toast(context, 'Gagal menyimpan profil');
    }
  }

  Widget _menu(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: color)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Profile>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return ErrorRetry(onRetry: _reload);
          }
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Akun',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Panel(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.blue,
                      child: Text(
                        p.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(Api.user?.email ?? '',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          if (p.phone != null && p.phone!.isNotEmpty)
                            Text(p.phone!,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _menu(Icons.edit_outlined, 'Ubah profil', () => _edit(p)),
              _menu(Icons.credit_card, 'Kartu member', () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MemberCardScreen(profile: p),
                ));
              }),
              _menu(Icons.receipt_long_outlined, 'Riwayat belanja', () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RiwayatScreen(),
                ));
              }),
              _menu(Icons.logout, 'Keluar', () => Api.signOut(),
                  color: Colors.redAccent),
            ],
          );
        },
      ),
    );
  }
}
