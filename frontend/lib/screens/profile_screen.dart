import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/role_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addrCtrl    = TextEditingController();
  bool  _editing = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final u = context.read<AuthProvider>().user;
    if (u == null) return;
    _firstCtrl.text = u.firstName;
    _lastCtrl.text  = u.lastName;
    _phoneCtrl.text = u.phoneNumber ?? '';
    _addrCtrl.text  = u.address ?? '';
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _phoneCtrl, _addrCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().updateProfile({
      'first_name':   _firstCtrl.text.trim(),
      'last_name':    _lastCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'address':      _addrCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profile updated!' : context.read<AuthProvider>().error ?? 'Error'),
        backgroundColor: ok ? AppTheme.emerald : AppTheme.rose));
      if (ok) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u    = auth.user;
    if (u == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Manage your account details', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            if (!_editing)
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () => setState(() => _editing = true)),
          ]),
          const SizedBox(height: 24),

          // Avatar card
          Center(
            child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.pink]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.violet.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6))]),
                child: Center(child: Text(u.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)))),
              const SizedBox(height: 12),
              Text(u.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(u.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                RoleChip(u.role),
                const SizedBox(width: 8),
                StatusChip(u.status),
              ]),
            ]),
          ),
          const SizedBox(height: 28),

          if (_editing) ...[
            Form(
              key: _formKey,
              child: Column(children: [
                Row(children: [
                  Expanded(child: TextFormField(
                    controller: _firstCtrl,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                    controller: _lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null)),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addrCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () { setState(() => _editing = false); _prefill(); },
                    child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(child: GradientButton(
                    label: 'Save Changes',
                    loading: auth.loading,
                    onPressed: _save)),
                ]),
              ]),
            ),
          ] else ...[
            _InfoCard('Personal Details', [
              ['Full Name', u.fullName],
              ['Email',     u.email],
              ['Phone',     u.phoneNumber ?? '—'],
              ['Address',   u.address ?? '—'],
            ]),
            const SizedBox(height: 16),
            _InfoCard('Account Details', [
              ['Role',       u.role],
              ['Status',     u.status],
              ['Member Since', u.createdAt.substring(0, 10)],
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.rose),
                label: const Text('Sign Out', style: TextStyle(color: AppTheme.rose)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.rose),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                })),
          ],
        ]),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  const _InfoCard(this.title, this.rows);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const Divider(height: 20),
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(r[0], style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(child: Text(r[1],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.right)),
        ]))),
    ]),
  );
}
