import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../theme.dart';

class FacultyOverviewTable extends StatefulWidget {
  final List<FacultyOverviewItem> facultyMembers;

  const FacultyOverviewTable({
    super.key,
    required this.facultyMembers,
  });

  @override
  State<FacultyOverviewTable> createState() => _FacultyOverviewTableState();
}

class _FacultyOverviewTableState extends State<FacultyOverviewTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.facultyMembers.where((f) {
      final q = _searchQuery.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.designation.toLowerCase().contains(q) ||
          f.id.toLowerCase().contains(q);
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          const Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: AppTheme.accentBlue,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Department Faculty Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search faculty...',
                hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Department Faculty Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              // Search Bar
              SizedBox(
                width: 240,
                height: 38,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search faculty...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),

        // Data Table Box
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('Faculty Name & ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Designation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Attendance Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Subjects Assigned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Classes Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Research Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: filtered.map((f) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.12),
                            child: Text(
                              f.name[0],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(f.id, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(f.designation, style: const TextStyle(fontSize: 12))),
                    DataCell(
                      SizedBox(
                        width: 110,
                        child: Row(
                          children: [
                            Icon(
                              f.attendancePct >= 90 ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 14,
                              color: f.attendancePct >= 90 ? AppTheme.accentGreen : AppTheme.accentAmber,
                            ),
                            const SizedBox(width: 6),
                            Text('${f.attendancePct}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text('${f.assignedSubjects} Subjects', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${f.classesToday} Classes', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${f.researchCount} Papers',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentPurple),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: f.status == 'Present' ? AppTheme.badgeGreenBg : AppTheme.badgeOrangeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          f.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: f.status == 'Present' ? AppTheme.badgeGreenText : AppTheme.badgeOrangeText,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
