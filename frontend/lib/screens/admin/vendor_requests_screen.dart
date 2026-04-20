import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../models/vendor_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/role_chip.dart';

class VendorRequestsScreen extends StatefulWidget {
  const VendorRequestsScreen({super.key});
  @override State<VendorRequestsScreen> createState() => _VendorRequestsScreenState();
}

class _VendorRequestsScreenState extends State<VendorRequestsScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken ?? '';
      context.read<AdminProvider>().loadVendors(token);
    });
  }

  Future<void> _showReviewDialog(VendorProfile vp) async {
    final rejectCtrl  = TextEditingController();
    String? rejectErr;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.violet, AppTheme.purple]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Text(vp.businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _infoGrid(vp),
                const SizedBox(height: 16),
                if (vp.description != null && vp.description!.isNotEmpty) ...[
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
                    child: Text(vp.description!, style: const TextStyle(fontSize: 13))),
                  const SizedBox(height: 16),
                ],
                const Text('Rejection Reason (required if rejecting)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: rejectCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Explain why the application is being rejected…',
                    errorText: rejectErr,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose, foregroundColor: Colors.white),
              onPressed: () async {
                if (rejectCtrl.text.trim().isEmpty) {
                  setDialogState(() => rejectErr = 'Rejection reason is required');
                  return;
                }
                Navigator.pop(ctx);
                final token = context.read<AuthProvider>().accessToken ?? '';
                final ok = await context.read<AdminProvider>().rejectVendor(token, vp.id, rejectCtrl.text.trim());
                if (mounted) _snack(ok ? 'Application rejected.' : context.read<AdminProvider>().error ?? 'Error', ok ? null : AppTheme.rose);
              }),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                final token = context.read<AuthProvider>().accessToken ?? '';
                final ok = await context.read<AdminProvider>().approveVendor(token, vp.id);
                if (mounted) _snack(ok ? '${vp.businessName} approved! ✅' : context.read<AdminProvider>().error ?? 'Error', ok ? AppTheme.emerald : AppTheme.rose);
              }),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(VendorProfile vp) {
    final items = [
      ['Business Type',    vp.businessType],
      ['POC Name',         vp.pocName],
      ['POC Phone',        vp.pocPhone],
      ['POC Email',        vp.pocEmail],
      ['GST Number',       vp.gstNumber ?? '—'],
      ['Document',         vp.documentName ?? '—'],
      ['Submitted',        vp.submittedAt],
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5, mainAxisSpacing: 6, crossAxisSpacing: 6,
      children: items.map((i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i[0], style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(i[1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      )).toList(),
    );
  }

  void _snack(String msg, Color? color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final all   = admin.vendors;
    final displayed = _filter == 'All' ? all : all.where((v) => v.onboardingStatus == _filter).toList();
    final counts = {
      'All': all.length,
      'Pending':  all.where((v) => v.onboardingStatus == 'Pending').length,
      'Approved': all.where((v) => v.onboardingStatus == 'Approved').length,
      'Rejected': all.where((v) => v.onboardingStatus == 'Rejected').length,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Vendor Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text('${counts['Pending']} pending review', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['All','Pending','Approved','Rejected'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$f (${counts[f]})'),
                  selected: _filter == f,
                  selectedColor: AppTheme.violet,
                  labelStyle: TextStyle(
                    color: _filter == f ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _filter = f)),
              )).toList())),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: admin.loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
            : displayed.isEmpty
              ? const Center(child: Text('No applications found.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: displayed.length,
                  itemBuilder: (_, i) {
                    final vp = displayed[i];
                    final u  = admin.users.where((x) => x.id == vp.userId).firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.cyan.withOpacity(0.15),
                            child: Text(vp.businessName[0],
                              style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold, fontSize: 18))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(vp.businessName,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                              StatusChip(vp.onboardingStatus),
                            ]),
                            const SizedBox(height: 3),
                            Text('${u?.fullName ?? '—'} · ${vp.pocEmail}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            Text('📍 ${vp.businessAddress} · ${vp.submittedAt}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            if (vp.rejectionReason != null && vp.rejectionReason!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Rejected: "${vp.rejectionReason}"',
                                style: const TextStyle(color: AppTheme.rose, fontSize: 11)),
                            ],
                          ])),
                          if (vp.onboardingStatus == 'Pending') ...[
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _showReviewDialog(vp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.violet,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Text('Review', style: TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                        ]),
                      ),
                    );
                  }),
        ),
      ]),
    );
  }
}
