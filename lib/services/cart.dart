import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartLine {
  final Product product;
  int qty;
  CartLine(this.product, this.qty);
  int get total => product.price * qty;
}

class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (s, l) => s + l.qty);
  int get subtotal => _lines.values.fold(0, (s, l) => s + l.total);
  bool get hasService =>
      _lines.values.any((l) => l.product.category == 'Layanan');

  void add(Product p) {
    final l = _lines[p.id];
    if (l == null) {
      _lines[p.id] = CartLine(p, 1);
    } else if (l.qty < 20) {
      l.qty++;
    }
    notifyListeners();
  }

  void setQty(String id, int qty) {
    final l = _lines[id];
    if (l == null) return;
    if (qty <= 0) {
      _lines.remove(id);
    } else {
      l.qty = qty > 20 ? 20 : qty;
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
