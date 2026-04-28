import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app_theme.dart';
import '../../../models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/gradient_button.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  List<String> _selectedUnits = [];
  bool _isAvailable    = true;
  bool _isSubscribable = false;
  bool _unitsError     = false;

  bool get _isEdit => widget.product != null;

  // Predefined common unit suggestions
  static const List<String> _suggestedUnits = [
    '100 G', '250 G', '500 G', '1 Kg', '2 Kg', '5 Kg',
    '100 ML', '250 ML', '500 ML', '1 Ltr', '2 Ltr', '5 Ltr',
    '1 Piece', '6 Pack', '12 Pack', '1 Dozen', '1 Box', '1 Set',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text   = p.name;
      _descCtrl.text   = p.description ?? '';
      _selectedUnits   = List<String>.from(p.units);
      _isAvailable     = p.isAvailable;
      _isSubscribable  = p.isSubscribable;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  void _toggleUnit(String unit) {
    setState(() {
      if (_selectedUnits.contains(unit)) {
        _selectedUnits.remove(unit);
      } else {
        _selectedUnits.add(unit);
      }
      if (_selectedUnits.isNotEmpty) _unitsError = false;
    });
  }

  void _addCustomUnit() {
    final v = _customUnitCtrl.text.trim();
    if (v.isEmpty) return;
    if (!_selectedUnits.contains(v)) {
      setState(() {
        _selectedUnits.add(v);
        _unitsError = false;
      });
    }
    _customUnitCtrl.clear();
  }

  void _removeUnit(String unit) => setState(() => _selectedUnits.remove(unit));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnits.isEmpty) {
      setState(() => _unitsError = true);
      return;
    }

    final token    = context.read<AuthProvider>().accessToken!;
    final provider = context.read<ProductProvider>();
    final payload  = {
      'name':            _nameCtrl.text.trim(),
      'description':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'units':           _selectedUnits,
      'is_available':    _isAvailable,
      'is_subscribable': _isSubscribable,
    };

    final ok = _isEdit
        ? await provider.updateProduct(token, widget.product!.id, payload)
        : await provider.createProduct(token, payload);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to save product'),
        backgroundColor: AppTheme.rose,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ProductProvider>().loading;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    title: 'Product Details',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _field(
                        controller: _nameCtrl,
                        label: 'Product Name',
                        icon: Icons.label_outline,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: _descCtrl,
                        label: 'Description (optional)',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        validator: (v) {
                          if (v != null && v.trim().length > 500) {
                            return 'Max 500 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUnitsSection(),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Availability & Subscription',
                    icon: Icons.toggle_on_outlined,
                    children: [
                      _toggleTile(
                        title: 'Available',
                        subtitle: 'Product is currently in stock / offered',
                        value: _isAvailable,
                        activeColor: AppTheme.emerald,
                        onChanged: (v) => setState(() => _isAvailable = v),
                      ),
                      const Divider(height: 20, color: Color(0xFFE5E7EB)),
                      _toggleTile(
                        title: 'Subscribable',
                        subtitle: 'Customers can subscribe to this product',
                        value: _isSubscribable,
                        activeColor: AppTheme.violet,
                        onChanged: (v) => setState(() => _isSubscribable = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: _isEdit ? 'Save Changes' : 'Add Product',
                    loading: loading,
                    onPressed: _save,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitsSection() {
    final unselected = _suggestedUnits
        .where((u) => !_selectedUnits.contains(u))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _unitsError ? AppTheme.rose : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.straighten_outlined, size: 16, color: AppTheme.violet),
          SizedBox(width: 8),
          Text('Available Units',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151))),
          Spacer(),
          Text('tap to add / remove',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
        if (_unitsError) ...[
          const SizedBox(height: 6),
          const Text('At least one unit is required',
              style: TextStyle(fontSize: 12, color: AppTheme.rose)),
        ],

        // Selected units
        if (_selectedUnits.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Selected',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: _selectedUnits.map((u) => _selectedChip(u)).toList()),
        ],

        // Quick-add suggestions
        if (unselected.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Quick add',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: unselected.map((u) => _suggestionChip(u)).toList(),
          ),
        ],

        // Custom unit input
        const SizedBox(height: 16),
        const Text('Custom unit',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _customUnitCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 750 ML, Half Ltr…',
                prefixIcon: Icon(Icons.add_circle_outline, size: 18),
                isDense: true,
              ),
              onFieldSubmitted: (_) => _addCustomUnit(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _addCustomUnit,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.violet,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Add'),
          ),
        ]),
      ]),
    );
  }

  Widget _selectedChip(String label) => InputChip(
    label: Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
    backgroundColor: AppTheme.violet,
    deleteIconColor: Colors.white70,
    onDeleted: () => _removeUnit(label),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _suggestionChip(String label) => ActionChip(
    label: Text(label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
    avatar: const Icon(Icons.add, size: 14, color: Color(0xFF6B7280)),
    backgroundColor: const Color(0xFFF3F4F6),
    side: const BorderSide(color: Color(0xFFE5E7EB)),
    onPressed: () => _toggleUnit(label),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: AppTheme.violet),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: validator,
      );

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color activeColor,
    required void Function(bool) onChanged,
  }) =>
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
        ),
      ]);
}
