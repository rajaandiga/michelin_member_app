import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/member_card.dart';
import '../card/member_card_screen.dart';
import 'riwayat_screen.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  late Future<Profile> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.myProfile();
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

  Widget _badge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _stat(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        _badge(icon, color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  const TextStyle(color: AppColors.muted, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
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
          final target = p.nextTarget;
          final progress =
          target == null ? 1.0 : (p.totalSpent / target).clamp(0.0, 1.0);
          final initial = p.displayName.substring(0, 1).toUpperCase();
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.blue,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat datang,',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          Text(
                            p.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MemberCardScreen(profile: p),
                  )),
                  child: MemberCardFront(profile: p),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text('Ketuk kartu untuk melihat detail',
                      style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.nextTier == null
                                ? 'Tier tertinggi: ${p.tier}'
                                : 'Menuju ${p.nextTier}',
                            style:
                            const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.tier(p.nextTier ?? p.tier),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: AppColors.line,
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        target == null
                            ? 'Terima kasih sudah jadi member setia.'
                            : 'Belanja ${rupiah(target - p.totalSpent)} lagi untuk naik ke ${p.nextTier}.',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Panel(
                  child: Column(
                    children: [
                      _stat(Icons.stars_rounded, const Color(0xFFC99700),
                          'Poin kamu', '${p.points}'),
                      const Divider(height: 24, color: AppColors.line),
                      _stat(Icons.account_balance_wallet_outlined,
                          AppColors.blue, 'Total belanja', rupiah(p.totalSpent)),
                      const Divider(height: 24, color: AppColors.line),
                      Row(
                        children: [
                          Expanded(
                            child: _stat(Icons.storefront_outlined,
                                AppColors.blue, 'Kunjungan', '${p.visitCount}'),
                          ),
                          Expanded(
                            child: _stat(Icons.build_circle_outlined,
                                AppColors.blue, 'Kunjungan jasa',
                                '${p.serviceVisitCount}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          p.lastVisitAt == null
                              ? 'Belum ada kunjungan. Ban awet kalau dirawat, cek jasa di tab Katalog.'
                              : 'Terakhir berkunjung ${tanggal(p.lastVisitAt!)}. Rotasi dan balancing rutin menjaga ban tetap awet.',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Panel(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RiwayatScreen(),
                  )),
                  child: Row(
                    children: [
                      _badge(Icons.receipt_long_outlined, AppColors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Riwayat belanja',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
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