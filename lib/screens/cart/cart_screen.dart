import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<UserVoucher>> _vouchers = Api.myVouchers();
  UserVoucher? _picked;
  bool _loading = false;
  String? _error;

  bool _usable(Voucher v, Cart cart) =>
      !v.expired &&
      cart.subtotal >= v.minSpend &&
      (!v.onlyService || cart.hasService);

  String? _why(Voucher v, Cart cart) {
    if (v.expired) return 'Sudah kedaluwarsa';
    if (cart.subtotal < v.minSpend) {
      return 'Belanja minimal ${rupiah(v.minSpend)}';
    }
    if (v.onlyService && !cart.hasService) {
      return 'Tambahkan jasa ke keranjang';
    }
    return null;
  }

  Future<void> _pay(Cart cart, UserVoucher? voucher, int pointsEarned) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Api.checkoutCart(cart.lines, voucher?.id);
      if (mounted) {
        Navigator.of(context)
            .pop('Pesanan selesai, kamu dapat $pointsEarned poin.');
      }
      return;
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memproses. Cek koneksi.');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final cart = Cart.instance;
          if (cart.isEmpty) {
            return const Center(
              child: Text('Keranjang kosong',
                  style: TextStyle(color: AppColors.muted)),
            );
          }
          final active = (_picked != null && _usable(_picked!.voucher, cart))
              ? _picked
              : null;
          final discount = active?.voucher.discountFor(cart.subtotal) ?? 0;
          final total = cart.subtotal - discount;
          final points = total ~/ 10000;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final l in cart.lines) ...[
                      Panel(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(rupiah(l.product.price),
                                      style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  cart.setQty(l.product.id, l.qty - 1),
                              icon: Icon(
                                l.qty == 1
                                    ? Icons.delete_outline
                                    : Icons.remove_circle_outline,
                              ),
                            ),
                            Text('${l.qty}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            IconButton(
                              onPressed: () =>
                                  cart.setQty(l.product.id, l.qty + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    const Text('Voucher',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    FutureBuilder<List<UserVoucher>>(
                      future: _vouchers,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final list = snap.data ?? [];
                        if (list.isEmpty) {
                          return const Text(
                            'Kamu belum punya voucher. Tukar poin atau klaim promo di tab Voucher.',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13),
                          );
                        }
                        return Column(
                          children: [
                            for (final uv in list) ...[
                              Builder(builder: (context) {
                                final ok = _usable(uv.voucher, cart);
                                final selected = active?.id == uv.id;
                                return Opacity(
                                  opacity: ok ? 1 : 0.5,
                                  child: Panel(
                                    onTap: ok
                                        ? () => setState(() =>
                                            _picked = selected ? null : uv)
                                        : null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: selected
                                              ? AppColors.blue
                                              : AppColors.muted,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(uv.voucher.title,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                _why(uv.voucher, cart) ??
                                                    uv.voucher.benefit,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: ok
                                                      ? AppColors.blue
                                                      : AppColors.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _row('Subtotal', rupiah(cart.subtotal)),
                      if (discount > 0)
                        _row('Diskon voucher', '- ${rupiah(discount)}',
                            color: const Color(0xFF1E9E5A)),
                      const SizedBox(height: 4),
                      _row('Total', rupiah(total), bold: true),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Kamu akan dapat $points poin',
                            style: const TextStyle(
                                color: AppColors.blue, fontSize: 12)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 12)),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed:
                            _loading ? null : () => _pay(cart, active, points),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Selesaikan pesanan'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontSize: bold ? 17 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
