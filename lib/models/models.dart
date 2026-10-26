import '../core/format.dart';

class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String memberNo;
  final String role;
  final int points;
  final int totalSpent;
  final String tier;
  final int visitCount;
  final int serviceVisitCount;
  final DateTime? lastVisitAt;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.memberNo,
    required this.role,
    required this.points,
    required this.totalSpent,
    required this.tier,
    required this.visitCount,
    required this.serviceVisitCount,
    required this.lastVisitAt,
    required this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: (m['full_name'] ?? '') as String,
        phone: m['phone'] as String?,
        memberNo: (m['member_no'] ?? '-') as String,
        role: (m['role'] ?? 'customer') as String,
        points: (m['points'] as num).toInt(),
        totalSpent: (m['total_spent'] as num).toInt(),
        tier: (m['tier'] ?? 'Bronze') as String,
        visitCount: ((m['visit_count'] ?? 0) as num).toInt(),
        serviceVisitCount: ((m['service_visit_count'] ?? 0) as num).toInt(),
        lastVisitAt: m['last_visit_at'] == null
            ? null
            : DateTime.parse(m['last_visit_at'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  bool get isAdmin => role == 'admin';
  String get displayName =>
      fullName.trim().isEmpty ? 'Member' : fullName.trim();

  String? get nextTier => switch (tier) {
        'Bronze' => 'Silver',
        'Silver' => 'Gold',
        'Gold' => 'Platinum',
        _ => null,
      };

  int? get nextTarget => switch (tier) {
        'Bronze' => 5000000,
        'Silver' => 15000000,
        'Gold' => 40000000,
        _ => null,
      };

  static int rankOf(String tier) => switch (tier) {
        'Platinum' => 4,
        'Gold' => 3,
        'Silver' => 2,
        _ => 1,
      };

  // Sama dengan fungsi segment_of di database
  String get segment {
    final now = DateTime.now();
    final last = lastVisitAt;
    if (last == null) {
      return createdAt.isAfter(now.subtract(const Duration(days: 30)))
          ? 'Baru'
          : 'Tidur';
    }
    if (last.isBefore(now.subtract(const Duration(days: 60)))) return 'Tidur';
    if (visitCount >= 4) return 'Setia';
    if (visitCount <= 1) return 'Baru';
    return 'Aktif';
  }
}

class Product {
  final String id;
  final String name;
  final String category;
  final String? description;
  final int price;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] as String,
        category: m['category'] as String,
        description: m['description'] as String?,
        price: (m['price'] as num).toInt(),
      );
}

class OrderLine {
  final String name;
  final String category;
  final int qty;
  final int price;

  const OrderLine({
    required this.name,
    required this.category,
    required this.qty,
    required this.price,
  });
}

class OrderRecord {
  final String id;
  final int subtotal;
  final int discount;
  final int total;
  final int pointsEarned;
  final String? voucherTitle;
  final DateTime createdAt;
  final List<OrderLine> lines;

  const OrderRecord({
    required this.id,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.pointsEarned,
    required this.voucherTitle,
    required this.createdAt,
    required this.lines,
  });

  factory OrderRecord.fromMap(Map<String, dynamic> m) {
    final total = (m['total'] as num).toInt();
    final items = (m['order_items'] as List? ?? [])
        .map((e) => OrderLine(
              name: e['product_name'] as String,
              category: e['category'] as String,
              qty: (e['qty'] as num).toInt(),
              price: (e['price'] as num).toInt(),
            ))
        .toList();
    // Pesanan dari tahap 1 belum punya order_items
    if (items.isEmpty && m['product_name'] != null) {
      final qty = ((m['qty'] ?? 1) as num).toInt();
      items.add(OrderLine(
        name: m['product_name'] as String,
        category: (m['category'] ?? '') as String,
        qty: qty,
        price: qty == 0 ? total : total ~/ qty,
      ));
    }
    return OrderRecord(
      id: m['id'] as String,
      subtotal: ((m['subtotal'] ?? total) as num).toInt(),
      discount: ((m['discount'] ?? 0) as num).toInt(),
      total: total,
      pointsEarned: (m['points_earned'] as num).toInt(),
      voucherTitle: m['voucher_title'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      lines: items,
    );
  }
}

class Complaint {
  final String id;
  final String subject;
  final String message;
  final String status;
  final String? resolution;
  final DateTime createdAt;

  const Complaint({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.resolution,
    required this.createdAt,
  });

  factory Complaint.fromMap(Map<String, dynamic> m) => Complaint(
        id: m['id'] as String,
        subject: m['subject'] as String,
        message: m['message'] as String,
        status: m['status'] as String,
        resolution: m['resolution'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class Voucher {
  final String id;
  final String title;
  final String? description;
  final String kind; // 'nominal' atau 'persen'
  final int value;
  final int? maxDiscount;
  final int minSpend;
  final int? pointsCost;
  final String? minTier;
  final String? targetSegment;
  final bool onlyService;
  final DateTime? expiresAt;

  const Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.value,
    required this.maxDiscount,
    required this.minSpend,
    required this.pointsCost,
    required this.minTier,
    required this.targetSegment,
    required this.onlyService,
    required this.expiresAt,
  });

  factory Voucher.fromMap(Map<String, dynamic> m) => Voucher(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        kind: m['kind'] as String,
        value: (m['value'] as num).toInt(),
        maxDiscount: (m['max_discount'] as num?)?.toInt(),
        minSpend: ((m['min_spend'] ?? 0) as num).toInt(),
        pointsCost: (m['points_cost'] as num?)?.toInt(),
        minTier: m['min_tier'] as String?,
        targetSegment: m['target_segment'] as String?,
        onlyService: (m['only_service'] ?? false) as bool,
        expiresAt: m['expires_at'] == null
            ? null
            : DateTime.parse(m['expires_at'] as String),
      );

  String get benefit {
    if (kind == 'nominal') return 'Potongan ${rupiah(value)}';
    final cap = maxDiscount == null ? '' : ', maksimal ${rupiah(maxDiscount!)}';
    return 'Diskon $value%$cap';
  }

  String get conditions {
    final parts = <String>[];
    if (minSpend > 0) parts.add('minimal belanja ${rupiah(minSpend)}');
    if (onlyService) parts.add('khusus pesanan yang ada jasanya');
    if (minTier != null) parts.add('tier $minTier ke atas');
    if (expiresAt != null) parts.add('sampai ${tanggal(expiresAt!)}');
    if (parts.isEmpty) return 'Tanpa syarat tambahan';
    final s = parts.join(', ');
    return s[0].toUpperCase() + s.substring(1);
  }

  int discountFor(int subtotal) {
    var d = kind == 'nominal' ? value : subtotal * value ~/ 100;
    if (kind == 'persen' && maxDiscount != null && d > maxDiscount!) {
      d = maxDiscount!;
    }
    return d > subtotal ? subtotal : d;
  }

  bool get expired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool eligibleFor(Profile p) {
    if (expired) return false;
    if (minTier != null && Profile.rankOf(p.tier) < Profile.rankOf(minTier!)) {
      return false;
    }
    if (targetSegment != null && targetSegment != p.segment) return false;
    return true;
  }
}

class UserVoucher {
  final String id;
  final Voucher voucher;
  final DateTime claimedAt;

  const UserVoucher({
    required this.id,
    required this.voucher,
    required this.claimedAt,
  });
}
