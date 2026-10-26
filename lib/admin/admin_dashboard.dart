import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_ui.dart';

class _Stats {
  final int customers;
  final Map<String, int> segments;
  final int orders;
  final int revenue;
  final int revenue7d;
  final int openComplaints;
  final int claims;
  final List<_VoucherStat> topVouchers;
  final List<Map<String, dynamic>> recentOrders;

  _Stats({
    required this.customers,
    required this.segments,
    required this.orders,
    required this.revenue,
    required this.revenue7d,
    required this.openComplaints,
    required this.claims,
    required this.topVouchers,
    required this.recentOrders,
  });
}

class _VoucherStat {
  final String title;
  int claimed = 0;
  int used = 0;
  _VoucherStat(this.title);
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_Stats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Stats> _load() async {
    final db = Supabase.instance.client;

    final custRows = await db
        .from('customer_segments')
        .select('id, segment')
        .neq('role', 'admin');
    final orderRows = await db
        .from('orders')
        .select('id, user_id, total, created_at, voucher_title, product_name')
        .order('created_at', ascending: false);
    final complaintRows = await db.from('complaints').select('status');
    final uvRows = await db
        .from('user_vouchers')
        .select('voucher_id, used_at, vouchers(title)');
    final profRows = await db.from('profiles').select('id, full_name');

    final segments = <String, int>{
      'Baru': 0,
      'Aktif': 0,
      'Setia': 0,
      'Tidur': 0,
    };
    for (final r in custRows) {
      final s = (r['segment'] ?? 'Aktif') as String;
      segments[s] = (segments[s] ?? 0) + 1;
    }

    var revenue = 0;
    var revenue7d = 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    for (final o in orderRows) {
      final t = ((o['total'] ?? 0) as num).toInt();
      revenue += t;
      final at = DateTime.parse(o['created_at'] as String);
      if (at.isAfter(weekAgo)) revenue7d += t;
    }

    final names = <String, String>{
      for (final p in profRows)
        p['id'] as String: ((p['full_name'] ?? '-') as String),
    };
    final recent = <Map<String, dynamic>>[];
    for (final o in orderRows.take(5)) {
      final m = Map<String, dynamic>.from(o);
      m['customer_name'] = names[o['user_id']] ?? '-';
      recent.add(m);
    }

    final open = complaintRows.where((c) => c['status'] != 'Selesai').length;

    final byVoucher = <String, _VoucherStat>{};
    for (final u in uvRows) {
      final v = u['vouchers'];
      if (v == null) continue;
      final id = u['voucher_id'] as String;
      final st =
      byVoucher.putIfAbsent(id, () => _VoucherStat((v['title'] ?? '-') as String));
      st.claimed++;
      if (u['used_at'] != null) st.used++;
    }
    final top = byVoucher.values.toList()
      ..sort((a, b) => b.claimed.compareTo(a.claimed));

    return _Stats(
      customers: custRows.length,
      segments: segments,
      orders: orderRows.length,
      revenue: revenue,
      revenue7d: revenue7d,
      openComplaints: open,
      claims: uvRows.length,
      topVouchers: top.take(5).toList(),
      recentOrders: recent,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Widget _kpi(IconData icon, Color color, String label, String value) {
    return Expanded(
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(_Stats s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total penjualan',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(s.revenue),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up,
                    size: 16, color: AppColors.yellow),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${rupiah(s.revenue7d)} dalam 7 hari terakhir',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.yellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segments(_Stats s) {
    final total = s.segments.values.fold<int>(0, (a, b) => a + b);
    return Panel(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: total == 0
                  ? Container(color: AppColors.line)
                  : Row(
                children: [
                  for (final e in s.segments.entries)
                    if (e.value > 0)
                      Expanded(
                        flex: e.value,
                        child: Container(color: segColor(e.key)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final e in s.segments.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: segColor(e.key), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(e.key),
                  const Spacer(),
                  Text('${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${total == 0 ? 0 : (e.value * 100 / total).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _vouchers(_Stats s) {
    if (s.topVouchers.isEmpty) {
      return const Panel(
        child: Text('Belum ada voucher yang diklaim',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return Panel(
      child: Column(
        children: [
          for (var i = 0; i < s.topVouchers.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(s.topVouchers[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${s.topVouchers[i].used}/${s.topVouchers[i].claimed} dipakai',
                  style:
                  const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.topVouchers[i].claimed == 0
                    ? 0
                    : s.topVouchers[i].used / s.topVouchers[i].claimed,
                minHeight: 6,
                color: AppColors.blue,
                backgroundColor: AppColors.line,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orders(_Stats s) {
    if (s.recentOrders.isEmpty) {
      return const Panel(
        child: Text('Belum ada pesanan',
            style: TextStyle(color: AppColors.muted)),
      );
    }
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < s.recentOrders.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            Builder(builder: (context) {
              final o = s.recentOrders[i];
              final vt = o['voucher_title'];
              final name = (o['customer_name'] ?? '-') as String;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.blue.withValues(alpha: 0.1),
                      child: Text(initialOf(name),
                          style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${tanggal(DateTime.parse(o['created_at'] as String))}'
                                '${vt != null ? ' • $vt' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(rupiah((o['total'] ?? 0) as num),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_Stats>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return LoadError(snap.error, _refresh);
          }
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _hero(s),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpi(Icons.people_outline, AppColors.blue, 'Pelanggan',
                      '${s.customers}'),
                  const SizedBox(width: 12),
                  _kpi(Icons.receipt_long_outlined, AppColors.blue, 'Pesanan',
                      '${s.orders}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _kpi(Icons.local_offer_outlined, const Color(0xFFC99700),
                      'Voucher diklaim', '${s.claims}'),
                  const SizedBox(width: 12),
                  _kpi(
                    Icons.report_outlined,
                    s.openComplaints > 0
                        ? const Color(0xFFE07B00)
                        : const Color(0xFF1E9E5A),
                    'Keluhan terbuka',
                    '${s.openComplaints}',
                  ),
                ],
              ),
              const SectionTitle('Pelanggan per segmen'),
              _segments(s),
              const SectionTitle('Voucher terpopuler'),
              _vouchers(s),
              const SectionTitle('Pesanan terbaru'),
              _orders(s),
            ],
          );
        },
      ),
    );
  }
}