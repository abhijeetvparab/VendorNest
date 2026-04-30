import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/role_chip.dart';
import 'admin/admin_dashboard_screen.dart';
import 'admin/vendor_requests_screen.dart';
import 'admin/user_management_screen.dart';
import 'vendor/vendor_dashboard_screen.dart';
import 'vendor/vendor_onboarding_screen.dart';
import 'vendor/products/product_list_screen.dart';
import 'admin/admin_products_screen.dart';
import 'customer/customer_dashboard_screen.dart';
import 'customer/browse_vendors_screen.dart';
import 'profile_screen.dart';

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  const _NavItem(this.id, this.label, this.icon);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String  _activePage = 'dashboard';
  String? _navRole;

  @override
  void initState() {
    super.initState();
    final role = context.read<AuthProvider>().role;
    if (role == 'Vendor') _activePage = 'profile';
  }

  // Admin nav only holds non-grouped items — vendors/products live in the sidebar group.
  // Length > 4 keeps bottom nav hidden for admin (they use the drawer).
  static const List<_NavItem> _adminNav = [
    _NavItem('dashboard', 'Dashboard',          Icons.home_outlined),
    _NavItem('vendors',   'Vendor Applications',Icons.store_mall_directory_outlined),
    _NavItem('users',     'User Management',    Icons.people_outline),
    _NavItem('products',  'Products',           Icons.inventory_2_outlined),
    _NavItem('profile',   'My Profile',         Icons.person_outline),
  ];
  static const List<_NavItem> _vendorNav = [
    _NavItem('profile',    'My Profile',    Icons.person_outline),
    _NavItem('dashboard',  'Dashboard',     Icons.home_outlined),
    _NavItem('onboarding', 'My Onboarding', Icons.assignment_outlined),
    _NavItem('products',   'My Products',   Icons.inventory_2_outlined),
  ];
  static const List<_NavItem> _customerNav = [
    _NavItem('dashboard', 'Dashboard',      Icons.home_outlined),
    _NavItem('browse',    'Browse Vendors', Icons.shopping_bag_outlined),
    _NavItem('profile',   'My Profile',     Icons.person_outline),
  ];

  List<_NavItem> get _navItems {
    final role = context.read<AuthProvider>().role;
    if (role == 'Admin')  return _adminNav;
    if (role == 'Vendor') return _vendorNav;
    return _customerNav;
  }

  void _navigate(String page, {String? role}) {
    setState(() {
      _activePage = page;
      _navRole = role;
    });
  }

  Widget _buildPage() {
    final role = context.read<AuthProvider>().role;
    switch (_activePage) {
      case 'dashboard':
        if (role == 'Admin')  return AdminDashboardScreen(onNavigate: _navigate);
        if (role == 'Vendor') return const VendorDashboardScreen();
        return const CustomerDashboardScreen();
      case 'vendors':    return const VendorRequestsScreen();
      case 'users':      return UserManagementScreen(initialRole: _navRole);
      case 'onboarding': return const VendorOnboardingScreen();
      case 'products':
        if (role == 'Admin') return const AdminProductsScreen();
        return const ProductListScreen();
      case 'browse':     return const BrowseVendorsScreen();
      case 'profile':    return const ProfileScreen();
      default:           return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return isWide ? _wideLayout() : _narrowLayout();
  }

  Widget _wideLayout() => Scaffold(
    body: Row(children: [
      _Sidebar(
        activePage: _activePage,
        navItems: _navItems,
        onSelect: (id) => setState(() { _activePage = id; _navRole = null; }),
      ),
      Expanded(
        child: ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: _buildPage(),
        ),
      ),
    ]),
  );

  Widget _narrowLayout() {
    final auth  = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final pending = admin.pendingCount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VendorNest',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.violet)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: UserAvatar(
              initials: auth.user?.initials ?? '',
              role: auth.user?.role ?? '',
              size: 34,
            ),
          ),
        ],
      ),
      drawer: _DrawerContent(
        activePage: _activePage,
        navItems: _navItems,
        onSelect: (id) {
          setState(() { _activePage = id; _navRole = null; });
          Navigator.pop(context);
        },
      ),
      body: ColoredBox(color: const Color(0xFFF8FAFC), child: _buildPage()),
      bottomNavigationBar: _navItems.length <= 4 ? _bottomNav(pending) : null,
    );
  }

  Widget _bottomNav(int badge) {
    final items = _navItems;
    return BottomNavigationBar(
      currentIndex: items.indexWhere((n) => n.id == _activePage).clamp(0, items.length - 1),
      onTap: (i) => setState(() { _activePage = items[i].id; _navRole = null; }),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.violet,
      unselectedItemColor: Colors.grey,
      items: items.map((n) => BottomNavigationBarItem(
        icon: badge > 0 && n.id == 'vendors'
            ? Badge(label: Text('$badge'), child: Icon(n.icon))
            : Icon(n.icon),
        label: n.label,
      )).toList(),
    );
  }
}

// ── Sidebar (wide screens) ─────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String activePage;
  final List<_NavItem> navItems;
  final void Function(String) onSelect;

  const _Sidebar({
    required this.activePage,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    return Container(
      width: 240,
      decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
      child: Column(children: [
        // App name
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('VendorNest',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ]),
        ),
        // User card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            UserAvatar(
                initials: auth.user?.initials ?? '',
                role: auth.user?.role ?? '',
                size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?.fullName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    RoleChip(auth.user?.role ?? ''),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Nav items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: _buildNavEntries(auth, admin),
            ),
          ),
        ),
        // Logout
        Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(children: [
                Icon(Icons.logout,
                    color: Colors.white.withValues(alpha: 0.5), size: 18),
                const SizedBox(width: 10),
                Text('Sign Out',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildNavEntries(AuthProvider auth, AdminProvider admin) {
    final role = auth.user?.role ?? '';
    if (role == 'Admin') {
      return [
        _navTile('dashboard', 'Dashboard', Icons.home_outlined, admin),
        _VendorMgmtGroupTile(
          activePage: activePage,
          onSelect: onSelect,
          pendingCount: admin.pendingCount,
        ),
        _navTile('users', 'User Management', Icons.people_outline, admin),
        _navTile('profile', 'My Profile', Icons.person_outline, admin),
      ];
    }
    return navItems.map((n) => _navTile(n.id, n.label, n.icon, admin)).toList();
  }

  Widget _navTile(
      String id, String label, IconData icon, AdminProvider admin) {
    final active    = activePage == id;
    final isPending = id == 'vendors' && admin.pendingCount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onSelect(id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppTheme.violet, AppTheme.violetDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : null,
            borderRadius: BorderRadius.circular(12),
            color: active ? null : Colors.transparent,
          ),
          child: Row(children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13)),
            ),
            if (isPending)
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                    color: AppTheme.pink, shape: BoxShape.circle),
                child: Center(
                  child: Text('${admin.pendingCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Drawer (narrow screens) ────────────────────────────────────────────────────
class _DrawerContent extends StatelessWidget {
  final String activePage;
  final List<_NavItem> navItems;
  final void Function(String) onSelect;

  const _DrawerContent({
    required this.activePage,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth  = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();
    final role  = auth.user?.role ?? '';

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
        child: ListView(children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                      initials: auth.user?.initials ?? '',
                      role: auth.user?.role ?? '',
                      size: 48),
                  const SizedBox(height: 10),
                  Text(auth.user?.fullName ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  RoleChip(auth.user?.role ?? ''),
                ]),
          ),
          if (role == 'Admin') ...[
            _drawerTile('dashboard', 'Dashboard', Icons.home_outlined),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _VendorMgmtGroupTile(
                activePage: activePage,
                onSelect: onSelect,
                pendingCount: admin.pendingCount,
              ),
            ),
            _drawerTile('users', 'User Management', Icons.people_outline),
            _drawerTile('profile', 'My Profile', Icons.person_outline),
          ] else ...[
            ...navItems.map((n) => _drawerTile(n.id, n.label, n.icon)),
          ],
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54),
            title:
                const Text('Sign Out', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ]),
      ),
    );
  }

  ListTile _drawerTile(String id, String label, IconData icon) {
    final active = activePage == id;
    return ListTile(
      leading: Icon(icon, color: active ? Colors.white : Colors.white54),
      title: Text(label,
          style: TextStyle(
              color: active ? Colors.white : Colors.white70,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      selected: active,
      selectedTileColor: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () => onSelect(id),
    );
  }
}

// ── Vendor Management collapsible group (Admin sidebar & drawer) ───────────────
class _VendorMgmtGroupTile extends StatefulWidget {
  final String activePage;
  final void Function(String) onSelect;
  final int pendingCount;

  const _VendorMgmtGroupTile({
    required this.activePage,
    required this.onSelect,
    required this.pendingCount,
  });

  @override
  State<_VendorMgmtGroupTile> createState() => _VendorMgmtGroupTileState();
}

class _VendorMgmtGroupTileState extends State<_VendorMgmtGroupTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _isGroupActive;
  }

  @override
  void didUpdateWidget(_VendorMgmtGroupTile old) {
    super.didUpdateWidget(old);
    if (_isGroupActive && !_expanded) setState(() => _expanded = true);
  }

  bool get _isGroupActive =>
      widget.activePage == 'vendors' || widget.activePage == 'products';

  @override
  Widget build(BuildContext context) {
    final groupActive = _isGroupActive;
    return Column(children: [
      // ── Group header ──────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: groupActive && !_expanded
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(Icons.storefront_outlined,
                  color: groupActive ? Colors.white : Colors.white54,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Vendor Management',
                    style: TextStyle(
                        color: groupActive ? Colors.white : Colors.white70,
                        fontWeight: groupActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 13)),
              ),
              if (widget.pendingCount > 0) ...[
                Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(
                      color: AppTheme.pink, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${widget.pendingCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white54,
                size: 16,
              ),
            ]),
          ),
        ),
      ),
      // ── Sub-items ─────────────────────────────────────────────────────────
      if (_expanded) ...[
        _subTile('vendors', 'Vendor Applications',
            Icons.store_mall_directory_outlined),
        _subTile('products', 'Products', Icons.inventory_2_outlined),
      ],
    ]);
  }

  Widget _subTile(String id, String label, IconData icon) {
    final active = widget.activePage == id;
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 4),
      child: InkWell(
        onTap: () => widget.onSelect(id),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppTheme.violet, AppTheme.violetDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : null,
            borderRadius: BorderRadius.circular(10),
            color: active ? null : Colors.white.withValues(alpha: 0.06),
          ),
          child: Row(children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white54, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.white60,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}
