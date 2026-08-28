import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_supabase_service.dart';

class ApprovalWorkflowScreen extends ConsumerStatefulWidget {
  const ApprovalWorkflowScreen({super.key});
  @override
  ConsumerState<ApprovalWorkflowScreen> createState() => _ApprovalWorkflowScreenState();
}

class _ApprovalWorkflowScreenState extends ConsumerState<ApprovalWorkflowScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await AdminSupabaseService.fetchApprovalRequests();
    if (mounted) setState(() { _requests = data; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered => _filter == 'All' ? _requests : _requests.where((r) => (r['status'] ?? 'Pending').toLowerCase() == _filter.toLowerCase()).toList();

  void _showAddModal() {
    final titleCtrl = TextEditingController();
    final reqCtrl = TextEditingController();
    final sumCtrl = TextEditingController();
    var category = 'academic';
    var priority = 'normal';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => AlertDialog(
      title: const Text('New Approval Request', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: reqCtrl, decoration: const InputDecoration(labelText: 'Requester Name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: sumCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Summary', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: category, isExpanded: true, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: ['academic','event','financial','administrative'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => ss(() => category = v!))),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(initialValue: priority, isExpanded: true, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), items: ['low','normal','high','urgent'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => ss(() => priority = v!))),
        ]),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white), onPressed: () async {
          Navigator.pop(ctx);
          await AdminSupabaseService.addApprovalRequest({
            'request_title': titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'New Request',
            'requested_by': reqCtrl.text.trim().isNotEmpty ? reqCtrl.text.trim() : 'Admin',
            'module': category,
            'status': 'Pending',
            'submitted_date': DateTime.now().toIso8601String(),
          });
          _loadData();
        }, child: const Text('Submit')),
      ],
    )));
  }

  Future<void> _updateDecision(Map<String, dynamic> req, String decision) async {
    if (req['id'] != null) {
      await AdminSupabaseService.updateApprovalRequest(req['id'].toString(), {'status': decision});
      _loadData();
    }
  }

  Future<void> _delete(Map<String, dynamic> req) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete?'), content: Text('Delete "${req['title']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true && req['id'] != null) { await AdminSupabaseService.deleteApprovalRequest(req['id'].toString()); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Approvals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            SizedBox(height: 4),
            Text('Manage approval requests and decisions', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ]),
          Row(children: [
            ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Refresh'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2E8F0), foregroundColor: const Color(0xFF334155), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(width: 12),
            ElevatedButton.icon(onPressed: _showAddModal, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('New Request'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          ]),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _stat('Total', '${_requests.length}', Icons.inbox_rounded, const Color(0xFF0052CC)),
          const SizedBox(width: 12),
          _stat('Pending', '${_requests.where((r) => (r['status'] ?? 'Pending') == 'Pending').length}', Icons.pending_rounded, const Color(0xFFD97706)),
          const SizedBox(width: 12),
          _stat('Approved', '${_requests.where((r) => r['status'] == 'Approved').length}', Icons.check_circle_rounded, const Color(0xFF16A34A)),
          const SizedBox(width: 12),
          _stat('Rejected', '${_requests.where((r) => r['status'] == 'Rejected').length}', Icons.cancel_rounded, const Color(0xFFDC2626)),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 8, children: ['All','pending','approved','rejected'].map((f) => ChoiceChip(label: Text(f[0].toUpperCase() + f.substring(1)), selected: _filter == f, onSelected: (_) => setState(() => _filter = f), selectedColor: const Color(0xFF0052CC), labelStyle: TextStyle(color: _filter == f ? Colors.white : const Color(0xFF64748B)))).toList()),
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (filtered.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Icon(Icons.inbox_rounded, size: 64, color: Color(0xFFCBD5E1)), SizedBox(height: 12), Text('No approval requests found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16))]))) else ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (ctx, i) {
          final r = filtered[i];
          final decision = (r['status'] ?? 'Pending').toLowerCase();
          final decisionColor = decision == 'approved' ? const Color(0xFF16A34A) : decision == 'rejected' ? const Color(0xFFDC2626) : const Color(0xFFD97706);
          return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['request_title'] ?? r['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4), Text('${r['requested_by'] ?? r['requester_name'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))]),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: decisionColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text((r['status'] ?? 'Pending').toUpperCase(), style: TextStyle(color: decisionColor, fontWeight: FontWeight.bold, fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)), child: Text(r['module'] ?? r['category'] ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
              const Spacer(),
              if (decision == 'pending') ...[
                TextButton(onPressed: () => _updateDecision(r, 'Approved'), child: const Text('Approve', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold))),
                TextButton(onPressed: () => _updateDecision(r, 'Rejected'), child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold))),
              ],
              IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)), onPressed: () => _delete(r)),
            ]),
          ]));
        }),
      ])),
    );
  }

  Widget _stat(String t, String v, IconData icon, Color c) => Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: c, size: 20)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))]))])));
}
