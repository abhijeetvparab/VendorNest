import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/role_chip.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});
  @override State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _roleFilter   = 'All';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final token = context.read<AuthProvider>().accessToken ?? '';
    context.read<AdminProvider>().loadUsers(token,
      role:   _roleFilter   == 'All' ? null : _roleFilter,
      status: _statusFilter == 'All' ? null : _statusFilter,
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _showEditDialog(User u) async {
    final firstCtrl   = TextEditingController(text: u.firstName);
    final lastCtrl    = TextEditingController(text: u.lastName);
    final phoneCtrl   = TextEditingController(text: u.phoneNumber ?? '');
    final addressCtrl = TextEditingController(text: u.address ?? '');
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.purple]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Text('Edit ${u.fullName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(children: [
                if (err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.rose.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(err!, style: const TextStyle(color: AppTheme.rose, fontSize: 13))),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(child: TextField(controller: firstCtrl,
                    decoration: const InputDecoration(labelText: 'First Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 12),
                TextField(controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Address')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet, foregroundColor: Colors.white),
              onPressed: () async {
                set(() => err = null);
                final token = context.read<AuthProvider>().accessToken ?? '';
                final ok = await context.read<AdminProvider>().updateUser(token, u.id, {
                  'first_name': firstCtrl.text.trim(),
                  'last_name':  lastCtrl.text.trim(),
                  'phone_number': phoneCtrl.text.trim(),
                  'address':    addressCtrl.text.trim(),
                });
                if (ok) { if (ctx.mounted) Navigator.pop(ctx); }
                else set(() => err = context.read<AdminProvider>().error ?? 'Error');
              },
              child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateAdminDialog() async {
    final firstCtrl  = TextEditingController();
    final lastCtrl   = TextEditingController();
    final emailCtrl  = TextEditingController();
    final passCtrl   = TextEditingController();
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.purple]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: const Text('Create Admin User',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(children: [
                if (err != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.rose.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(err!, style: const TextStyle(color: AppTheme.rose, fontSize: 13))),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Expanded(child: TextField(controller: firstCtrl,
                    decoration: const InputDecoration(labelText: 'First Name'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name'))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: passCtrl, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violet, foregroundColor: Colors.white),
              onPressed: () async {
                set(() => err = null);
                final token = context.read<AuthProvider>().accessToken ?? '';
                final ok = await context.read<AdminProvider>().createAdmin(token, {
                  'first_name': firstCtrl.text.trim(),
                  'last_name':  lastCtrl.text.trim(),
                  'email':      emailCtrl.text.trim(),
                  'password':   passCtrl.text,
                });
                if (ok) { if (ctx.mounted) Navigator.pop(ctx); }
                else set(() => err = context.read<AdminProvider>().error ?? 'Error');
              },
              child: const Text('Create')),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(User u) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete ${u.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      final ok = await context.read<AdminProvider>().deleteUser(token, u.id);
      if (mounted) _snack(ok ? '${u.fullName} deleted.' : context.read<AdminProvider>().error ?? 'Error',
        ok ? null : AppTheme.rose);
    }
  }

  void _snack(String msg, Color? color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final me    = context.read<AuthProvider>().user;
    final users = admin.users;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                Text('Manage all system users', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _showCreateAdminDialog),
            ]),
            const SizedBox(height: 16),
            // Filters row
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onSubmitted: (_) => _load(),
                  onChanged: (v) { if (v.isEmpty) _load(); },
                )),
              const SizedBox(width: 12),
              _FilterChips(
                label: 'Role',
                options: const ['All','Admin','Vendor','Customer'],
                value: _roleFilter,
                onChanged: (v) { setState(() => _roleFilter = v); _load(); }),
              const SizedBox(width: 8),
              _FilterChips(
                label: 'Status',
                options: const ['All','Active','Inactive','Pending'],
                value: _statusFilter,
                onChanged: (v) { setState(() => _statusFilter = v); _load(); }),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: admin.loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
            : users.isEmpty
              ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final isSelf = u.id == me?.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppTheme.violet.withOpacity(0.15),
                            child: Text(u.initials,
                              style: const TextStyle(color: AppTheme.violet, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(u.fullName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              if (isSelf) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.violet.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                  child: const Text('You', style: TextStyle(fontSize: 10, color: AppTheme.violet, fontWeight: FontWeight.w700))),
                              ],
                            ]),
                            const SizedBox(height: 2),
                            Text(u.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(children: [
                              RoleChip(u.role),
                              const SizedBox(width: 6),
                              StatusChip(u.status),
                            ]),
                          ])),
                          if (!isSelf) Row(children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit',
                              onPressed: () => _showEditDialog(u)),
                            IconButton(
                              icon: Icon(
                                u.status == 'Active' ? Icons.block_outlined : Icons.check_circle_outline,
                                size: 18,
                                color: u.status == 'Active' ? AppTheme.amber : AppTheme.emerald),
                              tooltip: u.status == 'Active' ? 'Deactivate' : 'Activate',
                              onPressed: () async {
                                final token = context.read<AuthProvider>().accessToken ?? '';
                                final newStatus = u.status == 'Active' ? 'Inactive' : 'Active';
                                final ok = await context.read<AdminProvider>().toggleUserStatus(token, u.id, newStatus);
                                if (mounted && !ok) _snack(context.read<AdminProvider>().error ?? 'Error', AppTheme.rose);
                              }),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.rose),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(u)),
                          ]),
                        ]),
                      ),
                    );
                  }),
        ),
      ]),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String label;
  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  const _FilterChips({required this.label, required this.options, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
          color: value == 'All' ? Colors.white : AppTheme.violet.withOpacity(0.08)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label: $value',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: value == 'All' ? Colors.black87 : AppTheme.violet)),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 16),
        ]),
      ),
      itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
    );
  }
}
