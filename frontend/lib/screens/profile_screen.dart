import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../providers/vendor_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/role_chip.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Personal
  final _formKey   = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl   = TextEditingController();

  String?                   _selectedCity;
  List<Map<String, String>> _cities        = [];
  bool                      _citiesLoading = false;
  bool                      _editing       = false;

  // Business (vendor only)
  final _bizNameCtrl  = TextEditingController();
  final _pocNameCtrl  = TextEditingController();
  final _pocPhoneCtrl = TextEditingController();
  final _pocEmailCtrl = TextEditingController();
  final _gstCtrl      = TextEditingController();
  final _descCtrl     = TextEditingController();
  String _bizType     = 'Retail';

  static const _bizTypes = [
    'Retail', 'Wholesale', 'Manufacturing', 'Services',
    'Food & Beverage', 'Technology', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadCities();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.role == 'Vendor') {
        context.read<VendorProvider>().loadMyProfile(auth.accessToken ?? '').then((_) {
          if (mounted) _prefillBusiness();
        });
      }
    });
  }

  Future<void> _loadCities() async {
    setState(() => _citiesLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.cities));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _cities = data.map((e) => {
            'city':  e['city']  as String,
            'state': e['state'] as String,
          }).toList();
        });
        if (_selectedCity != null) {
          final match = _cities.where((c) => c['city'] == _selectedCity).firstOrNull;
          if (match != null) setState(() => _stateCtrl.text = match['state']!);
        }
      }
    } catch (_) {
    } finally {
      setState(() => _citiesLoading = false);
    }
  }

  void _prefill() {
    final u = context.read<AuthProvider>().user;
    if (u == null) return;
    _firstCtrl.text = u.firstName;
    _lastCtrl.text  = u.lastName;
    _phoneCtrl.text = u.phoneNumber;
    _parseAddress(u.address);
  }

  void _prefillBusiness() {
    final p = context.read<VendorProvider>().myProfile;
    if (p == null) return;
    _bizNameCtrl.text  = p.businessName;
    _pocNameCtrl.text  = p.pocName;
    _pocPhoneCtrl.text = p.pocPhone;
    _pocEmailCtrl.text = p.pocEmail;
    _gstCtrl.text      = p.gstNumber ?? '';
    _descCtrl.text     = p.description ?? '';
    if (_bizTypes.contains(p.businessType)) {
      setState(() => _bizType = p.businessType);
    }
  }

  void _parseAddress(String address) {
    if (address.isEmpty) return;
    final parts = address.split(', ');
    if (parts.length >= 3 && RegExp(r'^[1-9][0-9]{5}$').hasMatch(parts.last)) {
      _pinCtrl.text   = parts.last;
      _stateCtrl.text = parts[parts.length - 2];
      _selectedCity   = parts[parts.length - 3];
      _cityCtrl.text  = _selectedCity!;
      final addrParts = parts.sublist(0, parts.length - 3);
      _addr1Ctrl.text = addrParts.isNotEmpty ? addrParts.first : '';
      _addr2Ctrl.text = addrParts.length > 1 ? addrParts.sublist(1).join(', ') : '';
    } else {
      _addr1Ctrl.text = address;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _firstCtrl, _lastCtrl, _phoneCtrl,
      _addr1Ctrl, _addr2Ctrl, _cityCtrl, _stateCtrl, _pinCtrl,
      _bizNameCtrl,
      _pocNameCtrl, _pocPhoneCtrl, _pocEmailCtrl,
      _gstCtrl, _descCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  String get _combinedAddress {
    final parts = [
      _addr1Ctrl.text.trim(),
      if (_addr2Ctrl.text.trim().isNotEmpty) _addr2Ctrl.text.trim(),
      if (_selectedCity != null) _selectedCity!,
      _stateCtrl.text.trim(),
      _pinCtrl.text.trim(),
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Future<void> _openCityPicker() async {
    final searchCtrl = TextEditingController();
    var filtered = List<Map<String, String>>.from(_cities);

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select City',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search city…',
                  prefixIcon: Icon(Icons.search, size: 18),
                  isDense: true,
                ),
                onChanged: (q) => setDialogState(() {
                  filtered = _cities
                      .where((c) => c['city']!.toLowerCase().contains(q.toLowerCase()))
                      .toList();
                }),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No cities found',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(filtered[i]['city']!,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(filtered[i]['state']!,
                              style: const TextStyle(fontSize: 12)),
                          dense: true,
                          selected: _selectedCity == filtered[i]['city'],
                          selectedColor: AppTheme.violet,
                          onTap: () => Navigator.pop(ctx, filtered[i]['city']),
                        ),
                      ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final match = _cities.firstWhere((c) => c['city'] == selected);
      setState(() {
        _selectedCity   = selected;
        _cityCtrl.text  = selected;
        _stateCtrl.text = match['state']!;
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth     = context.read<AuthProvider>();
    final vendor   = context.read<VendorProvider>();
    final isVendor = auth.user?.role == 'Vendor';

    bool ok = await auth.updateProfile({
      'first_name':   _firstCtrl.text.trim(),
      'last_name':    _lastCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'address':      _combinedAddress,
    });

    if (ok && isVendor && vendor.myProfile != null) {
      ok = await vendor.updateVendorProfile(auth.accessToken ?? '', {
        'business_name':    _bizNameCtrl.text.trim(),
        'business_type':    _bizType,
        'gst_number':_gstCtrl.text.trim().isEmpty    ? null : _gstCtrl.text.trim(),
        'poc_name':  _pocNameCtrl.text.trim(),
        'poc_phone': _pocPhoneCtrl.text.trim(),
        'poc_email': _pocEmailCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      });
    }

    if (mounted) {
      final errMsg = isVendor
          ? (vendor.error ?? auth.error ?? 'Error')
          : (auth.error ?? 'Error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Profile updated!' : errMsg),
        backgroundColor: ok ? AppTheme.emerald : AppTheme.rose));
      if (ok) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u    = auth.user;
    if (u == null) return const SizedBox.shrink();

    final isVendor = u.role == 'Vendor';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('My Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Account overview',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            if (!_editing)
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                onPressed: () => setState(() => _editing = true)),
          ]),
          const SizedBox(height: 24),

          // Avatar
          Center(
            child: Column(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.violet, AppTheme.pink]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.violet.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]),
                child: Center(
                  child: Text(u.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)))),
              const SizedBox(height: 12),
              Text(u.fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(u.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Personal Details ────────────────────────────────
                  _sectionLabel('Personal Details'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _firstCtrl,
                      decoration: const InputDecoration(labelText: 'First Name *'),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _lastCtrl,
                      decoration: const InputDecoration(labelText: 'Last Name *'),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null)),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined))),
                  const SizedBox(height: 16),

                  _sectionLabel('Address'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addr1Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 1 *',
                      prefixIcon: Icon(Icons.location_on_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 5) return 'Minimum 5 characters';
                      return null;
                    }),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addr2Ctrl,
                    decoration: const InputDecoration(
                      labelText: 'Address Line 2 (Optional)',
                      prefixIcon: Icon(Icons.add_location_alt_outlined))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _cityField()),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: _stateCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'State',
                        filled: _selectedCity != null,
                        fillColor: _selectedCity != null
                            ? AppTheme.violet.withValues(alpha: 0.05)
                            : null,
                      ),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      prefixIcon: Icon(Icons.pin_drop_outlined)),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim())) {
                        return 'Enter a valid 6-digit pincode';
                      }
                      return null;
                    }),

                  // ── Business Details (vendor only) ──────────────────
                  if (isVendor && context.watch<VendorProvider>().myProfile != null) ...[
                    const SizedBox(height: 24),
                    _sectionLabel('Business Details'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _bizNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        prefixIcon: Icon(Icons.store_outlined)),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _bizType,
                      decoration: const InputDecoration(
                        labelText: 'Business Type *',
                        prefixIcon: Icon(Icons.category_outlined)),
                      items: _bizTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _bizType = v!)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _gstCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'GST Number',
                        prefixIcon: Icon(Icons.receipt_long_outlined))),
                    const SizedBox(height: 20),

                    _sectionLabel('Point of Contact'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _pocNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'POC Name *',
                        prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pocPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'POC Phone *',
                        prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pocEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'POC Email *',
                        prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.]+$')
                            .hasMatch(v.trim())) { return 'Invalid email'; }
                        return null;
                      }),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true)),
                  ],

                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () {
                        setState(() => _editing = false);
                        _prefill();
                        _prefillBusiness();
                      },
                      child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(child: GradientButton(
                      label: 'Save Changes',
                      loading: auth.loading ||
                          context.watch<VendorProvider>().loading,
                      onPressed: _save)),
                  ]),
                ],
              ),
            ),
          ] else ...[
            _InfoCard('Account Details', [
              ['Role',         u.role],
              ['Status',       u.status],
              ['Member Since', u.createdAt.substring(0, 10)],
            ]),
            if (isVendor) ...[
              const SizedBox(height: 16),
              const _VendorBusinessCard(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppTheme.rose),
                label: const Text('Sign Out',
                    style: TextStyle(color: AppTheme.rose)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.rose),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                })),
          ],
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
  );

  Widget _cityField() => TextFormField(
    controller: _cityCtrl,
    readOnly: true,
    onTap: _citiesLoading ? null : _openCityPicker,
    decoration: InputDecoration(
      labelText: 'City *',
      prefixIcon: const Icon(Icons.location_city_outlined),
      suffixIcon: _citiesLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: Colors.grey),
    ),
    validator: (_) => _selectedCity == null ? 'City is required' : null,
  );
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
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      const Divider(height: 20),
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          Text(r[0],
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(child: Text(r[1],
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.right)),
        ]))),
    ]),
  );
}

class _VendorBusinessCard extends StatelessWidget {
  const _VendorBusinessCard();

  @override
  Widget build(BuildContext context) {
    final vendor  = context.watch<VendorProvider>();
    final profile = vendor.myProfile;

    if (vendor.loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.violet));
    }
    if (profile == null) return const SizedBox.shrink();

    final statusColor = switch (profile.onboardingStatus) {
      'Approved' => AppTheme.emerald,
      'Rejected' => AppTheme.rose,
      _          => AppTheme.amber,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Business Details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20)),
            child: Text(profile.onboardingStatus,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const Divider(height: 20),
        _row('Business Name', profile.businessName),
        _row('Business Type', profile.businessType),
        ..._addressRows(context.watch<AuthProvider>().user?.address ?? ''),
        _row('POC Name',  profile.pocName),
        _row('POC Phone', profile.pocPhone),
        _row('POC Email', profile.pocEmail),
        _row('GST Number', profile.gstNumber ?? '—'),
        if (profile.description != null && profile.description!.isNotEmpty)
          _blockRow('Description', profile.description!),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Flexible(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          textAlign: TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _blockRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 3),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  List<Widget> _addressRows(String address) {
    if (address.isEmpty) return [];
    final parts = address.split(', ');
    String addr1 = '', addr2 = '', city = '', state = '', pin = '';
    if (parts.length >= 3 && RegExp(r'^[1-9][0-9]{5}$').hasMatch(parts.last)) {
      pin   = parts.last;
      state = parts[parts.length - 2];
      city  = parts[parts.length - 3];
      final addrParts = parts.sublist(0, parts.length - 3);
      addr1 = addrParts.isNotEmpty ? addrParts.first : '';
      addr2 = addrParts.length > 1 ? addrParts.sublist(1).join(', ') : '';
    } else {
      addr1 = address;
    }
    return [
      if (addr1.isNotEmpty) _row('Address Line 1', addr1),
      if (addr2.isNotEmpty) _row('Address Line 2', addr2),
      if (city.isNotEmpty)  _row('City',           city),
      if (state.isNotEmpty) _row('State',          state),
      if (pin.isNotEmpty)   _row('Pincode',        pin),
    ];
  }
}
