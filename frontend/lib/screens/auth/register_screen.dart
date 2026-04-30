import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addr1Ctrl   = TextEditingController();
  final _addr2Ctrl   = TextEditingController();
  final _stateCtrl   = TextEditingController();
  final _pinCtrl     = TextEditingController();
  final _gstCtrl     = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _cityMenuCtrl = TextEditingController();

  String  _selectedRole = 'Vendor';
  bool    _obscurePass  = true;
  bool    _obscureConf  = true;
  bool    _submitted    = false;
  bool    _hasAttempted = false;
  String? _documentName;

  // City autocomplete state
  String?                  _selectedCity;
  List<Map<String, String>> _cities        = [];
  bool                     _citiesLoading  = false;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _cityMenuCtrl.addListener(() {
      if (_selectedCity != null && _cityMenuCtrl.text != _selectedCity) {
        setState(() {
          _selectedCity = null;
          _stateCtrl.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_firstCtrl, _lastCtrl, _phoneCtrl,
                     _addr1Ctrl, _addr2Ctrl, _stateCtrl, _pinCtrl,
                     _gstCtrl, _emailCtrl, _passCtrl, _confirmCtrl,
                     _cityMenuCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Cities ──────────────────────────────────────────────────────────────────

  Future<void> _loadCities() async {
    setState(() => _citiesLoading = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.cities));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _cities = data
              .map((item) => {
                    'city':  item['city']  as String,
                    'state': item['state'] as String,
                  })
              .toList();
        });
      }
    } catch (_) {
      // city list unavailable — user can still type
    } finally {
      setState(() => _citiesLoading = false);
    }
  }

  Widget _cityDropdown() => FormField<String>(
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (_) =>
        _selectedCity == null && _hasAttempted ? 'City is required' : null,
    builder: (state) => DropdownMenu<String>(
      controller:        _cityMenuCtrl,
      enableSearch:      true,
      requestFocusOnTap: true,
      expandedInsets:    EdgeInsets.zero,
      label:             const Text('City *'),
      errorText:         state.errorText,
      trailingIcon: _citiesLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)))
          : const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: Colors.grey),
      filterCallback: (entries, filter) => entries
          .where((e) => e.label.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      onSelected: (String? city) {
        if (city == null) return;
        final match = _cities.firstWhere((c) => c['city'] == city);
        setState(() {
          _selectedCity   = city;
          _stateCtrl.text = match['state']!;
        });
        state.didChange(city);
        _formKey.currentState?.validate();
      },
      dropdownMenuEntries: _cities
          .map((c) => DropdownMenuEntry<String>(
              value: c['city']!, label: c['city']!))
          .toList(),
    ),
  );

  // ── Document picker ─────────────────────────────────────────────────────────

  void _pickDocument() {
    final input = html.FileUploadInputElement()
      ..accept = '.pdf,.jpg,.jpeg,.png,.doc,.docx';
    input.click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file != null) setState(() => _documentName = file.name);
    });
  }

  Widget _documentPickerField() => GestureDetector(
    onTap: _pickDocument,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _documentName != null
                ? AppTheme.violet : const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12),
          color: _documentName != null
              ? AppTheme.violet.withValues(alpha: 0.04)
              : const Color(0xFFF9FAFB),
        ),
        child: Row(children: [
          Icon(
            _documentName != null
                ? Icons.description_outlined : Icons.upload_file_outlined,
            size: 20,
            color: _documentName != null ? AppTheme.violet : Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Document (Optional)',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: _documentName != null ? AppTheme.violet : Colors.grey)),
              const SizedBox(height: 2),
              Text(
                _documentName ?? 'PDF, JPG, PNG, DOC — tap to browse',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _documentName != null
                      ? FontWeight.w600 : FontWeight.normal,
                  color: _documentName != null
                      ? const Color(0xFF111827) : Colors.grey),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          if (_documentName != null)
            GestureDetector(
              onTap: () => setState(() => _documentName = null),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 18, color: Colors.grey)))
          else
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ]),
      ),
    ),
  );

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _req(String? v, String label) {
    if (v == null || v.trim().isEmpty) {
      return _hasAttempted ? '$label is required' : null;
    }
    return '';
  }

  String? _validateName(String? v, String label) {
    final r = _req(v, label);
    if (r != '') return r;
    return RegExp(r'^[A-Za-z ]{1,50}$').hasMatch(v!.trim())
        ? null : 'Letters only, max 50 chars';
  }

  String? _validateEmail(String? v) {
    final r = _req(v, 'Email');
    if (r != '') return r;
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
            .hasMatch(v!.trim())
        ? null : 'Enter a valid email address (e.g. name@domain.com)';
  }

  String? _validatePhone(String? v) {
    final r = _req(v, 'Phone number');
    if (r != '') return r;
    final digits = v!.trim().replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(\+91|91)?[6-9][0-9]{9}$').hasMatch(digits)
        ? null : 'Enter a valid 10-digit mobile number';
  }

  String? _validateGst(String? v) {
    final val = v?.trim().toUpperCase() ?? '';
    if (val.isEmpty) {
      if (_selectedRole == 'Vendor' && _hasAttempted) {
        return 'GST number is required for vendors';
      }
      return null;
    }
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$')
            .hasMatch(val)
        ? null : 'Invalid GST — expected format: 29ABCDE1234F1Z5';
  }

  String? _validateAddr1(String? v) {
    final r = _req(v, 'Address Line 1');
    if (r != '') return r;
    return v!.trim().length >= 5 ? null : 'Minimum 5 characters';
  }

  String? _validatePin(String? v) {
    final r = _req(v, 'Pincode');
    if (r != '') return r;
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(v!.trim())
        ? null : 'Enter a valid 6-digit pincode';
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

  String? _validatePassword(String? v) {
    final r = _req(v, 'Password');
    if (r != '') return r;
    final errs = <String>[];
    if (v!.length < 8)                         errs.add('8+ chars');
    if (!RegExp(r'[A-Z]').hasMatch(v))         errs.add('1 uppercase');
    if (!RegExp(r'[0-9]').hasMatch(v))         errs.add('1 number');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) errs.add('1 special char');
    return errs.isEmpty ? null : 'Needs: ${errs.join(', ')}';
  }

  String? _validateConfirm(String? v) {
    final r = _req(v, 'Confirm password');
    if (r != '') return r;
    return v == _passCtrl.text ? null : 'Passwords do not match';
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _hasAttempted = true);
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register({
      'first_name'   : _firstCtrl.text.trim(),
      'last_name'    : _lastCtrl.text.trim(),
      'email'        : _emailCtrl.text.trim(),
      'phone_number' : _phoneCtrl.text.trim(),
      'address'      : _combinedAddress,
      'gst_number'   : _gstCtrl.text.trim().isEmpty
                           ? null : _gstCtrl.text.trim().toUpperCase(),
      'document_name': _documentName,
      'password'     : _passCtrl.text,
      'role'         : _selectedRole,
    });
    if (!mounted) return;
    if (ok) {
      setState(() => _submitted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppTheme.rose));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_submitted) return _successScreen();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
                  const Text('Create Account', style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // Role selector
                      const Text('Register As',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Row(children: ['Vendor', 'Customer'].map((r) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _selectedRole = r;
                              if (r == 'Customer') {
                                _gstCtrl.clear();
                                _documentName = null;
                              }
                            }),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedRole == r
                                  ? AppTheme.violet : Colors.transparent,
                              foregroundColor: _selectedRole == r
                                  ? Colors.white : AppTheme.violet,
                              side: BorderSide(color: AppTheme.violet,
                                width: _selectedRole == r ? 0 : 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(r,
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                        ),
                      )).toList()),
                      const SizedBox(height: 16),

                      // Name
                      Row(children: [
                        Expanded(child: _field('First Name *', _firstCtrl,
                          validator: (v) => _validateName(v, 'First name'))),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Last Name *', _lastCtrl,
                          validator: (v) => _validateName(v, 'Last name'))),
                      ]),
                      const SizedBox(height: 12),

                      // Phone (+ GST for Vendor)
                      if (_selectedRole == 'Vendor')
                        Row(children: [
                          Expanded(child: _field('Phone Number *', _phoneCtrl,
                            type: TextInputType.phone,
                            validator: _validatePhone)),
                          const SizedBox(width: 12),
                          Expanded(child: _field('GST Number *', _gstCtrl,
                            validator: _validateGst,
                            inputFormatters: [_UpperCaseFormatter()])),
                        ])
                      else
                        _field('Phone Number *', _phoneCtrl,
                          type: TextInputType.phone,
                          validator: _validatePhone),
                      const SizedBox(height: 12),

                      // Document upload (Vendor only, optional)
                      if (_selectedRole == 'Vendor') ...[
                        _documentPickerField(),
                        const SizedBox(height: 12),
                      ],

                      // Address
                      _field('Address Line 1 *', _addr1Ctrl,
                        validator: _validateAddr1),
                      const SizedBox(height: 12),
                      _field('Address Line 2 (Optional)', _addr2Ctrl),
                      const SizedBox(height: 12),

                      // City (dropdown) + State (auto-filled, read-only)
                      Row(children: [
                        Expanded(child: _cityDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _stateCtrl,
                          readOnly:   true,
                          decoration: InputDecoration(
                            labelText: 'State',
                            filled:    _selectedCity != null,
                            fillColor: _selectedCity != null
                                ? AppTheme.violet.withValues(alpha: 0.05)
                                : null,
                          ),
                        )),
                      ]),
                      const SizedBox(height: 12),

                      _field('Pincode *', _pinCtrl,
                        type: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(6)],
                        validator: _validatePin),
                      const SizedBox(height: 12),

                      // Email
                      _field('Email Address *', _emailCtrl,
                        type: TextInputType.emailAddress,
                        validator: _validateEmail),
                      const SizedBox(height: 12),

                      // Password + Confirm
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass
                                  ? Icons.visibility_off : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass))),
                          validator: _validatePassword)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConf,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConf
                                  ? Icons.visibility_off : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscureConf = !_obscureConf))),
                          validator: _validateConfirm)),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                          'Password: 8+ chars · 1 uppercase · 1 number · 1 special char',
                          style: TextStyle(color: AppTheme.violet, fontSize: 11))),
                      const SizedBox(height: 20),

                      GradientButton(
                        label: 'Create Account',
                        loading: auth.loading,
                        onPressed: _submit),
                      const SizedBox(height: 14),
                      Center(child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Already have an account? Sign In',
                          style: TextStyle(color: AppTheme.violet,
                            fontWeight: FontWeight.w600, fontSize: 13)))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _field(String label, TextEditingController ctrl, {
    TextInputType? type,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: type,
    inputFormatters: inputFormatters,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(labelText: label),
    validator: validator ?? (v) =>
        (v?.isNotEmpty == true || _hasAttempted) && (v?.isEmpty != false)
            ? 'Required' : null,
  );

  Widget _successScreen() => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.1),
              shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
              color: AppTheme.emerald, size: 40)),
          const SizedBox(height: 16),
          const Text('Account Created!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            _selectedRole == 'Vendor'
                ? 'Your vendor account is pending activation. Log in to complete onboarding.'
                : 'Your customer account is ready. You can now sign in.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Go to Login',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/login', (_) => false)),
        ]),
      )),
    ),
  );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) =>
      next.copyWith(text: next.text.toUpperCase(), selection: next.selection);
}
