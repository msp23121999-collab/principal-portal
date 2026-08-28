 import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_supabase_service.dart';

class ScholarshipsScreen extends ConsumerStatefulWidget {
  const ScholarshipsScreen({super.key});
  @override
  ConsumerState<ScholarshipsScreen> createState() => _ScholarshipsScreenState();
}

class _ScholarshipsScreenState extends ConsumerState<ScholarshipsScreen> {
  List<Map<String, dynamic>> _schemes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await AdminSupabaseService.fetchScholarshipSchemes();
    if (mounted) setState(() { _schemes = data; _loading = false; });
  }

  void _showAddEditModal([Map<String, dynamic>? ex]) {
    final nameCtrl = TextEditingController(text: ex?['name'] ?? '');
    final providerCtrl = TextEditingController(text: ex?['provider'] ?? '');
    final amountCtrl = TextEditingController(text: ex?['amount']?.toString() ?? '');
    final eligCtrl = TextEditingController(text: ex?['eligibility_criteria'] ?? '');
    String category = ex?['category'] ?? 'merit';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: Text(ex == null ? 'Add Scholarship Scheme' : 'Edit Scholarship Scheme', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Scheme Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: providerCtrl, decoration: const InputDecoration(labelText: 'Provider / Authority', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(initialValue: category, isExpanded: true, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: ['merit','need-based','government','sports','minority'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => ss(() => category = v!))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: eligCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Eligibility Criteria', border: OutlineInputBorder())),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white), onPressed: () async {
          Navigator.pop(ctx);
          final payload = {'name': nameCtrl.text.trim(), 'provider': providerCtrl.text.trim(), 'amount': double.tryParse(amountCtrl.text.trim()), 'category': category, 'eligibility_criteria': eligCtrl.text.trim()};
          if (ex == null) {
            await AdminSupabaseService.addScholarshipScheme(payload);
          } else {
            await AdminSupabaseService.updateScholarshipScheme(ex['id'] as String, payload);
          }
          _loadData();
        }, child: Text(ex == null ? 'Add' : 'Update')),
      ],
    )));
  }

  Future<void> _delete(Map<String, dynamic> scheme) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Scheme?'), content: Text('Delete "${scheme['name']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true) { await AdminSupabaseService.deleteScholarshipScheme(scheme['id'] as String); _loadData(); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Scholarship & Financial Aid', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          SizedBox(height: 4),
          Text('Manage government and merit scholarship schemes', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ]),
        ElevatedButton.icon(onPressed: _showAddEditModal, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Scheme'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
      const SizedBox(height: 20),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator())) else if (_schemes.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(60), child: Column(children: [Icon(Icons.card_giftcard_rounded, size: 64, color: Color(0xFFCBD5E1)), SizedBox(height: 12), Text('No scholarship schemes found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16))]))) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 380, childAspectRatio: 1.5, crossAxisSpacing: 16, mainAxisSpacing: 16), itemCount: _schemes.length, itemBuilder: (ctx, i) {
        final s = _schemes[i];
        final catColor = s['category'] == 'government' ? const Color(0xFF0052CC) : s['category'] == 'merit' ? const Color(0xFF16A34A) : const Color(0xFF9333EA);
        return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.card_giftcard_rounded, color: catColor, size: 20)), const SizedBox(width: 10), Expanded(child: Text(s['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis)), PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _showAddEditModal(s); else if (v == 'delete') _delete(s); }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('Edit')), const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red)))])]),
          const SizedBox(height: 10),
          if ((s['provider'] ?? '').isNotEmpty) Text('Provider: ${s['provider']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          if (s['amount'] != null) Text('Amount: ₹${s['amount']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(s['category'] ?? '-', style: TextStyle(color: catColor, fontWeight: FontWeight.bold, fontSize: 11))),
        ]));
      }),
    ])));
}

