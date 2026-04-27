import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _passFocus  = FocusNode();
  bool    _obscure  = true;
  String? _selectedRole;

  Future<void> _login(String email, String password) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(email, password);
    if (!mounted) return;
    if (ok) {
      final role = auth.user?.role ?? '';
      if (_selectedRole != role) {
        await auth.logout();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Incorrect role selected. Please select "$role".'),
          backgroundColor: AppTheme.rose));
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppTheme.rose));
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _login(_emailCtrl.text.trim(), _passCtrl.text);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Login card centered in remaining space
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 32, offset: const Offset(0, 8))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Welcome back',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                              color: Color(0xFF111827))),
                          const SizedBox(height: 6),
                          const Text('Sign in to your account',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 32),
                          _formContent(auth),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formContent(AuthProvider auth) => Form(
    key: _formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _passFocus.requestFocus(),
        decoration: const InputDecoration(
          labelText: 'Email Address',
          prefixIcon: Icon(Icons.email_outlined)),
        validator: (v) => (v?.contains('@') ?? false) ? null : 'Enter valid email'),
      const SizedBox(height: 14),
      TextFormField(
        controller: _passCtrl,
        focusNode: _passFocus,
        obscureText: _obscure,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure))),
        validator: (v) => (v?.isNotEmpty ?? false) ? null : 'Enter password'),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: _selectedRole,
        decoration: const InputDecoration(
          labelText: 'Login As',
          prefixIcon: Icon(Icons.badge_outlined),
          hintText: 'Select your role'),
        items: const [
          DropdownMenuItem(value: 'Admin',    child: Text('Admin')),
          DropdownMenuItem(value: 'Vendor',   child: Text('Vendor')),
          DropdownMenuItem(value: 'Customer', child: Text('Customer')),
        ],
        onChanged: (v) => setState(() => _selectedRole = v),
        validator: (v) => v == null ? 'Please select a role' : null,
      ),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/forgot'),
          child: const Text('Forgot Password?',
            style: TextStyle(color: AppTheme.violet)))),
      const SizedBox(height: 8),
      GradientButton(label: 'Sign In', loading: auth.loading, onPressed: _submit),
      const SizedBox(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: const Text('Register',
            style: TextStyle(color: AppTheme.violet, fontWeight: FontWeight.bold))),
      ]),
    ]),
  );

}
