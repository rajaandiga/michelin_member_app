import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class KeluhanTab extends StatefulWidget {
  const KeluhanTab({super.key});

  @override
  State<KeluhanTab> createState() => _KeluhanTabState();
}

class _KeluhanTabState extends State<KeluhanTab> {
  late Future<List<Complaint>> _future = Api.myComplaints();

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
    if (mounted) setState(() { _future = Api.myComplaints(); });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Diproses':
        return const Color(0xFFD98A00);
      case 'Selesai':
        return const Color(0xFF1E9E5A);
      default:
        return AppColors.blue;
    }
  }

  Future<void> _create() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ComplaintSheet(),
    );
    if (ok == true && mounted) toast(context, 'Keluhan terkirim');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add),
        label: const Text('Buat keluhan'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Keluhan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: FutureBuilder<List<Complaint>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return ErrorRetry(onRetry: _reload);
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Belum ada keluhan. Kalau ada masalah dengan ban atau layanan, tulis di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = items[i];
                      final color = _statusColor(c.status);
                      return Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.subject,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(c.status,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(c.message,
                                style: const TextStyle(fontSize: 13)),
                            if (c.resolution != null &&
                                c.resolution!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Tanggapan: ${c.resolution}',
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(tanggal(c.createdAt),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintSheet extends StatefulWidget {
  const _ComplaintSheet();

  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<_ComplaintSheet> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Judul dan isi keluhan wajib diisi');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Api.sendComplaint(_subject.text.trim(), _message.text.trim());
      if (mounted) Navigator.of(context).pop(true);
      return;
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal mengirim. Cek koneksi.');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keluhan baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _subject, decoration: inputDeco('Judul')),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            maxLines: 4,
            decoration: inputDeco('Ceritakan masalahnya'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _loading ? null : _send,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kirim keluhan'),
          ),
        ],
      ),
    );
  }
}
