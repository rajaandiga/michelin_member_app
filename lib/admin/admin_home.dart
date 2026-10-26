import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/api.dart';
import 'admin_dashboard.dart';
import 'admin_customers.dart';
import 'admin_complaints.dart';
import 'admin_vouchers.dart';
import 'admin_products.dart';

Future<bool> fetchIsAdmin() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) return false;
  final data = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
  return data != null && data['role'] == 'admin';
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  static const _titles = [
    'Ringkasan',
    'Pelanggan',
    'Keluhan',
    'Voucher',
    'Produk & Jasa',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const AdminDashboardPage(),
      const AdminCustomersPage(),
      const AdminComplaintsPage(),
      const AdminVouchersPage(),
      const AdminProductsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        toolbarHeight: 64,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MICHELIN MyXpert • ADMIN',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            Text(
              _titles[_index],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => Api.signOut(),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.yellow,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Ringkasan'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Pelanggan'),
          NavigationDestination(
              icon: Icon(Icons.report_outlined),
              selectedIcon: Icon(Icons.report),
              label: 'Keluhan'),
          NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer),
              label: 'Voucher'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Produk'),
        ],
      ),
    );
  }
}