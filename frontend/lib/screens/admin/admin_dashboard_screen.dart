import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart' show StatusChip;
import '../../widgets/role_chip.dart';

class AdminDashboardScreen extends StatefulWidget {
  final void Function(String page, {String? role})? onNavigate;
  const AdminDashboardScreen({super.key, this.onNavigate});
  @override State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      context.read<AdminProvider>().loadUsers(token);
      context.read<AdminProvider>().loadVendors(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final users   = admin.users;
    final vendors = admin.vendors;

    final stats = [
      {'label': 'Total Users',       'value': '${users.length}',                                                 'icon': Icons.people,          'colors': [const Color(0xFF0F766E), const Color(0xFF134E4A)], 'page': 'users',   'role': null},
      {'label': 'Vendors',           'value': '${users.where((u) => u.role == 'Vendor').length}',                'icon': Icons.store,           'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)], 'page': 'users',   'role': 'Vendor'},
      {'label': 'Customers',         'value': '${users.where((u) => u.role == 'Customer').length}',             'icon': Icons.person,          'colors': [const Color(0xFF0891B2), const Color(0xFF0E7490)], 'page': 'users',   'role': 'Customer'},
      {'label': 'Pending Approvals', 'value': '${vendors.where((v) => v.onboardingStatus == 'Pending').length}','icon': Icons.pending_actions, 'colors': [const Color(0xFFD97706), const Color(0xFFB45309)], 'page': 'vendors', 'role': null},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: admin.loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Greeting
              Text('Welcome back, ${auth.user?.firstName}! 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
              Text('Admin Dashboard · ${DateTime.now().toLocal().toString().substring(0, 10)}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),

              // Stat cards
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
                children: stats.map((s) => StatCard(
                  label: s['label'] as String,
                  value: s['value'] as String,
                  icon: s['icon'] as IconData,
                  gradientColors: s['colors'] as List<Color>,
                  onTap: () => widget.onNavigate?.call(
                    s['page'] as String,
                    role: s['role'] as String?,
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // User status summary
              Row(children: ['Active', 'Inactive', 'Pending'].map((st) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Column(children: [
                    Text('${users.where((u) => u.status == st).length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    StatusChip(st),
                  ]),
                ),
              )).toList()),
              const SizedBox(height: 24),

              // Pending vendor applications
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Pending Vendor Applications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                if (vendors.where((v) => v.onboardingStatus == 'Pending').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text('${vendors.where((v) => v.onboardingStatus == 'Pending').length} pending',
                      style: const TextStyle(color: AppTheme.amber, fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 12),
              ...vendors.where((v) => v.onboardingStatus == 'Pending').take(5).map((v) {
                final u = users.where((x) => x.id == v.userId).firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.cyan.withValues(alpha: 0.2),
                      child: Text(v.businessName[0], style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold))),
                    title: Text(v.businessName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${u?.fullName ?? '—'} · ${v.submittedAt}',
                      style: const TextStyle(fontSize: 12)),
                    trailing: StatusChip(v.onboardingStatus),
                  ),
                );
              }),
              if (vendors.where((v) => v.onboardingStatus == 'Pending').isEmpty)
                const Card(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No pending applications', style: TextStyle(color: Colors.grey))))),
            ]),
          ),
    );
  }
}
