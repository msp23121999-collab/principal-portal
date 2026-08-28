import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../../faculty/services/profile_service.dart';

class FilesModuleView extends StatefulWidget {
  const FilesModuleView({super.key});
  @override
  State<FilesModuleView> createState() => _FilesModuleViewState();
}

class _FilesModuleViewState extends State<FilesModuleView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  final _fs = FirestoreService.instance;

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.streamAll(_fs.files),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        final categories = <String>{'All', ...docs.map((d) => (d.data() as Map)['category']?.toString() ?? '')}.toList();
        final query = _searchCtrl.text.toLowerCase();
        final filtered = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final matchCategory = _selectedCategory == 'All' || data['category'] == _selectedCategory;
          final matchSearch = (data['name'] ?? '').toString().toLowerCase().contains(query) || (data['uploadedBy'] ?? '').toString().toLowerCase().contains(query);
          return matchCategory && matchSearch;
        }).toList();

        final verifiedCount = docs.where((d) => (d.data() as Map)['status'] == 'VERIFIED').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Department Digital Files & Document Repository', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                SizedBox(height: 2),
                Text('Files > Syllabi, NAAC Files, Course Diaries & Reports', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              ElevatedButton.icon(
                onPressed: () => _openUploadModal(context, docs.length),
                icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _kpi('Total Files', '${docs.length}', 'Repository Total', Icons.folder, AppTheme.accentBlue)),
              const SizedBox(width: 8),
              Expanded(child: _kpi('Verified Files', '$verifiedCount', 'Authenticated', Icons.verified, AppTheme.accentGreen)),
              const SizedBox(width: 8),
              Expanded(child: _kpi('Categories', '${categories.length - 1}', 'Document Types', Icons.category, AppTheme.accentOrange)),
            ]),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Document Repository', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Row(children: [
                      DropdownButton<String>(
                        value: categories.contains(_selectedCategory) ? _selectedCategory : 'All',
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val ?? 'All'),
                        underline: const SizedBox(),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(width: 220, height: 36, child: TextField(
                        controller: _searchCtrl, onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(hintText: 'Search file name...', hintStyle: const TextStyle(fontSize: 12), prefixIcon: const Icon(Icons.search, size: 16), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      )),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Uploaded By', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Access', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final name = d['name'] ?? '';
                        return DataRow(cells: [
                          DataCell(Row(children: [
                            Icon(name.endsWith('.pdf') ? Icons.picture_as_pdf : name.endsWith('.xlsx') ? Icons.table_chart : Icons.description,
                                color: name.endsWith('.pdf') ? Colors.red : name.endsWith('.xlsx') ? Colors.green : Colors.blue, size: 18),
                            const SizedBox(width: 6),
                            SizedBox(width: 200, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ])),
                          DataCell(Text(d['category'] ?? '', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(d['uploadedBy'] ?? '', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(d['size'] ?? '', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(d['date'] ?? '', style: const TextStyle(fontSize: 11))),
                          DataCell(Text(d['access'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.accentBlue))),
                          DataCell(_statusBadge(d['status'] ?? 'VERIFIED')),
                          DataCell(Row(children: [
                            IconButton(icon: const Icon(Icons.download, size: 16, color: AppTheme.accentBlue), tooltip: 'Download', onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading "$name"...')))),
                            IconButton(icon: const Icon(Icons.edit, size: 16, color: AppTheme.accentOrange), tooltip: 'Edit', onPressed: () => _openEditModal(context, doc.id, d)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.accentRose), tooltip: 'Delete', onPressed: () async {
                              await _fs.deleteDoc(_fs.files, doc.id);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" deleted.')));
                            }),
                          ])),
                        ]);
                      }).toList(),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'VERIFIED' ? AppTheme.accentGreen : AppTheme.accentOrange;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)));
  }

  Widget _kpi(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), maxLines: 1), Icon(icon, color: color, size: 16)]),
      const SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 2), Text(subtitle, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), maxLines: 1),
    ]));
  }

  String _monthAbbr(int month) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][month - 1];

  void _openUploadModal(BuildContext context, int count) {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final currentHodName = ProfileService.get()['name'] ?? 'Dr. K. Ravichandran';
    final uploaderCtrl = TextEditingController(text: currentHodName);
    final sizeCtrl = TextEditingController();
    String selectedAccess = 'Department Public';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) => AlertDialog(
        title: const Text('Upload Document to Repository', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Document File Name *', hintText: 'e.g. Syllabus_2026.pdf')),
          const SizedBox(height: 10),
          TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category *', hintText: 'Syllabus / NAAC / Course Materials')),
          const SizedBox(height: 10),
          TextField(controller: uploaderCtrl, decoration: const InputDecoration(labelText: 'Uploaded By')),
          const SizedBox(height: 10),
          TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'File Size', hintText: '2.4 MB')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedAccess,
            decoration: const InputDecoration(labelText: 'Access Permission'),
            items: ['Department Public', 'Faculty Only', 'HOD Only', 'Public'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (val) => setModalState(() => selectedAccess = val ?? 'Department Public'),
          ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields!')));
                return;
              }
              final now = DateTime.now();
              final newId = 'F${(count + 1).toString().padLeft(3, '0')}';
              await _fs.addDoc(_fs.files, {
                'displayId': newId,
                'name': nameCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'uploadedBy': uploaderCtrl.text.trim().isEmpty ? (ProfileService.get()['name'] ?? 'Dr. K. Ravichandran') : uploaderCtrl.text.trim(),
                'size': sizeCtrl.text.trim().isEmpty ? 'Unknown' : sizeCtrl.text.trim(),
                'date': '${now.day.toString().padLeft(2, '0')}-${_monthAbbr(now.month)}-${now.year}',
                'access': selectedAccess,
                'status': 'VERIFIED',
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${nameCtrl.text.trim()}" uploaded!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Upload File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  void _openEditModal(BuildContext context, String docId, Map<String, dynamic> d) {
    final nameCtrl = TextEditingController(text: d['name']);
    final accessCtrl = TextEditingController(text: d['access']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit File', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'File Name')),
          const SizedBox(height: 10),
          TextField(controller: accessCtrl, decoration: const InputDecoration(labelText: 'Access Level')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _fs.updateDoc(_fs.files, docId, {
                if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                if (accessCtrl.text.trim().isNotEmpty) 'access': accessCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File updated!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
