import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_ui.dart';

class _Detail {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> vouchers;
  final List<Map<String, dynamic>> complaints;
  _Detail(this.orders, this.vouchers, this.complaints);
}

class AdminCustomerDetailPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  const AdminCustomerDetailPage({super.key, required this.customer});

  @override
  State<AdminCustomerDetailPage> createState() =>
      _AdminCustomerDetailPageState();
}

class _AdminCustomerDetailPageState extends State<AdminCustomerDetailPage> {
  late Future<_Detail> _future;

  String get _id => widget.customer['id'] as String;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Detail> _load() async {
    final db = Supabase.instance.client;
    final orders = await db
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', _id)
        .order('created_at', ascending: false);
    final vouchers = await db
        .from('user_vouchers')
        .select('*, vouchers(title)')
        .eq('user_id', _id)
        .order('claimed_at', ascending: false);
    final complaints = await db
        .from('complaints')
        .select()
        .eq('user_id', _id)
        .order('created_at', ascending: false);
    return _Detail(
      List<Map<String, dynamic>>.from(orders),
      List<Map<String, dynamic>>.from(vouchers),
      List<Map<String, dynamic>>.from(complaints),
    );
  }

  String _dt(dynamic iso) =>
      iso == null ? '-' : tanggal(DateTime.parse(iso.toString()));

  String _items(Map<String, dynamic> o) {
    final items = (o['order_items'] as List? ?? []);
    if (items.isEmpty) {
      // Pesanan tahap 1 belum punya order_items
      return '${o['product_name'] ?? '-'} x${o['qty'] ?? 1}';
    }
    return items
        .map((e) => '${e['product_name']} x${e['qty']}')
        .join(', ');
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(k,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
        Expanded(
          child: Text(v,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _row(String title, String sub, Widget trailing) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );

  Widget _section(String title, List<Widget> children, String empty) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(const Divider(height: 1, color: AppColors.line));
      spaced.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: children.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(empty,
                style: const TextStyle(color: AppColors.muted)),
          )
              : Column(children: spaced),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final seg = (c['segment'] ?? 'Aktif') as String;
    final tier = (c['tier'] ?? 'Bronze') as String;
    final name = (c['full_name'] ?? 'Pelanggan') as String;
    final tc = AppColors.tier(tier);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail pelanggan')),
      body: FutureBuilder<_Detail>(
        future: _future,
        builder: (context, snap) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Panel(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tc.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(initialOf(name),
                          style: TextStyle(
                              color: tc,
                              fontWeight: FontWeight.w700,
                              fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('${c['member_no'] ?? '-'}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Pill(tier, tc),
                              Pill(seg, segColor(seg)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat('Poin', '${c['points'] ?? 0}', Icons.stars_rounded),
                  const SizedBox(width: 12),
                  _stat('Total belanja', rupiah((c['total_spent'] ?? 0) as num),
                      Icons.account_balance_wallet_outlined),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat('Kunjungan', '${c['visit_count'] ?? 0}',
                      Icons.storefront_outlined),
                  const SizedBox(width: 12),
                  _stat('Kunjungan jasa', '${c['service_visit_count'] ?? 0}',
                      Icons.build_circle_outlined),
                ],
              ),
              const SizedBox(height: 12),
              Panel(
                child: Column(
                  children: [
                    _kv('Telepon', '${c['phone'] ?? '-'}'),
                    _kv('Kunjungan terakhir', _dt(c['last_visit_at'])),
                    _kv('Bergabung', _dt(c['created_at'])),
                  ],
                ),
              ),
              if (snap.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat: ${snap.error}',
                      style: const TextStyle(color: AppColors.muted)),
                )
              else ...[
                  _section(
                    'Riwayat pesanan (${snap.data!.orders.length})',
                    snap.data!.orders.map((o) {
                      final disc = ((o['discount'] ?? 0) as num).toInt();
                      final vt = o['voucher_title'];
                      return _row(
                        _items(o),
                        '${_dt(o['created_at'])}'
                            '${vt != null ? ' • voucher $vt (-${rupiah(disc)})' : ''}'
                            '${o['has_service'] == true ? ' • ada jasa' : ''}',
                        Text(rupiah((o['total'] ?? 0) as num),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      );
                    }).toList(),
                    'Belum ada pesanan',
                  ),
                  _section(
                    'Voucher (${snap.data!.vouchers.length})',
                    snap.data!.vouchers.map((u) {
                      final used = u['used_at'] != null;
                      return _row(
                        '${u['vouchers']?['title'] ?? '-'}',
                        'Diklaim ${_dt(u['claimed_at'])}'
                            '${used ? ' • dipakai ${_dt(u['used_at'])}' : ''}',
                        Pill(
                          used ? 'Terpakai' : 'Belum dipakai',
                          used
                              ? const Color(0xFF8A93A6)
                              : const Color(0xFF1E9E5A),
                        ),
                      );
                    }).toList(),
                    'Belum mengklaim voucher',
                  ),
                  _section(
                    'Keluhan (${snap.data!.complaints.length})',
                    snap.data!.complaints.map((k) {
                      final st = '${k['status'] ?? 'Baru'}';
                      return _row(
                        '${k['subject'] ?? '-'}',
                        _dt(k['created_at']),
                        Pill(st, statusColor(st)),
                      );
                    }).toList(),
                    'Tidak ada keluhan',
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}