import 'package:flutter/material.dart';
import '../services/campus_services_backend.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';

class InventoryAssetsScreen extends StatefulWidget {
  const InventoryAssetsScreen({super.key});

  @override
  State<InventoryAssetsScreen> createState() => _InventoryAssetsScreenState();
}

class _InventoryAssetsScreenState extends State<InventoryAssetsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final data = await CampusServicesBackend.instance.getInventoryAssets();
    if (mounted) {
      setState(() {
        _items = data;
        _isLoading = false;
      });
    }
  }

  void _showAddAssetModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '10');
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    String category = 'IT Equipment';
    String status = 'In Stock';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add New Inventory Asset',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Item / Asset Name',
                        hintText: 'e.g. Dell OptiPlex 7090 Desktop',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: ['IT Equipment', 'Audio Visual', 'Networking', 'Lab Instruments', 'Furniture']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setModalState(() => category = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: ['In Stock', 'In Use', 'Maintenance', 'Retired']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setModalState(() => status = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: locationCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Location / Room',
                              hintText: 'CSE Lab 2',
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            validator: (v) => (int.tryParse(v ?? '') ?? -1) < 1 ? 'Enter count' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date (YYYY-MM-DD)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              await CampusServicesBackend.instance.addInventoryAsset({
                                'item_name': nameCtrl.text,
                                'category': category,
                                'location': locationCtrl.text,
                                'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                                'purchase_date': dateCtrl.text,
                                'status': status,
                              });
                              if (context.mounted) Navigator.of(context).pop();
                              _loadAssets();
                            }
                          },
                          child: const Text('Save Asset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory & Asset Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hardware, lab equipment, networking switches & campus asset tracking',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Add New Asset',
                  icon: Icons.inventory_2_rounded,
                  onPressed: _showAddAssetModal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Asset Inventory Log (public.inventory_assets)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadAssets,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No inventory assets found in database. Click "Add New Asset" to add one.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Table(
                      border: TableBorder.symmetric(
                        inside: const BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      children: [
                        TableRow(
                          decoration:
                              const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildHeader('ITEM NAME'),
                            _buildHeader('CATEGORY'),
                            _buildHeader('LOCATION'),
                            _buildHeader('QUANTITY'),
                            _buildHeader('PURCHASE DATE'),
                            _buildHeader('STATUS'),
                          ],
                        ),
                        ..._items.map(
                          (item) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  item['item_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['category'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['location'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['quantity']?.toString() ?? '0'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(item['purchase_date'] ?? 'N/A'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: AppStatusBadge(
                                  status: item['status'] ?? 'In Stock',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
