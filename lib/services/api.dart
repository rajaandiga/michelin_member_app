import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'cart.dart';

class Api {
  static SupabaseClient get _db => Supabase.instance.client;
  static User? get user => _db.auth.currentUser;

  // Naik satu setiap ada perubahan data, supaya tab lain ikut memuat ulang.
  static final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  static void notifyChanged() => refresh.value++;

  static Future<void> signIn(String email, String password) async {
    await _db.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) {
    return _db.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name, 'phone': phone},
    );
  }

  static Future<void> signOut() async {
    Cart.instance.clear();
    await _db.auth.signOut();
  }

  static Future<Profile> myProfile() async {
    final m = await _db.from('profiles').select().eq('id', user!.id).single();
    return Profile.fromMap(m);
  }

  static Future<void> updateProfile(String name, String phone) async {
    await _db
        .from('profiles')
        .update({'full_name': name, 'phone': phone}).eq('id', user!.id);
  }

  static Future<List<Product>> products() async {
    final r = await _db
        .from('products')
        .select()
        .eq('active', true)
        .order('category')
        .order('name');
    return r.map<Product>((e) => Product.fromMap(e)).toList();
  }

  // Pesanan dari keranjang, dengan voucher (boleh kosong)
  static Future<void> checkoutCart(
      List<CartLine> lines, String? userVoucherId) async {
    await _db.rpc('checkout_cart', params: {
      'p_items': lines
          .map((l) => {'product_id': l.product.id, 'qty': l.qty})
          .toList(),
      'p_user_voucher_id': userVoucherId,
    });
    Cart.instance.clear();
    notifyChanged();
  }

  static Future<List<OrderRecord>> myOrders() async {
    final r = await _db
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);
    return r.map<OrderRecord>((e) => OrderRecord.fromMap(e)).toList();
  }

  static Future<List<Voucher>> vouchers() async {
    final r = await _db.from('vouchers').select().eq('active', true);
    return r.map<Voucher>((e) => Voucher.fromMap(e)).toList();
  }

  // Voucher milik kita yang belum dipakai
  static Future<List<UserVoucher>> myVouchers() async {
    final r = await _db
        .from('user_vouchers')
        .select('*, vouchers(*)')
        .eq('user_id', user!.id)
        .isFilter('used_at', null)
        .order('claimed_at', ascending: false);
    final out = <UserVoucher>[];
    for (final e in r) {
      final v = e['vouchers'];
      if (v == null) continue;
      out.add(UserVoucher(
        id: e['id'] as String,
        voucher: Voucher.fromMap(v as Map<String, dynamic>),
        claimedAt: DateTime.parse(e['claimed_at'] as String),
      ));
    }
    return out;
  }

  // Semua voucher yang pernah diklaim (termasuk yang sudah dipakai)
  static Future<Set<String>> claimedVoucherIds() async {
    final r = await _db
        .from('user_vouchers')
        .select('voucher_id')
        .eq('user_id', user!.id);
    return r.map<String>((e) => e['voucher_id'] as String).toSet();
  }

  static Future<void> claimVoucher(String voucherId) async {
    await _db.rpc('claim_voucher', params: {'p_voucher_id': voucherId});
    notifyChanged();
  }

  static Future<List<Complaint>> myComplaints() async {
    final r = await _db
        .from('complaints')
        .select()
        .eq('user_id', user!.id)
        .order('created_at', ascending: false);
    return r.map<Complaint>((e) => Complaint.fromMap(e)).toList();
  }

  static Future<void> sendComplaint(String subject, String message) async {
    await _db.from('complaints').insert({
      'user_id': user!.id,
      'subject': subject,
      'message': message,
    });
    notifyChanged();
  }
}
