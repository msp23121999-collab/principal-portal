import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/admin_supabase_service.dart';
import '../utils/file_downloader.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});
  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _searchQuery = '';
  String _severityFilter = 'All';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await AdminSupabaseService.fetchAuditEntries();
    if (mounted) setState(() { _logs = data; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _logs;
    if (_searchQuery.isNotEmpty) list = list.where((l) => jsonEncode(l).toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    if (_severityFilter != 'All') {
      final levelFilter = _severityFilter == 'Critical' ? 'ERROR' : _severityFilter == 'Warning' ? 'WARN' : 'INFO';
      list = list.where((l) => (l['level'] ?? 'INFO') == levelFilter).toList();
    }
    return list;
  }

  void _showAddModal() {
    final actionCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final resourceCtrl = TextEditingController();
    var severity = 'Informational';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('Add Audit Entry', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: 'Action', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'User', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: resourceCtrl, decoration: const InputDecoration(labelText: 'Resource', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: severity, isExpanded: true, decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()), items: ['Informational','Warning','Critical'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => ss(() => severity = v!)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white), onPressed: () async {
          Navigator.pop(ctx);
          await AdminSupabaseService.addAuditEntry({
            'description': actionCtrl.text.trim().isNotEmpty
                ? '${actionCtrl.text.trim()} on ${resourceCtrl.text.trim()}'
                : 'Admin action performed',
            'operator_name': userCtrl.text.trim().isNotEmpty ? userCtrl.text.trim() : 'Admin System',
            'level': severity == 'Critical' ? 'ERROR' : severity == 'Warning' ? 'WARN' : 'INFO',
            'timestamp': DateTime.now().toIso8601String(),
          });
          _loadData();
        }, child: const Text('Add')),
      ],
    )));
  }

  Future<void> _delete(Map<String, dynamic> log) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Entry?'), content: const Text('Remove this audit log entry?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true && log['id'] != null) { await AdminSupabaseService.deleteAuditEntry(log['id'].toString()); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          SizedBox(height: 4),
          Text('Track all system events and admin actions', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ]),
        Row(children: [
          OutlinedButton.icon(onPressed: () async { final csv = _logs.map((l) => '${l['id']},${l['actor_name'] ?? ''},${l['action'] ?? ''},${l['resource'] ?? ''},${l['severity'] ?? ''},${l['created_at'] ?? ''}').join('\n'); FileDownloader.downloadCSV('id,actor,action,resource,severity,timestamp\n$csv', 'audit_log.csv'); }, icon: const Icon(Icons.download_rounded, size: 18), label: const Text('Export CSV')),
          const SizedBox(width: 12),
          ElevatedButton.icon(onPressed: _showAddModal, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Add Entry'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
        ]),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        _stat('Total Events', '${_logs.length}', Icons.receipt_long_rounded, const Color(0xFF0052CC)),
        const SizedBox(width: 12),
        _stat('Critical', '${_logs.where((l) => (l['level'] ?? '') == 'ERROR').length}', Icons.error_rounded, const Color(0xFFDC2626)),
        const SizedBox(width: 12),
        _stat('Warnings', '${_logs.where((l) => (l['level'] ?? '') == 'WARN').length}', Icons.warning_rounded, const Color(0xFFD97706)),
        const SizedBox(width: 12),
        _stat('Info', '${_logs.where((l) => (l['level'] ?? '') == 'INFO').length}', Icons.info_rounded, const Color(0xFF16A34A)),
      ]),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: 'Search audit logs...', prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white))),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(10)), child: DropdownButton<String>(value: _severityFilter, items: ['All','Informational','Warning','Critical'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _severityFilter = v!)))),
      ]),
      const SizedBox(height: 20),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
      else Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: filtered.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFCBD5E1)), SizedBox(height: 12), Text('No audit logs found', style: TextStyle(color: Color(0xFF64748B)))])))
      : SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)), columnSpacing: 16, columns: const [DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('User', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Resource', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Severity', style: TextStyle(fontWeight: FontWeight.bold))), DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)))], rows: filtered.take(100).map((l) {
        final level = l['level'] ?? 'INFO';
        final sev = level == 'ERROR' ? 'Critical' : level == 'WARN' ? 'Warning' : 'Informational';
        final sevColor = level == 'ERROR' ? const Color(0xFFDC2626) : level == 'WARN' ? const Color(0xFFD97706) : const Color(0xFF16A34A);
        final ts = l['timestamp']?.toString() ?? '';
        return DataRow(cells: [
          DataCell(Text(ts.length > 16 ? ts.substring(0, 16).replaceAll('T', ' ') : ts, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(l['operator_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text('Admin', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))])),
          DataCell(Text(l['description'] ?? '-', style: const TextStyle(fontSize: 13))),
          DataCell(Text(l['level'] ?? 'INFO', style: const TextStyle(fontSize: 13))),
          DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sevColor.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Text(sev, style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 12)))),
          DataCell(Row(children: [IconButton(icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)), onPressed: () => Clipboard.setData(ClipboardData(text: jsonEncode(l)))), IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)), onPressed: () => _delete(l))])),
        ]);
      }).toList()))),
    ])));
  }

  Widget _stat(String t, String v, IconData icon, Color c) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: c, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))]))])));
}
