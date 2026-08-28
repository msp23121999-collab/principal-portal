import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/admin_supabase_service.dart';

class DigitalRepositoryScreen extends StatefulWidget {
  const DigitalRepositoryScreen({super.key});
  @override
  State<DigitalRepositoryScreen> createState() => _DigitalRepositoryScreenState();
}

class _DigitalRepositoryScreenState extends State<DigitalRepositoryScreen> {
  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  String? _selectedFolderId;
  String _searchQuery = '';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final folders = await AdminSupabaseService.fetchRepositoryFolders();
    final docs = await AdminSupabaseService.fetchRepositoryDocuments(folderId: _selectedFolderId);
    if (mounted) setState(() { _folders = folders; _docs = docs; _loading = false; });
  }

  List<Map<String, dynamic>> get _filteredDocs => _searchQuery.isEmpty ? _docs : _docs.where((d) => (d['title'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) || (d['category'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  void _showAddDocModal() {
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'General');
    final sizeCtrl = TextEditingController();
    var docType = 'PDF';
    var folderId = _selectedFolderId;
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload_rounded, color: Color(0xFF0052CC)),
              SizedBox(width: 10),
              Text('Upload Document to Repository', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Local File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          final ext = file.extension?.toUpperCase() ?? 'PDF';
                          final sizeMb = file.size > (1024 * 1024)
                              ? '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB'
                              : '${(file.size / 1024).toStringAsFixed(1)} KB';

                          ss(() {
                            selectedFile = file;
                            if (titleCtrl.text.isEmpty) {
                              titleCtrl.text = file.name;
                            }
                            if (['PDF', 'DOCX', 'XLSX', 'ZIP', 'PNG', 'JPG'].contains(ext)) {
                              docType = ext;
                            }
                            sizeCtrl.text = sizeMb;
                          });
                        }
                      } catch (e) {
                        debugPrint('File picker error: $e');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedFile != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedFile != null ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                          width: selectedFile != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selectedFile != null ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              selectedFile != null ? Icons.check_circle_rounded : Icons.folder_open_rounded,
                              color: selectedFile != null ? const Color(0xFF166534) : const Color(0xFF0052CC),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedFile != null ? selectedFile!.name : 'Click to Browse File from Local System',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selectedFile != null ? const Color(0xFF166534) : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedFile != null
                                      ? 'Selected (${sizeCtrl.text}) — Click to change'
                                      : 'Supports PDF, DOCX, XLSX, ZIP, PNG, JPG',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g. Academic Regulation 2026 Policy',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: catCtrl,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            hintText: 'e.g. Policy / Circular',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: docType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'File Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: ['PDF', 'DOCX', 'XLSX', 'ZIP', 'PNG', 'JPG']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => ss(() => docType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: folderId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Target Folder (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(child: Text('No Folder (Root)')),
                      ..._folders.map((f) => DropdownMenuItem<String?>(
                            value: f['id']?.toString(),
                            child: Text(f['name'] ?? 'Untitled Folder'),
                          )),
                    ],
                    onChanged: (v) => ss(() => folderId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sizeCtrl,
                    decoration: InputDecoration(
                      labelText: 'File Size',
                      hintText: 'Auto-detected or e.g. 2.4 MB',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter or select a document title.')),
                  );
                  return;
                }

                Navigator.pop(ctx);

                String? fileUrl;
                if (selectedFile != null && selectedFile!.bytes != null) {
                  final mime = selectedFile!.name.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream';
                  fileUrl = await AdminSupabaseService.uploadRepositoryFile(selectedFile!.name, selectedFile!.bytes!, mimeType: mime);
                }

                await AdminSupabaseService.addRepositoryDocument({
                  'title': title,
                  'category': catCtrl.text.trim().isEmpty ? 'General' : catCtrl.text.trim(),
                  'file_type': docType,
                  'file_size': sizeCtrl.text.trim().isEmpty ? '1.2 MB' : sizeCtrl.text.trim(),
                  'folder_id': folderId,
                  'file_url': fileUrl,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                });

                if (mounted) {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Document "$title" saved & uploaded successfully.'),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              label: const Text('Upload to Repository', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFolderModal() {
    final nameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Folder Name', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white), onPressed: () async {
          Navigator.pop(ctx);
          await AdminSupabaseService.addRepositoryFolder({'name': nameCtrl.text.trim()});
          _loadData();
        }, child: const Text('Create')),
      ],
    ));
  }

  Future<void> _deleteDoc(Map<String, dynamic> doc) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete Document?'), content: Text('Delete "${doc['title']}"?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete'))]));
    if (ok == true && doc['id'] != null) { await AdminSupabaseService.deleteRepositoryDocument(doc['id'].toString()); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    final docs = _filteredDocs;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP PAGE HEADER ────────────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 768;
                if (isDesktop) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Digital Repository', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text('Manage institutional documents, policies, and approvals', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showAddFolderModal,
                            icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                            label: const Text('New Folder'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddDocModal,
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text('Upload Document'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0052CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Digital Repository', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        SizedBox(height: 4),
                        Text('Manage institutional documents, policies, and approvals', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showAddFolderModal,
                          icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                          label: const Text('New Folder'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddDocModal,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Upload Document'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // ── RESPONSIVE STAT CARDS ─────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 768;
                final docCount = '${_docs.length}';
                final folderCount = '${_folders.length}';
                final pdfCount = '${_docs.where((d) => d['file_type'] == 'PDF').length}';
                final otherCount = '${_docs.where((d) => d['file_type'] != 'PDF').length}';

                if (isDesktop) {
                  return Row(
                    children: [
                      Expanded(child: _statCard('Documents', docCount, Icons.description_rounded, const Color(0xFF0052CC))),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Folders', folderCount, Icons.folder_rounded, const Color(0xFFD97706))),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('PDFs', pdfCount, Icons.picture_as_pdf_rounded, const Color(0xFFDC2626))),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Other', otherCount, Icons.file_copy_rounded, const Color(0xFF9333EA))),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _statCard('Documents', docCount, Icons.description_rounded, const Color(0xFF0052CC))),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('Folders', folderCount, Icons.folder_rounded, const Color(0xFFD97706))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _statCard('PDFs', pdfCount, Icons.picture_as_pdf_rounded, const Color(0xFFDC2626))),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('Other', otherCount, Icons.file_copy_rounded, const Color(0xFF9333EA))),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            if (_folders.isNotEmpty) ...[
              const Text('Folders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: [
                GestureDetector(onTap: () => setState(() { _selectedFolderId = null; _loadData(); }), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: _selectedFolderId == null ? const Color(0xFF0052CC) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF0052CC))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.folder_open_rounded, size: 16, color: _selectedFolderId == null ? Colors.white : const Color(0xFF0052CC)), const SizedBox(width: 6), Text('All Documents', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFolderId == null ? Colors.white : const Color(0xFF0052CC)))]))),
                ..._folders.map((f) => GestureDetector(onTap: () => setState(() { _selectedFolderId = f['id']?.toString(); _loadData(); }), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: _selectedFolderId == f['id']?.toString() ? const Color(0xFF0052CC) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF0052CC))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.folder_rounded, size: 16, color: _selectedFolderId == f['id']?.toString() ? Colors.white : const Color(0xFFD97706)), const SizedBox(width: 6), Text(f['name'] ?? 'Folder', style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFolderId == f['id']?.toString() ? Colors.white : const Color(0xFF334155)))]))))
              ]),
              const SizedBox(height: 20),
            ],
            TextField(onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: 'Search documents...', prefixIcon: const Icon(Icons.search_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white)),
            const SizedBox(height: 16),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (docs.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Icon(Icons.folder_off_rounded, size: 64, color: Color(0xFFCBD5E1)), SizedBox(height: 12), Text('No documents found', style: TextStyle(color: Color(0xFF64748B), fontSize: 16))]))) else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, childAspectRatio: 1.2, crossAxisSpacing: 14, mainAxisSpacing: 14), itemCount: docs.length, itemBuilder: (ctx, i) {
              final d = docs[i];
              final typeColor = d['file_type'] == 'PDF' ? const Color(0xFFDC2626) : d['file_type'] == 'DOCX' ? const Color(0xFF0052CC) : d['file_type'] == 'XLSX' ? const Color(0xFF16A34A) : const Color(0xFF9333EA);
              return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.description_rounded, color: typeColor, size: 18)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(d['file_type'] ?? '', style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 11))), const SizedBox(width: 6), IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _deleteDoc(d))]),
                const SizedBox(height: 6),
                Text(d['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(d['category'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF94A3B8)), const SizedBox(width: 4), Text(d['date'] ?? d['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))), const Spacer(), if (d['file_size'] != null) Text(d['file_size'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))]),
              ]));
            }),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String t, String v, IconData icon, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
    child: Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: c, size: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    ),
  );
}

