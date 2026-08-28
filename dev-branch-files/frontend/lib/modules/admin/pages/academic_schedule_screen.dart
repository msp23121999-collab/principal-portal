import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';
import '../widgets/app_text_field.dart';
import '../utils/file_downloader.dart';
import '../erp_repository.dart';

class AcademicScheduleScreen extends ConsumerStatefulWidget {
  const AcademicScheduleScreen({super.key});

  @override
  ConsumerState<AcademicScheduleScreen> createState() =>
      _AcademicScheduleScreenState();
}

class _AcademicScheduleScreenState extends ConsumerState<AcademicScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _selectedAcademicYear =
      '2026 - 2027'; // This can remain as local state if not used by other providers

  // Role Simulation: Administrator vs Faculty vs Student
  final String _currentRole =
      'Administrator'; // Options: Administrator, Faculty, Student

  // Calendar State
  DateTime _currentMonth = DateTime(2026, 8);

  @override
  void initState() {
    super.initState();
    // When the screen initializes, ensure the search query in the provider matches the controller.
    // This is useful if you want to preserve search state, though here we just clear it.
    final searchQuery = ref.read(academicScheduleSearchQueryProvider);
    if (searchQuery.isNotEmpty) {
      _searchController.text = searchQuery;
    }

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- STAT CARD BUILDER ---
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    String subtitle,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // --- PDF SCHEDULE MANAGEMENT CARD ---
  Widget _buildPdfManagementCard(AcademicScheduleDocModel? doc) {
    final isAdmin = _currentRole == 'Administrator';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            doc != null
                                ? doc.title
                                : 'No Academic Schedule PDF Uploaded',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Official PDF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (doc != null)
                      Text(
                        'File: ${doc.pdfFileName} (${doc.fileSize})  •  Uploaded by: ${doc.uploadedBy}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        'Please upload the official Academic Schedule PDF document.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () => _showUploadPdfDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0056A6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(
                    doc == null ? 'Upload PDF Schedule' : 'Replace PDF',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (doc != null) ...[
                OutlinedButton.icon(
                  onPressed: () => _showPdfViewerModal(context, doc),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0056A6),
                    side: const BorderSide(color: Color(0xFF0056A6)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text(
                    'Preview PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    FileDownloader.downloadPdf(filename: doc.pdfFileName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Downloading ${doc.pdfFileName} to your local system...',
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Delete Schedule PDF',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    onPressed: () => _showDeletePdfDialog(context),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 1: ACADEMIC EVENTS MASTER TABLE ---
  Widget _buildEventsTableTab(List<AcademicEventModel> events) {
    // Watch the new providers for filter values and the final filtered list.
    final filteredEvents = ref.watch(filteredAcademicEventsProvider);
    final searchQuery = ref.watch(academicScheduleSearchQueryProvider);

    final isAdmin = _currentRole == 'Administrator';

    return Column(
      children: [
        // ─── Filter Bar ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Search + Action Buttons
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      minWidth: 240,
                    ),
                    child: TextField(
                      controller: _searchController,
                      // Update the provider's state instead of local state.
                      onChanged: (val) =>
                          ref
                                  .read(
                                    academicScheduleSearchQueryProvider
                                        .notifier,
                                  )
                                  .state =
                              val,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText:
                            'Search by event title, description or venue…',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: const Color(0xFF94A3B8),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                          .read(
                                            academicScheduleSearchQueryProvider
                                                .notifier,
                                          )
                                          .state =
                                      '';
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0056A6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Result count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          '${filteredEvents.length} ${filteredEvents.length == 1 ? "result" : "results"}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0056A6),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _downloadEventsCsv(filteredEvents),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text(
                          'Export CSV',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        ElevatedButton.icon(
                          onPressed: () => _showEventFormModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0056A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'Add Academic Event',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Row 2: Filter Dropdowns
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Filter by:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  _buildDropdownFilter(
                    'Academic Year',
                    _selectedAcademicYear, // This filter is not part of the provider logic yet
                    ['2026 - 2027', '2025 - 2026'],
                    (v) => setState(() => _selectedAcademicYear = v!),
                  ),
                  _buildDropdownFilter(
                    'Department',
                    ref.watch(academicScheduleDeptFilterProvider),
                    ['ALL', 'CSE', 'IT', 'ECE', 'AI&DS', 'MECH'],
                    (v) =>
                        ref
                                .read(
                                  academicScheduleDeptFilterProvider.notifier,
                                )
                                .state =
                            v!,
                  ),
                  _buildDropdownFilter(
                    'Semester',
                    ref.watch(academicScheduleSemFilterProvider),
                    [
                      'ALL',
                      'Sem 1',
                      'Sem 2',
                      'Sem 3',
                      'Sem 4',
                      'Sem 5',
                      'Sem 6',
                      'Sem 7',
                      'Sem 8',
                    ],
                    (v) =>
                        ref
                                .read(
                                  academicScheduleSemFilterProvider.notifier,
                                )
                                .state =
                            v!,
                  ),
                  _buildDropdownFilter(
                    'Event Type',
                    ref.watch(academicScheduleCategoryFilterProvider),
                    [
                      'ALL',
                      'Semester Start',
                      'Mid Exam',
                      'Practical Exam',
                      'Internal Exam',
                      'Holiday',
                      'University Event',
                      'Semester End',
                    ],
                    (v) =>
                        ref
                                .read(
                                  academicScheduleCategoryFilterProvider
                                      .notifier,
                                )
                                .state =
                            v!,
                  ),
                  _buildDropdownFilter(
                    'Status',
                    ref.watch(academicScheduleStatusFilterProvider),
                    ['ALL', 'Upcoming', 'Ongoing', 'Completed'],
                    (v) =>
                        ref
                                .read(
                                  academicScheduleStatusFilterProvider.notifier,
                                )
                                .state =
                            v!,
                  ),
                  if (ref.watch(academicScheduleDeptFilterProvider) != 'ALL' ||
                      ref.watch(academicScheduleSemFilterProvider) != 'ALL' ||
                      ref.watch(academicScheduleCategoryFilterProvider) !=
                          'ALL' ||
                      ref.watch(academicScheduleStatusFilterProvider) !=
                          'ALL' ||
                      searchQuery.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        ref
                                .read(
                                  academicScheduleSearchQueryProvider.notifier,
                                )
                                .state =
                            '';
                        ref
                                .read(
                                  academicScheduleDeptFilterProvider.notifier,
                                )
                                .state =
                            'ALL';
                        ref
                                .read(
                                  academicScheduleSemFilterProvider.notifier,
                                )
                                .state =
                            'ALL';
                        ref
                                .read(
                                  academicScheduleCategoryFilterProvider
                                      .notifier,
                                )
                                .state =
                            'ALL';
                        ref
                                .read(
                                  academicScheduleStatusFilterProvider.notifier,
                                )
                                .state =
                            'ALL';
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                      label: const Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ─── Events Data Table ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: filteredEvents.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Academic Events Found',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try adjusting the search or filter criteria above.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showEventFormModal(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056A6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add New Event'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 44,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 70,
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF8FAFC),
                      ),
                      dividerThickness: 0.8,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade100,
                          width: 0.8,
                        ),
                      ),
                      columns: [
                        DataColumn(
                          label: _tableHeader(
                            'Event Name',
                            Icons.event_note_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Start Date',
                            Icons.calendar_today_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'End Date',
                            Icons.event_available_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Department',
                            Icons.account_tree_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Semester',
                            Icons.school_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Category',
                            Icons.category_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Venue',
                            Icons.location_on_outlined,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Status',
                            Icons.info_outline_rounded,
                          ),
                        ),
                        DataColumn(
                          label: _tableHeader(
                            'Actions',
                            Icons.settings_outlined,
                          ),
                        ),
                      ],
                      rows: filteredEvents.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final evt = entry.value;
                        final rowBg = idx.isEven
                            ? Colors.white
                            : const Color(0xFFFAFBFC);
                        return DataRow(
                          color: WidgetStateProperty.all(rowBg),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      evt.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      evt.description,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    evt.startDate,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_available_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    evt.endDate,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(_deptChip(evt.department)),
                            DataCell(_semChip(evt.semester)),
                            DataCell(_categoryBadge(evt.category)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    evt.venue,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(AppStatusBadge(status: evt.status)),
                            DataCell(
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Color(0xFF64748B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showEventFormModal(context, event: evt);
                                  } else if (val == 'toggle') {
                                    ref
                                        .read(academicEventsProvider.notifier)
                                        .toggleStatus(evt.id);
                                  } else if (val == 'delete') {
                                    _showDeleteEventDialog(context, evt.id);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  if (isAdmin)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: Color(0xFF0056A6),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Edit Event',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.swap_horiz_rounded,
                                          size: 16,
                                          color: Color(0xFF16A34A),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Toggle Status',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAdmin)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            color: Color(0xFFDC2626),
                                            size: 16,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Delete Event',
                                            style: TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // --- TABLE HEADER BUILDER ---
  Widget _tableHeader(String label, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: const Color(0xFF64748B)),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    ],
  );

  // --- DEPT CHIP ---
  Widget _deptChip(String dept) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      dept,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1D4ED8),
      ),
    ),
  );

  // --- SEM CHIP ---
  Widget _semChip(String sem) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FDF4),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFBBF7D0)),
    ),
    child: Text(
      sem,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF15803D),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  // --- CATEGORY BADGE ---
  Widget _categoryBadge(String category) {
    Color bgColor;
    Color textColor;
    switch (category) {
      case 'Mid Exam':
      case 'Practical Exam':
      case 'Internal Exam':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFC2410C);
        break;
      case 'Holiday':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFB91C1C);
        break;
      case 'Semester Start':
      case 'Semester End':
        bgColor = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        break;
      case 'University Event':
        bgColor = const Color(0xFFF5F3FF);
        textColor = const Color(0xFF7C3AED);
        break;
      default:
        bgColor = const Color(0xFFF8FAFC);
        textColor = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- TAB 2: INTERACTIVE MONTHLY CALENDAR VIEW ---
  Widget _buildCalendarTab(List<AcademicEventModel> events) {
    final monthName = _getMonthName(_currentMonth.month);
    final year = _currentMonth.year;

    // Days in month calculation
    final daysInMonth = DateTime(year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(year, _currentMonth.month).weekday;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          // Month Navigation Bar — responsive Wrap
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text('$monthName $year', style: AppTypography.h3),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildCalendarLegendItem(
                    'Semester Start / End',
                    AppColors.primary,
                  ),
                  _buildCalendarLegendItem(
                    'Mid & Practical Exams',
                    AppColors.info,
                  ),
                  _buildCalendarLegendItem('Holidays', AppColors.error),
                  _buildCalendarLegendItem(
                    'University Events',
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
          AppSpacing.gapMd,

          // Day Headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      color: AppColors.background,
                      child: Text(
                        day,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(height: 1),

          // Calendar Grid — aspect ratio adapts to cell width
          LayoutBuilder(
            builder: (context, calConstraints) {
              final cellW = calConstraints.maxWidth / 7;
              final cellH = cellW < 55 ? 50.0 : (cellW < 80 ? 62.0 : 76.0);
              final ratio = cellW / cellH;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - (firstWeekday - 2);
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(128),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                    );
                  }

                  final dateStr =
                      '$year-${_currentMonth.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
                  final matchingEvents = events
                      .where(
                        (e) => e.startDate == dateStr || e.endDate == dateStr,
                      )
                      .toList();

                  return InkWell(
                    onTap: matchingEvents.isNotEmpty
                        ? () => _showEventDetailsModal(
                            context,
                            matchingEvents.first,
                          )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        color: matchingEvents.isNotEmpty
                            ? AppColors.primary.withAlpha(10)
                            : Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayNumber',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: matchingEvents.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: matchingEvents.isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (matchingEvents.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getEventCategoryColor(
                                  matchingEvents.first.category,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                matchingEvents.first.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegendItem(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppTypography.bodySmall),
    ],
  );

  // --- TAB 3: HOLIDAY LIST ---
  Widget _buildHolidayListTab() {
    final holidays = ref.watch(academicHolidaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              'Official Institutional Holiday List (2026 - 2027)',
              style: AppTypography.h3,
            ),
            AppButton(
              label: 'Download Holiday List',
              type: AppButtonType.secondary,
              icon: Icons.download_rounded,
              onPressed: () => _downloadHolidaysCsv(holidays),
            ),
          ],
        ),
        AppSpacing.gapMd,
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 1000
                ? 3
                : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: holidays.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 130,
              ),
              itemBuilder: (context, index) {
                final hol = holidays[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.beach_access_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hol.name,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${hol.date} (${hol.dayOfWeek})',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              hol.remarks,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // --- TAB 4: IMPORTANT MILESTONES TIMELINE ---
  Widget _buildMilestonesTab() {
    final milestones = ref.watch(academicMilestonesProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Academic Year Key Milestones & Target Deadlines',
                style: AppTypography.h3,
              ),
              AppButton(
                label: 'Download Milestones',
                type: AppButtonType.secondary,
                icon: Icons.download_rounded,
                onPressed: () => _downloadMilestonesCsv(milestones),
              ),
            ],
          ),

          AppSpacing.gapLg,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: milestones.length,
            separatorBuilder: (ctx, idx) => const Padding(
              padding: EdgeInsets.only(left: 20),
              child: SizedBox(
                height: 24,
                child: VerticalDivider(thickness: 2, color: AppColors.primary),
              ),
            ),
            itemBuilder: (context, index) {
              final ms = milestones[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ms.status == 'Completed'
                          ? AppColors.success
                          : (ms.status == 'In Progress'
                                ? AppColors.warning
                                : AppColors.primary),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ms.status == 'Completed'
                          ? Icons.check_rounded
                          : Icons.flag_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ms.title,
                                  style: AppTypography.labelLarge.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  ms.description,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                AppSpacing.gapSm,
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Target Date: ${ms.targetDate}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppStatusBadge(status: ms.status),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI DIALOGS & MODALS ---

  void _showUploadPdfDialog(BuildContext context) {
    var selectedFileName = 'Official_Academic_Schedule_2026_27.pdf';
    var selectedFileSize = '2.8 MB';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctxState, setModalState) => AlertDialog(
          title: const Text('Upload Academic Schedule PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select the official Academic Schedule PDF document from your local system.',
                style: AppTypography.bodyMedium,
              ),
              AppSpacing.gapMd,
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withAlpha(76),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withAlpha(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedFileName,
                            style: AppTypography.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'PDF File  •  $selectedFileSize',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: 'Browse Local File',
                      type: AppButtonType.secondary,
                      onPressed: () {
                        FileDownloader.pickLocalFile(
                          accept: '.pdf',
                          onFileSelected: (name, sizeStr) {
                            setModalState(() {
                              selectedFileName = name;
                              selectedFileSize = sizeStr;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Save & Upload',
              onPressed: () {
                ref
                    .read(academicScheduleDocProvider.notifier)
                    .uploadPdf(
                      selectedFileName,
                      selectedFileSize,
                      'Dr. Suresh Kumar (Registrar)',
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Academic Schedule PDF "$selectedFileName" uploaded successfully!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfViewerModal(BuildContext context, AcademicScheduleDocModel doc) {
    var currentPage = 1;
    const totalPages = 4;
    var zoomLevel = 1.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 900,
            height: 700,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // PDF Viewer Header Toolbar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.error,
                          size: 24,
                        ),
                        AppSpacing.gapSm,
                        Text(
                          doc.pdfFileName,
                          style: AppTypography.h3.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.zoom_out_rounded),
                          onPressed: () {
                            if (zoomLevel > 0.8)
                              setModalState(() => zoomLevel -= 0.2);
                          },
                        ),
                        Text('${(zoomLevel * 100).toInt()}%'),
                        IconButton(
                          icon: const Icon(Icons.zoom_in_rounded),
                          onPressed: () {
                            if (zoomLevel < 2.0)
                              setModalState(() => zoomLevel += 0.2);
                          },
                        ),
                        const VerticalDivider(indent: 8, endIndent: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: currentPage > 1
                              ? () => setModalState(() => currentPage--)
                              : null,
                        ),
                        Text(
                          'Page $currentPage of $totalPages',
                          style: AppTypography.labelLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: currentPage < totalPages
                              ? () => setModalState(() => currentPage++)
                              : null,
                        ),
                        const VerticalDivider(indent: 8, endIndent: 8),
                        IconButton(
                          icon: const Icon(Icons.print_rounded),
                          tooltip: 'Print PDF',
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printing PDF document...'),
                                ),
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                AppSpacing.gapSm,

                // PDF Viewer Canvas Simulation
                Expanded(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Transform.scale(
                        scale: zoomLevel,
                        child: Container(
                          width: 600,
                          height: 550,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'KSR COLLEGE OF ENGINEERING (AUTONOMOUS)',
                                    style: AppTypography.h3.copyWith(
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'ACADEMIC SCHEDULE 2026 - 2027',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(thickness: 2),
                              AppSpacing.gapMd,
                              Center(
                                child: Text(
                                  'OFFICIAL CALENDAR OF EVENTS - PAGE $currentPage',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              AppSpacing.gapMd,
                              Text(
                                '• Reopening of College: 03-08-2026',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                '• Continuous Internal Assessment - I: 24-08-2026 to 29-08-2026',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                '• National Technical Symposium: 12-09-2026 to 13-09-2026',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                '• End Semester Practical Viva: 16-11-2026 to 21-11-2026',
                                style: AppTypography.bodyMedium,
                              ),
                              Text(
                                '• End Semester Theory Examinations: 01-12-2026 to 18-12-2026',
                                style: AppTypography.bodyMedium,
                              ),
                              const Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  'Registrar / Controller of Examinations Signature',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeletePdfDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Academic Schedule PDF?'),
        content: const Text(
          'Are you sure you want to delete the uploaded schedule PDF? Users will no longer be able to download or preview the schedule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(academicScheduleDocProvider.notifier).deletePdf();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Academic Schedule PDF deleted.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEventFormModal(BuildContext context, {AcademicEventModel? event}) {
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final descCtrl = TextEditingController(text: event?.description ?? '');
    final venueCtrl = TextEditingController(
      text: event?.venue ?? 'Main Classrooms',
    );
    final startDateCtrl = TextEditingController(
      text: event?.startDate ?? '2026-09-01',
    );
    final endDateCtrl = TextEditingController(
      text: event?.endDate ?? '2026-09-01',
    );

    var selectedDept = event?.department ?? 'CSE';
    var selectedSem = event?.semester ?? 'Sem 5';
    var selectedCat = event?.category ?? 'University Event';
    var selectedStat = event?.status ?? 'Upcoming';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                event == null ? 'Add Academic Event' : 'Edit Academic Event',
                style: AppTypography.h3,
              ),
              AppSpacing.gapMd,
              AppTextField(label: 'Event Title', controller: titleCtrl),
              AppSpacing.gapSm,
              AppTextField(
                label: 'Description',
                controller: descCtrl,
                maxLines: 2,
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Start Date',
                      controller: startDateCtrl,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: AppTextField(
                      label: 'End Date',
                      controller: endDateCtrl,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              AppTextField(label: 'Venue', controller: venueCtrl),
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter('Department', selectedDept, [
                      'ALL',
                      'CSE',
                      'IT',
                      'ECE',
                      'AI&DS',
                      'MECH',
                    ], (v) => selectedDept = v!),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: _buildDropdownFilter('Semester', selectedSem, [
                      'ALL',
                      'Sem 1',
                      'Sem 2',
                      'Sem 3',
                      'Sem 4',
                      'Sem 5',
                      'Sem 6',
                      'Sem 7',
                      'Sem 8',
                    ], (v) => selectedSem = v!),
                  ),
                ],
              ),
              AppSpacing.gapSm,
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter('Category', selectedCat, [
                      'Semester Start',
                      'Mid Exam',
                      'Practical Exam',
                      'Internal Exam',
                      'Holiday',
                      'University Event',
                      'Semester End',
                    ], (v) => selectedCat = v!),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: _buildDropdownFilter('Status', selectedStat, [
                      'Upcoming',
                      'Ongoing',
                      'Completed',
                    ], (v) => selectedStat = v!),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  AppSpacing.gapSm,
                  AppButton(
                    label: event == null ? 'Create Event' : 'Save Changes',
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;

                      final newEvt = AcademicEventModel(
                        id:
                            event?.id ??
                            'EVT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        scheduleId: 'DOC-2026-01',
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: selectedCat,
                        startDate: startDateCtrl.text.trim(),
                        endDate: endDateCtrl.text.trim(),
                        semester: selectedSem,
                        department: selectedDept,
                        status: selectedStat,
                        venue: venueCtrl.text.trim(),
                      );

                      if (event == null) {
                        ref
                            .read(academicEventsProvider.notifier)
                            .addEvent(newEvt);
                      } else {
                        ref
                            .read(academicEventsProvider.notifier)
                            .updateEvent(newEvt);
                      }

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            event == null
                                ? 'Event created successfully!'
                                : 'Event updated successfully!',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteEventDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Academic Event?'),
        content: const Text(
          'Are you sure you want to remove this academic event from the schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(academicEventsProvider.notifier).deleteEvent(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEventDetailsModal(BuildContext context, AcademicEventModel evt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEventCategoryColor(evt.category).withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event_rounded,
                color: _getEventCategoryColor(evt.category),
              ),
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text(
                evt.title,
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(evt.description, style: AppTypography.bodyMedium),
            AppSpacing.gapMd,
            Text('• Category: ${evt.category}', style: AppTypography.bodySmall),
            Text(
              '• Start Date: ${evt.startDate}',
              style: AppTypography.bodySmall,
            ),
            Text('• End Date: ${evt.endDate}', style: AppTypography.bodySmall),
            Text(
              '• Department: ${evt.department}',
              style: AppTypography.bodySmall,
            ),
            Text('• Semester: ${evt.semester}', style: AppTypography.bodySmall),
            Text('• Venue: ${evt.venue}', style: AppTypography.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- HELPER DOWNLOAD METHODS ---

  void _downloadEventsCsv(List<AcademicEventModel> events) {
    final csv = StringBuffer();
    csv.writeln(
      'Event Name,Category,Start Date,End Date,Department,Semester,Venue,Status,Description',
    );
    for (final e in events) {
      csv.writeln(
        '"${e.title}","${e.category}","${e.startDate}","${e.endDate}","${e.department}","${e.semester}","${e.venue}","${e.status}","${e.description}"',
      );
    }
    FileDownloader.downloadString(
      filename: 'Academic_Events_Schedule.csv',
      content: csv.toString(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Downloaded Academic_Events_Schedule.csv to your local system!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _downloadHolidaysCsv(List<HolidayModel> holidays) {
    final csv = StringBuffer();
    csv.writeln('Holiday Name,Date,Day,Remarks');
    for (final h in holidays) {
      csv.writeln('"${h.name}","${h.date}","${h.dayOfWeek}","${h.remarks}"');
    }
    FileDownloader.downloadString(
      filename: 'Institutional_Holidays_2026_27.csv',
      content: csv.toString(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Downloaded Institutional_Holidays_2026_27.csv to your local system!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _downloadMilestonesCsv(List<AcademicMilestoneModel> milestones) {
    final csv = StringBuffer();
    csv.writeln('Milestone Title,Target Date,Status,Description');
    for (final m in milestones) {
      csv.writeln(
        '"${m.title}","${m.targetDate}","${m.status}","${m.description}"',
      );
    }
    FileDownloader.downloadString(
      filename: 'Academic_Milestones_2026_27.csv',
      content: csv.toString(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Downloaded Academic_Milestones_2026_27.csv to your local system!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // --- HELPER METHODS ---

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Color _getEventCategoryColor(String cat) {
    switch (cat) {
      case 'Semester Start':
      case 'Semester End':
        return AppColors.primary;
      case 'Mid Exam':
      case 'Practical Exam':
      case 'Internal Exam':
        return AppColors.info;
      case 'Holiday':
        return AppColors.error;
      case 'University Event':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _getMonthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(academicScheduleDocProvider);
    final events = ref.watch(academicEventsProvider);
    final holidays = ref.watch(academicHolidaysProvider);

    final totalEvents = events.length;
    final upcomingEventsCount = events
        .where((e) => e.status == 'Upcoming')
        .length;
    final holidayCount = holidays.length;
    const workingDaysCount = 185;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Schedule & Calendar Module',
                    style: AppTypography.h2,
                  ),
                  Text(
                    'Official institutional schedule, calendar events, holidays, and milestones.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLg,

              // Top Statistics Cards (4 Cards in One Row)
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 750) {
                    return SizedBox(
                      height: 84,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Academic Events',
                              '$totalEvents Events',
                              Icons.event_note_rounded,
                              AppColors.primary,
                              'Master Schedule Registry',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Upcoming Events',
                              '$upcomingEventsCount Scheduled',
                              Icons.upcoming_rounded,
                              AppColors.info,
                              'Starting in 2026-2027',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Institutional Holidays',
                              '$holidayCount Holidays',
                              Icons.beach_access_rounded,
                              AppColors.error,
                              'Official Academic Year',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Working Days',
                              '$workingDaysCount Days',
                              Icons.calendar_today_rounded,
                              AppColors.success,
                              'Standard Academic Target',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: constraints.maxWidth > 500 ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 84,
                    children: [
                      _buildStatCard(
                        'Total Academic Events',
                        '$totalEvents Events',
                        Icons.event_note_rounded,
                        AppColors.primary,
                        'Master Schedule Registry',
                      ),
                      _buildStatCard(
                        'Upcoming Events',
                        '$upcomingEventsCount Scheduled',
                        Icons.upcoming_rounded,
                        AppColors.info,
                        'Starting in 2026-2027',
                      ),
                      _buildStatCard(
                        'Institutional Holidays',
                        '$holidayCount Holidays',
                        Icons.beach_access_rounded,
                        AppColors.error,
                        'Official Academic Year',
                      ),
                      _buildStatCard(
                        'Working Days',
                        '$workingDaysCount Days',
                        Icons.calendar_today_rounded,
                        AppColors.success,
                        'Standard Academic Target',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // PDF Schedule Upload & Preview Section
              _buildPdfManagementCard(doc),
              const SizedBox(height: 16),

              // Multi-Tab Navigation Header
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFF0056A6),
                  unselectedLabelColor: const Color(0xFF64748B),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  indicatorColor: const Color(0xFF0056A6),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.table_chart_outlined, size: 18),
                      text: 'Academic Events Table',
                    ),
                    Tab(
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                      text: 'Monthly Calendar View',
                    ),
                    Tab(
                      icon: Icon(Icons.beach_access_outlined, size: 18),
                      text: 'Holiday List',
                    ),
                    Tab(
                      icon: Icon(Icons.timeline_rounded, size: 18),
                      text: 'Important Milestones',
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,

              // Tab Content Views (Dynamic height to eliminate empty vertical space)
              SizedBox(
                height:
                    700, // Adjust height as needed or use other layout widgets
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsTableTab(events),
                    _buildCalendarTab(events),
                    _buildHolidayListTab(),
                    _buildMilestonesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
