import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      context.read<VendorProvider>().loadMyProfile(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final vendor = context.watch<VendorProvider>();
    final profile = vendor.myProfile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, ${auth.user?.firstName}! 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const Text('Vendor Dashboard',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          if (vendor.loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.violet))
          else if (profile == null)
            _NoApplicationCard()
          else ...[
            _StatusCard(profile.onboardingStatus, profile.businessName,
              profile.rejectionReason),
            const SizedBox(height: 24),
            if (profile.onboardingStatus == 'Approved') ...[
              const Text('Business Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _DetailGrid(profile),
            ],
          ],
        ]),
      ),
    );
  }
}

class _NoApplicationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.violet.withValues(alpha: 0.2))),
      child: Column(children: [
        Container(width: 64, height: 64,
          decoration: BoxDecoration(
            color: AppTheme.violet.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.store_outlined, color: AppTheme.violet, size: 32)),
        const SizedBox(height: 16),
        const Text('No Application Yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'Submit your onboarding application to get your business approved on the platform.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Start Onboarding'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () {}),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String status;
  final String businessName;
  final String? rejectionReason;
  const _StatusCard(this.status, this.businessName, this.rejectionReason);

  @override
  Widget build(BuildContext context) {
    final cfg = switch (status) {
      'Approved' => (AppTheme.emerald, const Color(0xFFF0FDF4), Icons.check_circle_outline, 'Your application is approved! Your business is now live.'),
      'Rejected' => (AppTheme.rose,    const Color(0xFFFFF1F2), Icons.cancel_outlined,       'Your application was rejected.'),
      _          => (AppTheme.amber,   const Color(0xFFFFFBEB), Icons.hourglass_top_outlined, 'Your application is under review. We\'ll notify you soon.'),
    };
    final (color, bg, icon, msg) = cfg;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(businessName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(msg, style: TextStyle(color: color, fontSize: 13)),
          if (rejectionReason != null && rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Reason: $rejectionReason',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))),
      ]),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final dynamic profile;
  const _DetailGrid(this.profile);

  @override
  Widget build(BuildContext context) {
    final items = [
      ['Business Type',    profile.businessType],
      ['POC Name',         profile.pocName],
      ['POC Phone',        profile.pocPhone],
      ['POC Email',        profile.pocEmail],
      ['GST Number',       profile.gstNumber ?? '—'],
      ['Address',          profile.businessAddress],
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item[0], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(item[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      )).toList(),
    );
  }
}
