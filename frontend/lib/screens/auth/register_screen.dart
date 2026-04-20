import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _firstCtrl     = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _gstCtrl       = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  String _selectedRole = 'Vendor';
  bool   _obscurePass  = true;
  bool   _obscureConf  = true;
  bool   _submitted    = false;

  @override
  void dispose() {
    for (final c in [_firstCtrl,_lastCtrl,_phoneCtrl,_addressCtrl,_gstCtrl,_emailCtrl,_passCtrl,_confirmCtrl]) c.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    final errs = <String>[];
    if (v.length < 8)                              errs.add('8+ chars');
    if (!RegExp(r'[A-Z]').hasMatch(v))             errs.add('1 uppercase');
    if (!RegExp(r'[0-9]').hasMatch(v))             errs.add('1 number');
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v))      errs.add('1 special char');
    return errs.isEmpty ? null : 'Needs: ${errs.join(', ')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register({
      'first_name'  : _firstCtrl.text.trim(),
      'last_name'   : _lastCtrl.text.trim(),
      'email'       : _emailCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
      'address'     : _addressCtrl.text.trim(),
      'gst_number'  : _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim().toUpperCase(),
      'password'    : _passCtrl.text,
      'role'        : _selectedRole,
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 24, offset: const Offset(0, 8))]),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Role selector
                      const Text('Register As', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                      const SizedBox(height: 8),
                      Row(children: ['Vendor', 'Customer'].map((r) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedRole = r),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedRole == r ? AppTheme.violet : Colors.transparent,
                              foregroundColor: _selectedRole == r ? Colors.white : AppTheme.violet,
                              side: BorderSide(color: AppTheme.violet, width: _selectedRole == r ? 0 : 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12)),
                            child: Text(r, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ),
                      )).toList()),
                      const SizedBox(height: 16),

                      // Name row
                      Row(children: [
                        Expanded(child: _field('First Name', _firstCtrl,
                          validator: (v) => RegExp(r'^[A-Za-z ]{1,50}$').hasMatch(v?.trim() ?? '') ? null : 'Alpha only, max 50')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('Last Name', _lastCtrl,
                          validator: (v) => RegExp(r'^[A-Za-z ]{1,50}$').hasMatch(v?.trim() ?? '') ? null : 'Alpha only, max 50')),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field('Phone Number', _phoneCtrl,
                          type: TextInputType.phone,
                          validator: (v) => RegExp(r'^\+?[0-9]{10,15}$').hasMatch(v?.trim() ?? '') ? null : '10-15 digit phone')),
                        const SizedBox(width: 12),
                        Expanded(child: _field('GST Number (Optional)', _gstCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            return RegExp(r'^[0-9A-Za-z]{15}$').hasMatch(v.trim()) ? null : '15-char alphanumeric';
                          })),
                      ]),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address *'),
                        validator: (v) => (v?.trim().length ?? 0) >= 10 ? null : 'Min 10 characters',
                      ),
                      const SizedBox(height: 12),
                      _field('Email Address', _emailCtrl,
                        type: TextInputType.emailAddress,
                        validator: (v) => RegExp(r'\S+@\S+\.\S+').hasMatch(v ?? '') ? null : 'Valid email required'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                          validator: _validatePassword)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConf,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConf ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConf = !_obscureConf))),
                          validator: (v) => v == _passCtrl.text ? null : 'Passwords do not match')),
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
                      GradientButton(label: 'Create Account', loading: auth.loading, onPressed: _submit),
                      const SizedBox(height: 14),
                      Center(child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Already have an account? Sign In',
                          style: TextStyle(color: AppTheme.violet, fontWeight: FontWeight.w600, fontSize: 13)))),
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

  Widget _field(String label, TextEditingController ctrl, {
    TextInputType? type, String? Function(String?)? validator
  }) => TextFormField(
    controller: ctrl, keyboardType: type,
    decoration: InputDecoration(labelText: label),
    validator: validator ?? (v) => v?.isNotEmpty == true ? null : 'Required',
  );

  Widget _successScreen() => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
            decoration: BoxDecoration(color: AppTheme.emerald.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 40)),
          const SizedBox(height: 16),
          const Text('Account Created!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false)),
        ]),
      )),
    ),
  );
}
