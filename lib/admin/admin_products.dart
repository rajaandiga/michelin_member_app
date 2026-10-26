import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_customers.dart' show rp;
import '../core/theme.dart';
import '../core/ui.dart';
import 'admin_ui.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  static const _filters = ['Semua', 'Ban', 'Layanan'];
  String _filter = 'Semua';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await Supabase.instance.client
        .from('products')
        .select()
        .order('category')
        .order('name');
    final list = List<Map<String, dynamic>>.from(rows);
    if (_filter == 'Semua') return list;
    return list.where((p) => p['category'] == _filter).toList();
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

  Future<void> _edit(Map<String, dynamic>? p) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _ProductForm(initial: p),
    );
    if (result == null) return;
    try {
      final t = Supabase.instance.client.from('products');
      if (p == null) {
        await t.insert(result);
      } else {
        await t.update(result).eq('id', p['id']);
      }
    } catch (e) {
      _msg('Gagal menyimpan: $e');
      return;
    }
    _reload();
  }

  Future<void> _toggle(Map<String, dynamic> p, bool on) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'active': on}).eq('id', p['id']);
    } catch (e) {
      _msg('Gagal mengubah: $e');
    }
    _reload();
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
        label: const Text('Produk'),
      ),
      body: Column(
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
                      EmptyState(Icons.inventory_2_outlined, 'Belum ada produk'),
                    ]);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = rows[i];
                      final on = p['active'] == true;
                      final isService = p['category'] == 'Layanan';
                      return Opacity(
                        opacity: on ? 1 : 0.55,
                        child: Panel(
                          onTap: () => _edit(p),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isService
                                      ? Icons.build_outlined
                                      : Icons.tire_repair,
                                  color: AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['name'] ?? '-',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                      rp((p['price'] ?? 0) as num),
                                      style: const TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Pill(
                                      isService ? 'Layanan' : 'Ban',
                                      isService
                                          ? const Color(0xFFC99700)
                                          : AppColors.blue,
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: on,
                                activeThumbColor: AppColors.navy,
                                activeTrackColor: AppColors.yellow,
                                onChanged: (x) => _toggle(p, x),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _ProductForm({this.initial});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late String _category;
  late bool _active;
  String? _err;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? {};
    _name = TextEditingController(text: (p['name'] ?? '') as String);
    _desc = TextEditingController(text: (p['description'] ?? '') as String);
    _price = TextEditingController(text: '${p['price'] ?? ''}');
    _category = (p['category'] ?? 'Ban') as String;
    _active = p['active'] != false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final price = int.tryParse(_price.text.trim());
    if (_name.text.trim().isEmpty) {
      setState(() => _err = 'Nama wajib diisi');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _err = 'Harga harus angka lebih dari 0');
      return;
    }
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'category': _category,
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'price': price,
      'active': _active,
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
            Text(isNew ? 'Produk / jasa baru' : 'Ubah produk / jasa',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: inputDeco('Nama'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: inputDeco('Kategori'),
              items: const [
                DropdownMenuItem(value: 'Ban', child: Text('Ban')),
                DropdownMenuItem(value: 'Layanan', child: Text('Layanan (jasa)')),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 2,
              decoration: inputDeco('Deskripsi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: inputDeco('Harga (Rp)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif (tampil untuk pelanggan)'),
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