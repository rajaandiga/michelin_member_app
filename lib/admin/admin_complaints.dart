import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_ui.dart';

const kStatuses = ['Baru', 'Diproses', 'Selesai'];

String _tgl(dynamic iso) {
  if (iso == null) return '-';
  final d = DateTime.parse(iso.toString()).toLocal();
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
}

class AdminComplaintsPage extends StatefulWidget {
  const AdminComplaintsPage({super.key});

  @override
  State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
}

class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
  static const _filters = ['Semua', 'Baru', 'Diproses', 'Selesai'];
  String _filter = 'Semua';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('complaints')
        .select()
        .order('created_at', ascending: false);
    final profs =
    await client.from('profiles').select('id, full_name, member_no');
    final byId = <String, Map<String, dynamic>>{
      for (final p in profs) p['id'] as String: Map<String, dynamic>.from(p),
    };
    final list = <Map<String, dynamic>>[];
    for (final r in rows) {
      final m = Map<String, dynamic>.from(r);
      m['customer'] = byId[m['user_id']];
      list.add(m);
    }
    if (_filter == 'Semua') return list;
    return list.where((r) => r['status'] == _filter).toList();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _open(Map<String, dynamic> r) async {
    final ctrl = TextEditingController(text: (r['resolution'] ?? '') as String);
    String status = (r['status'] ?? 'Baru') as String;
    if (!kStatuses.contains(status)) status = 'Baru';

    final saved = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        String? err;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['subject'] ?? '-',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      '${r['customer']?['full_name'] ?? '-'} • ${_tgl(r['created_at'])}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(r['message'] ?? ''),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: inputDeco('Status'),
                    items: kStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setSheet(() => status = v ?? status),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrl,
                    maxLines: 4,
                    decoration: inputDeco('Tanggapan untuk pelanggan').copyWith(errorText: err),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (status == 'Selesai' && ctrl.text.trim().isEmpty) {
                          setSheet(() => err = 'Isi tanggapan dulu');
                          return;
                        }
                        Navigator.pop(ctx, {
                          'status': status,
                          'resolution': ctrl.text.trim(),
                        });
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (saved == null) return;
    try {
      await Supabase.instance.client.from('complaints').update({
        'status': saved['status'],
        'resolution':
        saved['resolution']!.isEmpty ? null : saved['resolution'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', r['id']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      return;
    }
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilterBar(
          options: _filters,
          selected: _filter,
          onSelected: (f) {
            _filter = f;
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
                final rows = snap.data ?? [];
                if (rows.isEmpty) {
                  return ListView(children: const [
                    SizedBox(height: 60),
                    EmptyState(Icons.check_circle_outline, 'Tidak ada keluhan'),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    final st = (r['status'] ?? 'Baru') as String;
                    final replied = (r['resolution'] ?? '').toString().isNotEmpty;
                    return Panel(
                      onTap: () => _open(r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(r['subject'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Pill(st, statusColor(st)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r['customer']?['full_name'] ?? '-'} • ${_tgl(r['created_at'])}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${r['message'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (replied) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.reply,
                                    size: 14, color: AppColors.blue),
                                SizedBox(width: 4),
                                Text('Sudah ditanggapi',
                                    style: TextStyle(
                                        color: AppColors.blue, fontSize: 12)),
                              ],
                            ),
                          ],
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