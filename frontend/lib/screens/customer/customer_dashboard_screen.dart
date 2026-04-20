import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});
  @override State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      context.read<VendorProvider>().loadApprovedVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final vendor = context.watch<VendorProvider>();
    final vendors = vendor.approvedVendors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, ${auth.user?.firstName}! 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Text('Discover and connect with verified vendors',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          // Stats row
          Row(children: [
            _StatBox('Vendors', '${vendors.length}', Icons.store_outlined,
              const [Color(0xFF0F766E), Color(0xFF134E4A)]),
            const SizedBox(width: 12),
            _StatBox('Categories', '${vendors.map((v) => v.businessType).toSet().length}',
              Icons.category_outlined,
              const [Color(0xFFF59E0B), Color(0xFFD97706)]),
          ]),
          const SizedBox(height: 24),

          const Text('Featured Vendors',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),

          if (vendor.loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.violet))
          else if (vendors.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No vendors available yet.',
                style: TextStyle(color: Colors.grey)))))
          else
            ...vendors.take(5).map((v) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.cyan.withValues(alpha: 0.15),
                  child: Text(v.businessName[0],
                    style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold))),
                title: Text(v.businessName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${v.businessType} · ${v.pocEmail}',
                  style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('Active',
                    style: TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w700))),
              ),
            )),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> colors;
  const _StatBox(this.label, this.value, this.icon, this.colors);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        ]),
      ]),
    ),
  );
}
