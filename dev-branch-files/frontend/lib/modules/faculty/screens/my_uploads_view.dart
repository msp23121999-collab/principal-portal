// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/syllabus_service.dart';
import '../services/assignment_service.dart';
import '../services/course_allocation_service.dart';

class MyUploadsView extends StatefulWidget {
  const MyUploadsView({super.key});

  @override
  State<MyUploadsView> createState() => _MyUploadsViewState();
}

class _MyUploadsViewState extends State<MyUploadsView> {
  final repo = ErpRepository();
  String _activeTab =
      'All Files'; // 'All Files', 'Course Material', or 'Assignment'
  String _search = '';
  final _searchCtrl = TextEditingController();
  String _sortBy = 'Latest';
  bool _isLoading = false;

  List<Map<String, dynamic>> _courseMaterials = [];
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadUploadsFromDb();
  }

  Future<void> _loadUploadsFromDb({bool showToast = false}) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final facultyId = repo.profile['employeeId']?.toString() ?? 'FAC002';

      final materials = await SyllabusService.fetchFromSupabase(
        facultyId: facultyId,
      );
      final assignList = await AssignmentService.fetchFromSupabase(
        facultyId: facultyId,
      );

      if (mounted) {
        setState(() {
          _courseMaterials = materials;
          _assignments = assignList;
          _isLoading = false;
        });

        if (showToast) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploaded files refreshed from Database ✓'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getAllFiles() {
    final list = <Map<String, dynamic>>[];
    final seen = <String>{};

    // Add Course Material files
    final matList = _courseMaterials.isNotEmpty
        ? _courseMaterials
        : repo.syllabusUploads;
    for (final s in matList) {
      final id = s['id']?.toString() ?? s['syllabusId']?.toString() ?? '';
      final fname =
          (s['fileName'] ??
                  s['file_name'] ??
                  s['title'] ??
                  'Course_Material.pdf')
              .toString();
      final key = id.isNotEmpty ? 'MAT_$id' : 'MAT_${fname}_${s['subject']}';

      if (!seen.contains(key)) {
        seen.add(key);
        list.add({
          'id': id,
          'name': fname,
          'type': 'Course Material',
          'subject': s['subject'] ?? s['subject_name'] ?? 'General',
          'date':
              s['uploadedOn'] ??
              s['created_at']?.toString().split('T').first ??
              '2026-08-05',
          'size': s['fileSize'] ?? s['file_size'] ?? '1.2 MB',
          'fileUrl': s['fileUrl'] ?? s['file_url'] ?? s['fileData'] ?? '',
          'raw': s,
        });
      }
    }

    // Add Assignment files
    final aList = _assignments.isNotEmpty ? _assignments : repo.assignments;
    for (final a in aList) {
      final id = a['id']?.toString() ?? a['assignmentId']?.toString() ?? '';
      final qFile =
          a['qFile'] ??
          a['question_file'] ??
          a['fileName'] ??
          a['attachment_url'] ??
          '';
      final title = a['title'] ?? 'Assignment Task';
      final fname = qFile.toString().isNotEmpty
          ? qFile.toString().split('/').last
          : '$title.pdf';
      final key = id.isNotEmpty ? 'ASG_$id' : 'ASG_${fname}_${a['subject']}';

      if (!seen.contains(key)) {
        seen.add(key);
        list.add({
          'id': id,
          'name': fname,
          'type': 'Assignment',
          'subject': a['subject'] ?? a['subject_name'] ?? 'General',
          'date':
              a['dueDate'] ??
              a['due_date']?.toString().split('T').first ??
              '2026-08-05',
          'size': '1.5 MB',
          'fileUrl': a['qFile'] ?? a['attachment_url'] ?? a['file_url'] ?? '',
          'raw': a,
        });
      }
    }

    return list;
  }

  List<Map<String, dynamic>> get _filteredFiles {
    final all = _getAllFiles();
    final q = _search.trim().toLowerCase();

    var list = all.where((f) {
      final matchesTab = _activeTab == 'All Files' || f['type'] == _activeTab;
      final matchesSearch =
          q.isEmpty ||
          (f['name'] as String).toLowerCase().contains(q) ||
          (f['subject'] as String).toLowerCase().contains(q) ||
          (f['type'] as String).toLowerCase().contains(q);
      return matchesTab && matchesSearch;
    }).toList();

    if (_sortBy == 'Name') {
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }

    return list;
  }

  // ── Open Web File Downloader ──────────────────────────────────────────────
  // ── Open Web File Downloader ──────────────────────────────────────────────
  void _downloadFile(String name, String fileUrl) {
    repo.triggerFileDownload(name, fileUrl, 'application/pdf');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $name... ✓'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── View Document Details Modal ───────────────────────────────────────────
  void _showViewModal(Map<String, dynamic> f) {
    final name = f['name'] as String;
    final type = f['type'] as String;
    final subject = f['subject'] as String;
    final date = f['date'] as String;
    final size = f['size'] as String;
    final fileUrl = f['fileUrl'] as String;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Document Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modalDetailRow('Document Name', name),
            _modalDetailRow('Category', type),
            _modalDetailRow('Subject', subject),
            _modalDetailRow('Uploaded On', date),
            _modalDetailRow('File Size', size),
            if (fileUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Storage URL:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              SelectableText(
                fileUrl,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF475569),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modalDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _fileExplorerPanel(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Page Header: Title on Left; All Files, Course Materials, Assignments, Year Badge on Right
  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        final filterControls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. All Files Button
            _headerFilterChip('All Files', Icons.folder_outlined),
            const SizedBox(width: 8),

            // 2. Course Materials Button
            _headerFilterChip('Course Material', Icons.book_outlined),
            const SizedBox(width: 8),

            // 3. Assignments Button
            _headerFilterChip('Assignment', Icons.edit_document),
            const SizedBox(width: 16),

            // 4. Academic Year Badge (Rightmost position)
            _badge('Academic Year ${repo.selectedAcademicYear}'),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Uploads',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: filterControls,
              ),
            ],
          );
        }

        return Row(
          children: [
            Text(
              'My Uploads',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            filterControls,
          ],
        );
      },
    );
  }

  Widget _headerFilterChip(String tabKey, IconData icon) {
    final isSel = _activeTab == tabKey;
    String label = tabKey;
    if (tabKey == 'Assignment') label = 'Assignments';
    if (tabKey == 'Course Material') label = 'Course Materials';

    return InkWell(
      onTap: () => setState(() => _activeTab = tabKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSel ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSel ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full Width File Explorer Panel ────────────────────────────────────────
  Widget _fileExplorerPanel() {
    final list = _filteredFiles;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open_outlined,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'File Explorer',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),

              // ── Extended Search Input Field Box ───────────────────────────
              Container(
                height: 38,
                width: 360, // Extended Search Input Box Size
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search by file name, subject, or category...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh Button next to Search Bar
              IconButton(
                onPressed: () => _loadUploadsFromDb(showToast: true),
                icon: const Icon(
                  Icons.refresh,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                tooltip: 'Refresh from Supabase DB',
              ),
              const SizedBox(width: 8),

              // Sort Dropdown
              _dropdown(
                ['Sort by: Latest', 'Sort by: Name'],
                _sortBy == 'Latest' ? 'Sort by: Latest' : 'Sort by: Name',
                (v) {
                  setState(() {
                    _sortBy = v!.contains('Name') ? 'Name' : 'Latest';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading && list.isEmpty)
            const FacultyLoadingWidget()
          else if (list.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.folder_copy,
                      color: Color(0xFF2563EB),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No uploaded files to display',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "You haven't uploaded any files under this category yet.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            )
          else ...[
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      'File Name',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      'Subject',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Uploaded Date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Actions',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...list.map((f) => _fileRow(f)),
          ],
        ],
      ),
    );
  }

  // ── Table Data Row with View, Download, & Delete Action Buttons ───────────
  Widget _fileRow(Map<String, dynamic> f) {
    final name = f['name'] as String;
    final type = f['type'] as String;
    final fileUrl = f['fileUrl'] as String;
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'DOC';
    final extColor = ext == 'PDF'
        ? const Color(0xFFDC2626)
        : ext == 'ZIP'
        ? const Color(0xFF8B5CF6)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: extColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ext,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: extColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: type == 'Assignment'
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: type == 'Assignment'
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF137333),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              f['subject'] as String,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              f['date'] as String,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),

          // Actions Column: View, Download, Delete
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. View Button
                IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  tooltip: 'View Details',
                  onPressed: () => _showViewModal(f),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                ),

                // 2. Download Button
                IconButton(
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                  tooltip: 'Download File',
                  onPressed: () => _downloadFile(name, fileUrl),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                ),

                // 3. Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete File',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          'Delete File',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'Are you sure you want to delete "$name" permanently?',
                          style: GoogleFonts.inter(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final raw =
                                  f['raw'] as Map<String, dynamic>? ?? {};
                              final id =
                                  f['id']?.toString() ??
                                  raw['id']?.toString() ??
                                  '';

                              if (type == 'Course Material') {
                                if (id.isNotEmpty) {
                                  await SyllabusService.delete(id);
                                }
                                _courseMaterials.removeWhere(
                                  (m) => m['id']?.toString() == id,
                                );
                              } else {
                                if (id.isNotEmpty) {
                                  await AssignmentService.delete(id);
                                }
                                _assignments.removeWhere(
                                  (a) => a['id']?.toString() == id,
                                );
                              }

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                _loadUploadsFromDb(showToast: true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String val,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(val)
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : val);

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: validVal,
      onSelected: onChange,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == validVal;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validVal,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}
