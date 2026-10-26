import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_customer_detail.dart';
import 'admin_ui.dart';

String rp(num v) {
  final s = v.toStringAsFixed(0);
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  static const _segments = ['Semua', 'Baru', 'Aktif', 'Setia', 'Tidur'];
  String _segment = 'Semua';
  String _query = '';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    var q = Supabase.instance.client
        .from('customer_segments')
        .select()
        .neq('role', 'admin');
    if (_segment != 'Semua') {
      q = q.eq('segment', _segment);
    }
    final rows = await q.order('total_spent', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: inputDeco('Cari nama atau no. member',
                icon: Icons.search),
          ),
        ),
        FilterBar(
          options: _segments,
          selected: _segment,
          onSelected: (s) {
            _segment = s;
            _reload();
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return LoadError(snap.error, _reload);
                }
                final all = snap.data ?? [];
                final rows = _query.isEmpty
                    ? all
                    : all.where((r) {
                  final n = '${r['full_name'] ?? ''}'.toLowerCase();
                  final m = '${r['member_no'] ?? ''}'.toLowerCase();
                  return n.contains(_query) || m.contains(_query);
                }).toList();
                if (rows.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 60),
                      EmptyState(Icons.people_outline,
                          'Tidak ada pelanggan yang cocok'),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final seg = (r['segment'] ?? 'Aktif') as String;
                    final tier = (r['tier'] ?? 'Bronze') as String;
                    final name = (r['full_name'] ?? '-') as String;
                    final tc = AppColors.tier(tier);
                    return Panel(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminCustomerDetailPage(customer: r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: tc.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              initialOf(name),
                              style: TextStyle(
                                  color: tc,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17),
                            ),
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
                                Text('${r['member_no'] ?? '-'} • $tier',
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  rp((r['total_spent'] ?? 0) as num),
                                  style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  '${r['visit_count'] ?? 0} kunjungan • jasa ${r['service_visit_count'] ?? 0}',
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Pill(seg, segColor(seg)),
                              const SizedBox(height: 14),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.muted),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}