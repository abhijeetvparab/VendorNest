import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                  const Text('Forgot Password', style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                      blurRadius: 24, offset: const Offset(0, 8))]),
                  child: _sent ? _sentView() : _formView(auth),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView(AuthProvider auth) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 64, height: 64,
        decoration: BoxDecoration(color: AppTheme.violet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.lock_reset, color: AppTheme.violet, size: 32)),
      const SizedBox(height: 16),
      const Text('Reset Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text("Enter your email and we'll send a reset link.",
        style: TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email Address',
          prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 20),
      GradientButton(
        label: 'Send Reset Link',
        loading: auth.loading,
        onPressed: _emailCtrl.text.contains('@') ? () async {
          final ok = await context.read<AuthProvider>().forgotPassword(_emailCtrl.text.trim());
          if (ok && mounted) setState(() => _sent = true);
        } : null),
    ],
  );

  Widget _sentView() => Column(children: [
    Container(width: 72, height: 72,
      decoration: BoxDecoration(color: AppTheme.emerald.withOpacity(0.1), shape: BoxShape.circle),
      child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.emerald, size: 40)),
    const SizedBox(height: 16),
    const Text('Check Your Email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 8),
    Text("We sent a reset link to ${_emailCtrl.text}.",
      style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    GradientButton(
      label: 'Back to Login',
      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false)),
  ]);
}
