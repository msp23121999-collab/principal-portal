// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../services/local_storage_base.dart';
import '../services/research_service.dart';

/// Research & Publications View (Faculty Portal — Index 18)
///
/// Personal academic research and publication records manager for logged-in Faculty.
///
/// Categories Supported (7):
///   1. Journal Publication
///   2. Conference Publication
///   3. Book / Book Chapter
///   4. Patent
///   5. Funded Project
///   6. Consultancy
///   7. Research Achievement
///
/// Rules:
///   • Faculty-owned data ONLY (strictly scoped to logged-in faculty).
///   • Dynamic category-specific form fields (only relevant fields shown).
///   • Actions: Add, Edit, View Details, Upload Supporting Document, Delete own record.
///   • Preserves HOD verification workflow status ('Submitted for Verification' / 'Approved').
class ResearchPublicationsView extends StatefulWidget {
  const ResearchPublicationsView({super.key});

  @override
  State<ResearchPublicationsView> createState() =>
      _ResearchPublicationsViewState();
}

class _ResearchPublicationsViewState extends State<ResearchPublicationsView> {
  final repo = ErpRepository();

  List<Map<String, dynamic>> _records = [];

  static const _categories = [
    'Journal Publication',
    'Conference Publication',
    'Book / Book Chapter',
    'Patent',
    'Funded Project',
    'Consultancy',
    'Research Achievement',
  ];

  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  String _categoryFilter = 'All Categories';

  // Dynamic Form Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _venueCtrl =
      TextEditingController(); // Journal/Conference/Publisher/Agency/Client/Awarding Body
  final _extraCtrl1 =
      TextEditingController(); // Indexing / ISBN / Patent No / Sanction Ref / Value
  final _extraCtrl2 =
      TextEditingController(); // DOI / Volume / Amount / Location
  final _yearCtrl = TextEditingController();
  String _selectedCategory = 'Journal Publication';
  String _status = 'Approved';

  String? _uploadedDocName;
  int _uploadedDocSize = 0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _extraCtrl1.dispose();
    _extraCtrl2.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final facultyId = repo.profile['employeeId']?.toString() ?? 'FAC002';
    final remote = await ResearchService.fetchFromSupabase(
      facultyId: facultyId,
    );
    final rawLocal = LocalStorageBase.readList('researchPublications');

    // Scrub old mock data from localStorage
    final cleanLocal = rawLocal.where((loc) {
      final id = (loc['id'] ?? '').toString();
      final title = (loc['title'] ?? '').toString();
      final isMock =
          id.startsWith('PUB00') ||
          title.contains('An Efficient Query Optimization') ||
          title.contains('Predictive Analysis of Student') ||
          title.contains('Machine Learning Methods in Database') ||
          title.contains('System and Method for Secure') ||
          title.contains('AI-Assisted Autonomous Curriculum') ||
          title.contains('Database Migration & Performance') ||
          title.contains('Best Researcher Award');
      return !isMock;
    }).toList();

    // Write back scrubbed list so mock data never reappears
    LocalStorageBase.writeList('researchPublications', cleanLocal);

    final combined = <Map<String, dynamic>>[...remote];
    for (final loc in cleanLocal) {
      if (!combined.any(
        (c) => c['id'] == loc['id'] || c['title'] == loc['title'],
      )) {
        combined.add(loc);
      }
    }

    if (mounted) {
      setState(() {
        _records = combined;
      });
    }
  }

  void _saveRecords() {
    LocalStorageBase.writeList('researchPublications', _records);
  }

  List<Map<String, dynamic>> get _filteredRecords {
    final facultyId = repo.profile['facultyId']?.toString() ?? 'FAC73124';
    final q = _searchQuery.toLowerCase();

    return _records.where((r) {
      // Faculty-owned data scope
      final isOwnRecord = r['facultyId'] == null || r['facultyId'] == facultyId;
      if (!isOwnRecord) return false;

      final title = (r['title'] as String? ?? '').toLowerCase();
      final venue = (r['venue'] as String? ?? '').toLowerCase();
      final category = (r['category'] as String? ?? '');

      final matchesSearch = q.isEmpty || title.contains(q) || venue.contains(q);
      final matchesCategory =
          _categoryFilter == 'All Categories' || category == _categoryFilter;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  int _countCategory(String cat) {
    final facultyId = repo.profile['facultyId']?.toString() ?? 'FAC73124';
    return _records
        .where(
          (r) =>
              (r['facultyId'] == null || r['facultyId'] == facultyId) &&
              r['category'] == cat,
        )
        .length;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final list = _filteredRecords;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _statCards(),
            const SizedBox(height: 20),
            _recordsTableCard(list),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final yearBadge = _badge('Academic Year ${repo.selectedAcademicYear}');
        final addBtn = ElevatedButton.icon(
          onPressed: () => _showFormDialog(),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            'Add New Record',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Research & Publications',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [yearBadge, addBtn],
              ),
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Research & Publications',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            yearBadge,
            const SizedBox(width: 12),
            addBtn,
          ],
        );
      },
    );
  }

  Widget _heroBanner() {
    final facultyName = repo.profile['name'] ?? 'Mr. P. Kalaiyarasan';
    final dept = repo.profile['department'] ?? 'CSE';
    final totalCount = _filteredRecords.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.science_outlined,
              color: Color(0xFF2563EB),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FACULTY RESEARCH PORTFOLIO',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$facultyName — Academic Research Log',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Department of $dept | $totalCount Personal Research & Publication Entries Logged',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCards() {
    final cards = [
      {
        'label': 'Journals',
        'count': _countCategory('Journal Publication'),
        'icon': Icons.article_outlined,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Conferences',
        'count': _countCategory('Conference Publication'),
        'icon': Icons.groups_outlined,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Books & Chapters',
        'count': _countCategory('Book / Book Chapter'),
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'label': 'Patents & Projects',
        'count': _countCategory('Patent') + _countCategory('Funded Project'),
        'icon': Icons.lightbulb_outline,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final perRow = constraints.maxWidth < 500 ? 2 : 4;
        final w = (constraints.maxWidth - (perRow - 1) * 16) / perRow;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) {
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        c['icon'] as IconData,
                        color: c['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c['count']}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            c['label'] as String,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _recordsTableCard(List<Map<String, dynamic>> list) {
    return Container(
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'My Research Records',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                _countBadge('${list.length}'),

                // Category Filter
                _dropdownWidget(
                  ['All Categories', ..._categories],
                  _categoryFilter,
                  (v) => setState(() => _categoryFilter = v!),
                ),

                // Search Box
                SizedBox(
                  height: 36,
                  width: 200,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search title or venue...',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          list.isEmpty
              ? _emptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final targetWidth = constraints.maxWidth < 1000
                        ? 1000.0
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: targetWidth,
                        child: Column(
                          children: [
                            _tableHeader(),
                            ...list.asMap().entries.map(
                              (e) => _tableRow(e.value, e.key.isOdd),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _th('Title & Indexing')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _th('Pub Type')),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _th('Journal / Conf Name')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _th('Publication Date')),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _th('Verification Status')),
          const SizedBox(width: 8),
          SizedBox(width: 50, child: Center(child: _th('Action'))),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> item, bool alt) {
    final title = item['title'] as String? ?? '';
    final category = item['category'] as String? ?? 'Journal Publication';
    final venue =
        item['venue'] as String? ??
        item['journal_or_conf_name'] as String? ??
        '';
    final pubDate =
        item['publication_date'] as String? ?? item['year'] as String? ?? '';
    final status = item['status'] as String? ?? 'Approved';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: alt ? const Color(0xFFFAFAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // 1. Title & Indexing (Up to 2 lines)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if ((item['extra1'] as String? ?? '').isNotEmpty)
                  Text(
                    item['extra1'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 2. Pub Type
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _categoryBadge(category),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Journal / Conf Name (Up to 2 lines)
          Expanded(
            flex: 3,
            child: Text(
              venue,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // 4. Publication Date
          Expanded(
            flex: 2,
            child: Text(
              pubDate,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 5. Verification Status
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusBadge(status),
            ),
          ),
          const SizedBox(width: 8),

          // 6. Action Column (Fixed 50px width centered so Action is never cut off!)
          SizedBox(
            width: 50,
            child: Center(
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View Details',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Record',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (action) => _handleAction(action, item),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    if (action == 'view') {
      _showViewDialog(item);
    } else if (action == 'edit') {
      _showFormDialog(editItem: item);
    } else if (action == 'delete') {
      _confirmDelete(item);
    }
  }

  void _showViewDialog(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? '';
    final category = item['category'] as String? ?? '';
    final venue = item['venue'] as String? ?? '';
    final year = item['year'] as String? ?? '';
    final desc = item['description'] as String? ?? 'No description provided.';
    final extra1 = item['extra1'] as String? ?? '';
    final extra2 = item['extra2'] as String? ?? '';
    final fileName = item['fileName'] as String? ?? 'Document.pdf';
    final status = item['status'] as String? ?? 'Approved';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _categoryBadge(category),
                    const Spacer(),
                    _statusBadge(status),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Divider(height: 24),
                _detailRow('Publisher / Venue', venue),
                if (extra1.isNotEmpty) _detailRow('Details / Indexing', extra1),
                if (extra2.isNotEmpty) _detailRow('DOI / Reference', extra2),
                _detailRow('Year', year),
                _detailRow('Attachment File', fileName),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        repo.triggerFileDownload(
                          fileName,
                          'Document content for: $title',
                          'application/pdf',
                        );
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(
                        'Download Certificate',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'this record';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Research Record',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$title"?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _records.remove(item);
                _saveRecords();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Research record deleted.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dynamic Category-Specific Form Modal ──────────────────────────────────

  void _showFormDialog({Map<String, dynamic>? editItem}) {
    final isEdit = editItem != null;

    _titleCtrl.text = isEdit ? (editItem['title'] as String? ?? '') : '';
    _descCtrl.text = isEdit ? (editItem['description'] as String? ?? '') : '';
    _venueCtrl.text = isEdit ? (editItem['venue'] as String? ?? '') : '';
    _extraCtrl1.text = isEdit ? (editItem['extra1'] as String? ?? '') : '';
    _extraCtrl2.text = isEdit ? (editItem['extra2'] as String? ?? '') : '';
    _yearCtrl.text = isEdit ? (editItem['year'] as String? ?? '2026') : '2026';
    _selectedCategory = isEdit
        ? (editItem['category'] as String? ?? 'Journal Publication')
        : 'Journal Publication';
    _uploadedDocName = isEdit ? (editItem['fileName'] as String?) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isEdit
                                ? 'Edit Research Record'
                                : 'Add Research Record',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Category Selector
                      _formLabel('Category *'),
                      const SizedBox(height: 6),
                      _formDropdown(
                        items: _categories,
                        value: _selectedCategory,
                        onChanged: (v) {
                          if (v != null) {
                            setDlgState(() => _selectedCategory = v);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Title Field
                      _formLabel(_getTitleLabel(_selectedCategory)),
                      const SizedBox(height: 6),
                      _formField(_titleCtrl, _getTitleHint(_selectedCategory)),
                      const SizedBox(height: 14),

                      // Venue / Agency / Organization Field
                      _formLabel(_getVenueLabel(_selectedCategory)),
                      const SizedBox(height: 6),
                      _formField(_venueCtrl, _getVenueHint(_selectedCategory)),
                      const SizedBox(height: 14),

                      // Extra Field 1 (Indexing / Sanction / Patent No)
                      _formLabel(_getExtra1Label(_selectedCategory)),
                      const SizedBox(height: 6),
                      _formField(
                        _extraCtrl1,
                        _getExtra1Hint(_selectedCategory),
                      ),
                      const SizedBox(height: 14),

                      // Extra Field 2 (DOI / Amount / Location)
                      _formLabel(_getExtra2Label(_selectedCategory)),
                      const SizedBox(height: 6),
                      _formField(
                        _extraCtrl2,
                        _getExtra2Hint(_selectedCategory),
                      ),
                      const SizedBox(height: 14),

                      // Year
                      _formLabel('Date / Year *'),
                      const SizedBox(height: 6),
                      _formField(_yearCtrl, 'e.g. 2026'),
                      const SizedBox(height: 14),

                      // Description
                      _formLabel('Description / Abstract'),
                      const SizedBox(height: 6),
                      _formField(
                        _descCtrl,
                        'Brief summary of the research or achievement',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),

                      // Supporting Document Upload
                      _formLabel('Supporting Document / Certificate *'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          repo.triggerNativeUpload((name, size, dataUrl) {
                            setDlgState(() {
                              _uploadedDocName = name;
                              _uploadedDocSize = size;
                            });
                          });
                          if (_uploadedDocName == null) {
                            setDlgState(() {
                              _uploadedDocName =
                                  '${_titleCtrl.text.replaceAll(' ', '_')}_Certificate.pdf';
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _uploadedDocName != null
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _uploadedDocName != null
                                    ? Icons.file_present
                                    : Icons.upload_file_outlined,
                                color: _uploadedDocName != null
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _uploadedDocName ??
                                      'Click to attach proof (PDF, Image)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: _uploadedDocName != null
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('Cancel', style: GoogleFonts.inter()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_titleCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a title.'),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(ctx);
                                _saveFormRecord(editItem);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                isEdit ? 'Update Record' : 'Save Record',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveFormRecord(Map<String, dynamic>? editItem) {
    final facultyId = repo.profile['facultyId']?.toString() ?? 'FAC73124';
    final now = DateTime.now();

    if (editItem != null) {
      setState(() {
        editItem['title'] = _titleCtrl.text.trim();
        editItem['category'] = _selectedCategory;
        editItem['venue'] = _venueCtrl.text.trim();
        editItem['extra1'] = _extraCtrl1.text.trim();
        editItem['extra2'] = _extraCtrl2.text.trim();
        editItem['year'] = _yearCtrl.text.trim();
        editItem['description'] = _descCtrl.text.trim();
        if (_uploadedDocName != null) {
          editItem['fileName'] = _uploadedDocName;
        }
        _saveRecords();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record updated successfully.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
    } else {
      final newRecord = {
        'id': 'PUB${now.millisecondsSinceEpoch}',
        'facultyId': facultyId,
        'title': _titleCtrl.text.trim(),
        'category': _selectedCategory,
        'venue': _venueCtrl.text.trim(),
        'extra1': _extraCtrl1.text.trim(),
        'extra2': _extraCtrl2.text.trim(),
        'year': _yearCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'fileName': _uploadedDocName ?? 'Proof_Document.pdf',
        'status': 'Approved',
      };
      ResearchService.save(newRecord);
      setState(() {
        _records.add(newRecord);
        _saveRecords();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Research record added successfully.'),
          backgroundColor: Color(0xFF2563EB),
        ),
      );
    }
  }

  // Dynamic field labels based on category
  String _getTitleLabel(String cat) {
    if (cat == 'Patent') return 'Patent Title *';
    if (cat == 'Funded Project') return 'Project Title *';
    if (cat == 'Consultancy') return 'Consultancy Project Title *';
    if (cat == 'Research Achievement') return 'Award / Achievement Title *';
    return 'Paper / Book Title *';
  }

  String _getTitleHint(String cat) {
    if (cat == 'Patent') return 'System and Method for...';
    if (cat == 'Funded Project') return 'AI-Assisted Autonomous Platform...';
    if (cat == 'Consultancy') return 'Cloud Database Migration...';
    if (cat == 'Research Achievement') return 'Best Researcher Award...';
    return 'Paper or book title';
  }

  String _getVenueLabel(String cat) {
    if (cat == 'Journal Publication') return 'Journal Name *';
    if (cat == 'Conference Publication') return 'Conference Name *';
    if (cat == 'Book / Book Chapter') return 'Book Publisher / Series *';
    if (cat == 'Patent') return 'Patent Office *';
    if (cat == 'Funded Project') return 'Sponsoring Agency *';
    if (cat == 'Consultancy') return 'Client Organization *';
    return 'Awarding Organization *';
  }

  String _getVenueHint(String cat) {
    if (cat == 'Journal Publication') return 'e.g. IEEE Transactions on TKDE';
    if (cat == 'Conference Publication') return 'e.g. ICCAI 2025 Conference';
    if (cat == 'Book / Book Chapter') return 'e.g. Springer Series';
    if (cat == 'Patent') return 'e.g. Indian Patent Office';
    if (cat == 'Funded Project') return 'e.g. DST-SERB / AICTE';
    if (cat == 'Consultancy') return 'e.g. TechCorp Solutions';
    return 'e.g. Institution of Engineers';
  }

  String _getExtra1Label(String cat) {
    if (cat == 'Journal Publication' || cat == 'Conference Publication')
      return 'Indexing Details';
    if (cat == 'Book / Book Chapter') return 'ISBN / ISSN';
    if (cat == 'Patent') return 'Application / Grant Number';
    if (cat == 'Funded Project') return 'Grant Sanction Reference Number';
    if (cat == 'Consultancy') return 'Project Value / Consultancy Fee';
    return 'Recognition Level';
  }

  String _getExtra1Hint(String cat) {
    if (cat == 'Journal Publication' || cat == 'Conference Publication')
      return 'e.g. Scopus & Web of Science';
    if (cat == 'Book / Book Chapter') return 'e.g. ISBN: 978-3-031-12345-6';
    if (cat == 'Patent') return 'e.g. Application No: 202541098231';
    if (cat == 'Funded Project') return 'e.g. CRG/2025/00142';
    if (cat == 'Consultancy') return 'e.g. Rs. 2,80,000';
    return 'e.g. National Level Award';
  }

  String _getExtra2Label(String cat) {
    if (cat == 'Journal Publication' || cat == 'Conference Publication')
      return 'DOI / Volume / Issue';
    if (cat == 'Book / Book Chapter') return 'Chapter / Page Numbers';
    if (cat == 'Patent') return 'Patent Status & Granted Date';
    if (cat == 'Funded Project') return 'Sanctioned Amount (Rs.)';
    if (cat == 'Consultancy') return 'Duration & Status';
    return 'Award Category / Sub-field';
  }

  String _getExtra2Hint(String cat) {
    if (cat == 'Journal Publication' || cat == 'Conference Publication')
      return 'e.g. DOI: 10.1109/TKDE.2025.3190821';
    if (cat == 'Book / Book Chapter') return 'e.g. Chapter 4, Pages 85-112';
    if (cat == 'Patent') return 'e.g. Patent No: 512934 (Granted)';
    if (cat == 'Funded Project') return 'e.g. Rs. 12,50,000';
    if (cat == 'Consultancy') return 'e.g. 6 Months (Completed)';
    return 'e.g. Computer Science Engineering';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _bc(String t, {bool active = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    ),
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

  Widget _countBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2563EB),
      ),
    ),
  );

  Widget _th(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF64748B),
    ),
  );

  Widget _categoryBadge(String category) {
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF2563EB);
    if (category == 'Conference Publication') {
      bg = const Color(0xFFF5F3FF);
      fg = const Color(0xFF7C3AED);
    } else if (category == 'Patent') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
    } else if (category == 'Funded Project' || category == 'Consultancy') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isApproved = status == 'Approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isApproved ? const Color(0xFF166534) : const Color(0xFFD97706),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.science_outlined,
              size: 52,
              color: Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            Text(
              'No research records found',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your publications, patents, book chapters, and research grants.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String t) => Text(
    t,
    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
  );

  Widget _formField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF94A3B8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _formDropdown({
    required List<String> items,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          alignment: AlignmentDirectional.bottomStart,
          menuMaxHeight: 280,
          isExpanded: true,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF0F172A),
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dropdownWidget(
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
        height: 36,
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
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
