import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/cart.dart';
import '../cart/cart_screen.dart';

class KatalogTab extends StatefulWidget {
  const KatalogTab({super.key});

  @override
  State<KatalogTab> createState() => _KatalogTabState();
}

class _KatalogTabState extends State<KatalogTab> {
  late Future<List<Product>> _future = Api.products();
  String _cat = 'Semua';

  void _reload() => setState(() {
        _future = Api.products();
      });

  Future<void> _openCart() async {
    final msg = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
    if (msg != null && mounted) toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Katalog',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final c in const ['Semua', 'Ban', 'Layanan'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _cat == c,
                      selectedColor: AppColors.yellow,
                      onSelected: (_) => setState(() => _cat = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return ErrorRetry(onRetry: _reload);
                final all = snap.data ?? [];
                final items = _cat == 'Semua'
                    ? all
                    : all.where((e) => e.category == _cat).toList();
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Belum ada produk. Tambahkan produk di database lalu tarik layar ke bawah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return Panel(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                p.category == 'Ban'
                                    ? Icons.tire_repair
                                    : Icons.build_outlined,
                                color: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (p.description != null &&
                                      p.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        p.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(rupiah(p.price),
                                      style: const TextStyle(
                                          color: AppColors.blue,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            IconButton.filled(
                              tooltip: 'Tambah ke keranjang',
                              onPressed: () => Cart.instance.add(p),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.yellow,
                                foregroundColor: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) {
              final c = Cart.instance;
              if (c.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: FilledButton(
                  onPressed: _openCart,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_basket_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text('${c.itemCount} item di keranjang'),
                      const Spacer(),
                      Text(rupiah(c.subtotal)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
