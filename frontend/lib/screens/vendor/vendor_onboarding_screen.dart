import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/gradient_button.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});
  @override State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _bizNameCtrl    = TextEditingController();
  final _bizAddrCtrl    = TextEditingController();
  final _pocNameCtrl    = TextEditingController();
  final _pocPhoneCtrl   = TextEditingController();
  final _pocEmailCtrl   = TextEditingController();
  final _gstCtrl        = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _docNameCtrl    = TextEditingController();
  String _bizType = 'Retail';

  static const _bizTypes = ['Retail', 'Wholesale', 'Manufacturing', 'Services', 'Food & Beverage', 'Technology', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      context.read<VendorProvider>().loadMyProfile(token).then((_) {
        final p = context.read<VendorProvider>().myProfile;
        if (p != null) _prefill(p);
      });
    });
  }

  void _prefill(dynamic p) {
    _bizNameCtrl.text  = p.businessName;
    _bizAddrCtrl.text  = p.businessAddress;
    _pocNameCtrl.text  = p.pocName;
    _pocPhoneCtrl.text = p.pocPhone;
    _pocEmailCtrl.text = p.pocEmail;
    _gstCtrl.text      = p.gstNumber ?? '';
    _descCtrl.text     = p.description ?? '';
    _docNameCtrl.text  = p.documentName ?? '';
    setState(() => _bizType = p.businessType);
  }

  @override
  void dispose() {
    for (final c in [_bizNameCtrl,_bizAddrCtrl,_pocNameCtrl,_pocPhoneCtrl,
                     _pocEmailCtrl,_gstCtrl,_descCtrl,_docNameCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().accessToken ?? '';
    final ok = await context.read<VendorProvider>().submitOnboarding(token, {
      'business_name':    _bizNameCtrl.text.trim(),
      'business_type':    _bizType,
      'business_address': _bizAddrCtrl.text.trim(),
      'poc_name':         _pocNameCtrl.text.trim(),
      'poc_phone':        _pocPhoneCtrl.text.trim(),
      'poc_email':        _pocEmailCtrl.text.trim(),
      'gst_number':       _gstCtrl.text.trim().isEmpty ? null : _gstCtrl.text.trim(),
      'description':      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'document_name':    _docNameCtrl.text.trim().isEmpty ? null : _docNameCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Application submitted!' : context.read<VendorProvider>().error ?? 'Error'),
        backgroundColor: ok ? AppTheme.emerald : AppTheme.rose));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor  = context.watch<VendorProvider>();
    final profile = vendor.myProfile;
    final status  = profile?.onboardingStatus;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Onboarding', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(
            status == null ? 'Submit your business application' :
            status == 'Pending' ? 'Application under review' :
            status == 'Approved' ? 'Application approved' : 'Application rejected — re-submit below',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          if (status == 'Pending') ...[
            _StatusBanner(AppTheme.amber, const Color(0xFFFFFBEB), Icons.hourglass_top_outlined,
              'Under Review',
              'Your application is being reviewed by our admin team. You\'ll be notified once a decision is made.'),
          ] else if (status == 'Approved') ...[
            _StatusBanner(AppTheme.emerald, const Color(0xFFF0FDF4), Icons.verified_outlined,
              'Application Approved',
              'Congratulations! Your business is now live on the platform.'),
          ] else ...[
            if (status == 'Rejected' && profile?.rejectionReason != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.rose.withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.rose),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Rejected: ${profile!.rejectionReason}',
                    style: const TextStyle(color: AppTheme.rose, fontSize: 13))),
                ])),
            _OnboardingForm(
              formKey: _formKey,
              bizNameCtrl: _bizNameCtrl, bizAddrCtrl: _bizAddrCtrl,
              pocNameCtrl: _pocNameCtrl, pocPhoneCtrl: _pocPhoneCtrl,
              pocEmailCtrl: _pocEmailCtrl, gstCtrl: _gstCtrl,
              descCtrl: _descCtrl, docNameCtrl: _docNameCtrl,
              bizType: _bizType, bizTypes: _bizTypes,
              onBizTypeChanged: (v) => setState(() => _bizType = v),
              onSubmit: _submit,
              loading: vendor.loading,
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color, bg;
  final IconData icon;
  final String title, msg;
  const _StatusBanner(this.color, this.bg, this.icon, this.title, this.msg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.3))),
    child: Row(children: [
      Icon(icon, color: color, size: 36),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        const SizedBox(height: 4),
        Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ])),
    ]),
  );
}

class _OnboardingForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController bizNameCtrl, bizAddrCtrl, pocNameCtrl,
      pocPhoneCtrl, pocEmailCtrl, gstCtrl, descCtrl, docNameCtrl;
  final String bizType;
  final List<String> bizTypes;
  final void Function(String) onBizTypeChanged;
  final Future<void> Function() onSubmit;
  final bool loading;

  const _OnboardingForm({
    required this.formKey,
    required this.bizNameCtrl, required this.bizAddrCtrl,
    required this.pocNameCtrl, required this.pocPhoneCtrl,
    required this.pocEmailCtrl, required this.gstCtrl,
    required this.descCtrl, required this.docNameCtrl,
    required this.bizType, required this.bizTypes,
    required this.onBizTypeChanged, required this.onSubmit, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('Business Information'),
        const SizedBox(height: 12),
        TextFormField(
          controller: bizNameCtrl,
          decoration: const InputDecoration(labelText: 'Business Name *', prefixIcon: Icon(Icons.store_outlined)),
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: bizType,
          decoration: const InputDecoration(labelText: 'Business Type *', prefixIcon: Icon(Icons.category_outlined)),
          items: bizTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => onBizTypeChanged(v!)),
        const SizedBox(height: 12),
        TextFormField(
          controller: bizAddrCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Business Address *', prefixIcon: Icon(Icons.location_on_outlined)),
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
        const SizedBox(height: 20),
        _section('Point of Contact'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextFormField(
            controller: pocNameCtrl,
            decoration: const InputDecoration(labelText: 'POC Name *'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null)),
          const SizedBox(width: 12),
          Expanded(child: TextFormField(
            controller: pocPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'POC Phone *'),
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null)),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: pocEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'POC Email *', prefixIcon: Icon(Icons.email_outlined)),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'Required';
            if (!v!.contains('@')) return 'Enter a valid email';
            return null;
          }),
        const SizedBox(height: 20),
        _section('Additional Details'),
        const SizedBox(height: 12),
        TextFormField(
          controller: gstCtrl,
          decoration: const InputDecoration(
            labelText: 'GST Number (optional)',
            prefixIcon: Icon(Icons.receipt_long_outlined),
            hintText: 'e.g. 22AAAAA0000A1Z5')),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Business Description (optional)',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true)),
        const SizedBox(height: 12),
        TextFormField(
          controller: docNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Document Name (optional)',
            prefixIcon: Icon(Icons.attach_file_outlined),
            hintText: 'e.g. business_registration.pdf')),
        const SizedBox(height: 28),
        GradientButton(label: 'Submit Application', loading: loading, onPressed: onSubmit),
      ]),
    );
  }

  Widget _section(String title) => Text(title,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF374151)));
}
