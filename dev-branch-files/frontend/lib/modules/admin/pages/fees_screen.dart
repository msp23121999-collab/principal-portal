import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_supabase_service.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});
  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  List<Map<String, dynamic>> _finance = [];
  List<Map<String, dynamic>> _feeStatus = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final finance = await AdminSupabaseService.fetchMonthlyFinance();
    final status = await AdminSupabaseService.fetchDepartmentFeeStatus();
    if (mounted) setState(() { _finance = finance; _feeStatus = status; _loading = false; });
  }

  void _showAddModal() {
    final monthCtrl = TextEditingController();
    final collectedCtrl = TextEditingController();
    final pendingCtrl = TextEditingController();
    var mode = 'Online Banking';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('Add Fee Record', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 460, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: monthCtrl, decoration: const InputDecoration(labelText: 'Month (e.g. Aug 2026)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: collectedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Collected (₹)', border: OutlineInputBorder()))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: pendingCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pending (₹)', border: OutlineInputBorder()))),
        ]),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: mode, isExpanded: true, decoration: const InputDecoration(labelText: 'Primary Mode', border: OutlineInputBorder()), items: ['Online Banking','UPI','DD','Cash','Cheque'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => ss(() => mode = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white), onPressed: () async {
          Navigator.pop(ctx);
          await AdminSupabaseService.addMonthlyFinance({'month': monthCtrl.text.trim(), 'collected': double.tryParse(collectedCtrl.text.trim()) ?? 0, 'pending': double.tryParse(pendingCtrl.text.trim()) ?? 0, 'primary_mode': mode, 'created_at': DateTime.now().toIso8601String()});
          _loadData();
        }, child: const Text('Add')),
      ],
    )));
  }

  Future<void> _delete(Map<String, dynamic> rec) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Record?'), content: Text('Delete record for "${rec['month'] ?? rec['id']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true) { await AdminSupabaseService.deleteMonthlyFinance(rec['id'] as String); _loadData(); }
  }

  String _fmt(dynamic v) { if (v == null) return '-'; final d = double.tryParse(v.toString()); if (d == null) return v.toString(); if (d >= 10000000) return '₹${(d / 10000000).toStringAsFixed(2)} Cr'; if (d >= 100000) return '₹${(d / 100000).toStringAsFixed(2)} L'; return '₹${d.toStringAsFixed(0)}'; }

  @override
  Widget build(BuildContext context) {
    final totalCollected = _finance.fold<double>(0, (acc, r) => acc + (double.tryParse(r['collected']?.toString() ?? '0') ?? 0));
    final totalPending = _finance.fold<double>(0, (acc, r) => acc + (double.tryParse(r['pending']?.toString() ?? '0') ?? 0));
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fee Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          SizedBox(height: 4),
          Text('Track monthly fee collections and department-wise status', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ]),
        ElevatedButton.icon(onPressed: _showAddModal, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Fee Record'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        _stat('Total Collected', _fmt(totalCollected), Icons.account_balance_wallet_rounded, const Color(0xFF16A34A)),
        const SizedBox(width: 12),
        _stat('Total Pending', _fmt(totalPending), Icons.pending_actions_rounded, const Color(0xFFDC2626)),
        const SizedBox(width: 12),
        _stat('Records', '${_finance.length}', Icons.receipt_long_rounded, const Color(0xFF0052CC)),
        const SizedBox(width: 12),
        _stat('Departments', '${_feeStatus.length}', Icons.business_rounded, const Color(0xFF9333EA)),
      ]),
      const SizedBox(height: 24),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()))
      else ...[
        const Text('Monthly Finance Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 12),
        if (_finance.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No records found', style: TextStyle(color: Color(0xFF64748B))))) else Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), columnSpacing: 16, columns: const [DataColumn(label: Text('Month', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Collected', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)))], rows: _finance.map((r) => DataRow(cells: [DataCell(Text(r['month'] ?? r['created_at']?.toString().substring(0,7) ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))), DataCell(Text(_fmt(r['collected']), style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold))), DataCell(Text(_fmt(r['pending']), style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold))), DataCell(Text(r['primary_mode'] ?? r['mode'] ?? '-')), DataCell(IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)), onPressed: () => _delete(r)))])).toList()))),
        if (_feeStatus.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Department Fee Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), columnSpacing: 16, columns: _feeStatus.isNotEmpty ? _feeStatus.first.keys.where((k) => !['id','created_at','updated_at'].contains(k)).map((k) => DataColumn(label: Text(k.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList() : [], rows: _feeStatus.map((r) => DataRow(cells: r.entries.where((e) => !['id','created_at','updated_at'].contains(e.key)).map((e) => DataCell(Text('${e.value ?? '-'}'))).toList())).toList()))),
        ],
      ],
    ])));
  }

  Widget _stat(String t, String v, IconData icon, Color c) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: c, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))]))])));
}
