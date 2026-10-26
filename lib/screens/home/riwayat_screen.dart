import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late Future<List<OrderRecord>> _future = Api.myOrders();

  void _reload() => setState(() {
        _future = Api.myOrders();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat belanja')),
      body: FutureBuilder<List<OrderRecord>>(
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
                  'Belum ada pesanan. Pilih ban atau jasa di tab Katalog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final o = items[i];
              return Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tanggal(o.createdAt),
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 8),
                    for (final l in o.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${l.qty} x ${l.name}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Text(rupiah(l.price * l.qty),
                                style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    if (o.discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Voucher ${o.voucherTitle ?? ''}',
                              style: const TextStyle(
                                  color: Color(0xFF1E9E5A), fontSize: 13),
                            ),
                          ),
                          Text('- ${rupiah(o.discount)}',
                              style: const TextStyle(
                                  color: Color(0xFF1E9E5A), fontSize: 13)),
                        ],
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text('+${o.pointsEarned} poin',
                            style: const TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(rupiah(o.total),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
