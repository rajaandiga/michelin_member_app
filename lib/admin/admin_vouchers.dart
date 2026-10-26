import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_customers.dart' show rp;
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_ui.dart';

const _tiers = ['Bronze', 'Silver', 'Gold', 'Platinum'];
const _segs = ['Baru', 'Aktif', 'Setia', 'Tidur'];

class AdminVouchersPage extends StatefulWidget {
  const AdminVouchersPage({super.key});

  @override
  State<AdminVouchersPage> createState() => _AdminVouchersPageState();
}

class _AdminVouchersPageState extends State<AdminVouchersPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client
        .from('vouchers')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _msg(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _edit(Map<String, dynamic>? v) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _VoucherForm(initial: v),
    );
    if (result == null) return;
    try {
      final t = Supabase.instance.client.from('vouchers');
      if (v == null) {
        await t.insert(result);
      } else {
        await t.update(result).eq('id', v['id']);
      }
    } catch (e) {
      _msg('Gagal menyimpan: $e');
      return;
    }
    _reload();
  }

  Future<void> _toggle(Map<String, dynamic> v, bool on) async {
    try {
      await Supabase.instance.client
          .from('vouchers')
          .update({'active': on}).eq('id', v['id']);
    } catch (e) {
      _msg('Gagal mengubah: $e');
    }
    _reload();
  }

  String _nilai(Map<String, dynamic> v) {
    if (v['kind'] == 'persen') {
      final mx = v['max_discount'];
      return '${v['value']}%${mx != null ? ' (maks ${rp(mx as num)})' : ''}';
    }
    return rp((v['value'] ?? 0) as num);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: const Text('Voucher'),
      ),
      body: RefreshIndicator(
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
                EmptyState(Icons.local_offer_outlined, 'Belum ada voucher'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final v = rows[i];
                final on = v['active'] == true;
                final pc = v['points_cost'];
                final tags = <String>[
                  if (v['min_tier'] != null) 'Tier ${v['min_tier']}+',
                  if (v['target_segment'] != null)
                    'Segmen ${v['target_segment']}',
                  if (v['only_service'] == true) 'Khusus jasa',
                ];
                return Opacity(
                  opacity: on ? 1 : 0.55,
                  child: Panel(
                    onTap: () => _edit(v),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                v['kind'] == 'persen'
                                    ? Icons.percent
                                    : Icons.payments_outlined,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v['title'] ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    '${_nilai(v)} • ${pc == null ? 'Gratis' : '$pc poin'}',
                                    style: const TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: on,
                              activeThumbColor: AppColors.navy,
                              activeTrackColor: AppColors.yellow,
                              onChanged: (x) => _toggle(v, x),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Minimal belanja ${rp((v['min_spend'] ?? 0) as num)}',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in tags) Pill(t, AppColors.blue),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VoucherForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _VoucherForm({this.initial});

  @override
  State<_VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<_VoucherForm> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _value;
  late final TextEditingController _maxDisc;
  late final TextEditingController _minSpend;
  late final TextEditingController _points;
  late String _kind;
  String? _minTier;
  String? _segment;
  late bool _onlyService;
  late bool _active;
  DateTime? _expires;
  String? _err;

  @override
  void initState() {
    super.initState();
    final v = widget.initial ?? {};
    _title = TextEditingController(text: (v['title'] ?? '') as String);
    _desc = TextEditingController(text: (v['description'] ?? '') as String);
    _value = TextEditingController(text: '${v['value'] ?? ''}');
    _maxDisc = TextEditingController(text: '${v['max_discount'] ?? ''}');
    _minSpend = TextEditingController(text: '${v['min_spend'] ?? 0}');
    _points = TextEditingController(text: '${v['points_cost'] ?? ''}');
    _kind = (v['kind'] ?? 'nominal') as String;
    _minTier = v['min_tier'] as String?;
    _segment = v['target_segment'] as String?;
    _onlyService = v['only_service'] == true;
    _active = v['active'] != false;
    final e = v['expires_at'];
    _expires = e == null ? null : DateTime.parse(e.toString()).toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _value.dispose();
    _maxDisc.dispose();
    _minSpend.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expires ?? now.add(const Duration(days: 30)),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (d != null) setState(() => _expires = d);
  }

  void _save() {
    final value = int.tryParse(_value.text.trim());
    final pointsText = _points.text.trim();
    final points = pointsText.isEmpty ? null : int.tryParse(pointsText);
    final minSpend = int.tryParse(_minSpend.text.trim()) ?? 0;
    final maxDisc = int.tryParse(_maxDisc.text.trim());
    if (_title.text.trim().isEmpty) {
      setState(() => _err = 'Judul wajib diisi');
      return;
    }
    if (value == null || value <= 0) {
      setState(() => _err = 'Nilai harus angka lebih dari 0');
      return;
    }
    if (_kind == 'persen' && value > 100) {
      setState(() => _err = 'Persen maksimal 100');
      return;
    }
    if (pointsText.isNotEmpty && (points == null || points <= 0)) {
      setState(() =>
      _err = 'Biaya poin harus angka lebih dari 0, atau kosongkan jika gratis');
      return;
    }
    DateTime? exp;
    if (_expires != null) {
      exp = DateTime(_expires!.year, _expires!.month, _expires!.day, 23, 59, 59);
    }
    Navigator.pop(context, {
      'title': _title.text.trim(),
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'kind': _kind,
      'value': value,
      'max_discount': _kind == 'persen' ? maxDisc : null,
      'min_spend': minSpend,
      'points_cost': points,
      'min_tier': _minTier,
      'target_segment': _segment,
      'only_service': _onlyService,
      'active': _active,
      'expires_at': exp?.toUtc().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isNew ? 'Voucher baru' : 'Ubah voucher',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: inputDeco('Judul'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: inputDeco('Deskripsi'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: inputDeco('Jenis'),
              items: const [
                DropdownMenuItem(value: 'nominal', child: Text('Nominal (Rp)')),
                DropdownMenuItem(value: 'persen', child: Text('Persen (%)')),
              ],
              onChanged: (v) => setState(() => _kind = v ?? _kind),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration:
              inputDeco(_kind == 'persen' ? 'Nilai (%)' : 'Nilai (Rp)'),
            ),
            if (_kind == 'persen') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _maxDisc,
                keyboardType: TextInputType.number,
                decoration: inputDeco('Diskon maksimal (Rp, opsional)'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _minSpend,
              keyboardType: TextInputType.number,
              decoration: inputDeco('Minimal belanja (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _points,
              keyboardType: TextInputType.number,
              decoration: inputDeco('Biaya klaim (poin, kosongkan jika gratis)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _minTier,
              decoration: inputDeco('Minimal tier'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Semua tier')),
                ..._tiers.map((t) =>
                    DropdownMenuItem<String?>(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _minTier = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _segment,
              decoration: inputDeco('Target segmen'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Semua segmen')),
                ..._segs.map((t) =>
                    DropdownMenuItem<String?>(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _segment = v),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Berlaku sampai'),
              subtitle: Text(_expires == null
                  ? 'Tanpa batas waktu'
                  : '${_expires!.day}/${_expires!.month}/${_expires!.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expires != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expires = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Khusus layanan/jasa'),
              value: _onlyService,
              onChanged: (v) => setState(() => _onlyService = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_err!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Simpan')),
            ),
          ],
        ),
      ),
    );
  }
}