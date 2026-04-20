import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/vendor_provider.dart';
import '../../models/vendor_profile.dart';

class BrowseVendorsScreen extends StatefulWidget {
  const BrowseVendorsScreen({super.key});
  @override State<BrowseVendorsScreen> createState() => _BrowseVendorsScreenState();
}

class _BrowseVendorsScreenState extends State<BrowseVendorsScreen> {
  final _searchCtrl = TextEditingController();
  String? _typeFilter;

  static const _types = ['Retail','Wholesale','Manufacturing','Services',
    'Food & Beverage','Technology','Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<VendorProvider>().loadApprovedVendors(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      businessType: _typeFilter);
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vendor  = context.watch<VendorProvider>();
    final vendors = vendor.approvedVendors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Browse Vendors', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text('${vendors.length} active vendor${vendors.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search vendors…',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _searchCtrl.clear(); _load(); })
                      : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onSubmitted: (_) => _load(),
                  onChanged: (v) { if (v.isEmpty) _load(); })),
              const SizedBox(width: 12),
              PopupMenuButton<String?>(
                initialValue: _typeFilter,
                onSelected: (v) { setState(() => _typeFilter = v); _load(); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                    color: _typeFilter == null ? Colors.white : AppTheme.violet.withOpacity(0.08)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_typeFilter ?? 'All Types',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: _typeFilter == null ? Colors.black87 : AppTheme.violet)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 16),
                  ])),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All Types')),
                  ..._types.map((t) => PopupMenuItem(value: t, child: Text(t))),
                ]),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: vendor.loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
            : vendors.isEmpty
              ? const Center(child: Text('No vendors found.', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 :
                                    MediaQuery.of(context).size.width > 500 ? 2 : 1,
                    childAspectRatio: 1.4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12),
                  itemCount: vendors.length,
                  itemBuilder: (_, i) => _VendorCard(vendors[i]))),
      ]),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final VendorProfile vp;
  const _VendorCard(this.vp);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.violet.withOpacity(0.15),
                child: Text(vp.businessName[0],
                  style: const TextStyle(color: AppTheme.violet, fontWeight: FontWeight.bold, fontSize: 18))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vp.businessName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text(vp.businessType,
                    style: const TextStyle(fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.w700))),
              ])),
            ]),
            const SizedBox(height: 10),
            if (vp.description != null && vp.description!.isNotEmpty)
              Text(vp.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [
              const Icon(Icons.email_outlined, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(vp.pocEmail,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              CircleAvatar(radius: 30,
                backgroundColor: AppTheme.violet.withOpacity(0.15),
                child: Text(vp.businessName[0],
                  style: const TextStyle(color: AppTheme.violet, fontWeight: FontWeight.bold, fontSize: 22))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vp.businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(vp.businessType, style: const TextStyle(color: Colors.grey)),
              ])),
            ]),
            const SizedBox(height: 20),
            if (vp.description != null && vp.description!.isNotEmpty) ...[
              const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(vp.description!, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
            ],
            const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _row(Icons.person_outline,    vp.pocName),
            _row(Icons.phone_outlined,    vp.pocPhone),
            _row(Icons.email_outlined,    vp.pocEmail),
            _row(Icons.location_on_outlined, vp.businessAddress),
            if (vp.gstNumber != null) _row(Icons.receipt_long_outlined, vp.gstNumber!),
          ]),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}
