import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class _VoucherData {
  final Profile profile;
  final List<Voucher> all;
  final List<UserVoucher> mine;
  final Set<String> claimed;
  const _VoucherData(this.profile, this.all, this.mine, this.claimed);
}

class VoucherTab extends StatefulWidget {
  const VoucherTab({super.key});

  @override
  State<VoucherTab> createState() => _VoucherTabState();
}

class _VoucherTabState extends State<VoucherTab> {
  late Future<_VoucherData> _future = _load();
  bool _claiming = false;

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

  Future<_VoucherData> _load() async {
    final p = await Api.myProfile();
    final all = await Api.vouchers();
    final mine = await Api.myVouchers();
    final claimed = await Api.claimedVoucherIds();
    return _VoucherData(p, all, mine, claimed);
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<void> _claim(Voucher v) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      await Api.claimVoucher(v.id).timeout(const Duration(seconds: 20));
      if (mounted) toast(context, 'Voucher masuk ke \"Voucher saya\"');
    } on PostgrestException catch (e) {
      if (mounted) toast(context, e.message);
    } catch (_) {
      if (mounted) {
        toast(context,
            'Koneksi lambat. Cek \"Voucher saya\" sebelum mencoba lagi.');
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );

  Widget _empty(String text) => Text(text,
      style: const TextStyle(color: AppColors.muted, fontSize: 13));

  Widget _card(Voucher v, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(v.benefit,
                      style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(v.conditions,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 10), action],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_VoucherData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return ErrorRetry(onRetry: _reload);
          }
          final d = snap.data!;
          final redeem = d.all
              .where((v) => v.pointsCost != null && v.eligibleFor(d.profile))
              .toList()
            ..sort((a, b) => a.pointsCost!.compareTo(b.pointsCost!));
          final promos = d.all
              .where((v) => v.pointsCost == null && v.eligibleFor(d.profile))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Voucher',
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Poin kamu: ${d.profile.points}',
                    style: const TextStyle(color: AppColors.muted)),
                _title('Voucher saya'),
                if (d.mine.isEmpty)
                  _empty(
                      'Belum ada voucher. Tukar poin atau klaim promo di bawah, lalu pakai saat menyelesaikan pesanan.')
                else
                  for (final uv in d.mine) _card(uv.voucher),
                _title('Tukar dengan poin'),
                if (redeem.isEmpty)
                  _empty('Belum ada voucher yang bisa ditukar.')
                else
                  for (final v in redeem)
                    _card(
                      v,
                      action: FilledButton(
                        onPressed: _claiming
                            ? null
                            : d.profile.points >= v.pointsCost!
                            ? () => _claim(v)
                            : () => toast(context,
                            'Poin kamu kurang ${v.pointsCost! - d.profile.points} lagi untuk voucher ini'),
                        style: FilledButton.styleFrom(
                          backgroundColor: d.profile.points >= v.pointsCost!
                              ? null
                              : AppColors.muted,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text('${v.pointsCost} poin'),
                      ),
                    ),
                _title('Promo untuk kamu'),
                if (promos.isEmpty)
                  _empty('Belum ada promo untuk kamu saat ini.')
                else
                  for (final v in promos)
                    _card(
                      v,
                      action: d.claimed.contains(v.id)
                          ? const Text('Sudah diklaim',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 12))
                          : FilledButton(
                        onPressed: _claiming ? null : () => _claim(v),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Klaim'),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}