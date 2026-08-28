import 'package:flutter/material.dart';

class DepartmentClassesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const DepartmentClassesWidget({super.key, this.rows = const []});

  @override
  Widget build(BuildContext context) {
    final classes = rows.map(_toClass).toList();
    final totalStudents = classes.fold<int>(
      0,
      (sum, item) => sum + item.strength,
    );
    final years = <String, List<_ClassData>>{};
    for (final item in classes) {
      years.putIfAbsent(item.year, () => []).add(item);
    }
    final columns = years.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Department Classes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${classes.length} Active Classes • $totalStudents Students',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (columns.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No class data available'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final content = columns
                    .map((entry) => _yearColumn(entry.key, entry.value))
                    .toList();
                if (constraints.maxWidth >= 850)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _spaced(content),
                  );
                return Column(children: _spaced(content, vertical: true));
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _spaced(List<Widget> widgets, {bool vertical = false}) {
    final result = <Widget>[];
    for (var index = 0; index < widgets.length; index++) {
      if (index > 0)
        result.add(
          vertical ? const SizedBox(height: 16) : const SizedBox(width: 16),
        );
      result.add(vertical ? widgets[index] : Expanded(child: widgets[index]));
    }
    return result;
  }

  Widget _yearColumn(String year, List<_ClassData> items) {
    final color = _yearColor(year);
    final total = items.fold<int>(0, (sum, item) => sum + item.strength);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _classCard(item, color)),
          Center(
            child: Text(
              'Total Strength: $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classCard(_ClassData item, Color color) {
    final statusColor = item.attendance >= 75
        ? const Color(0xFF15803D)
        : const Color(0xFFC2410C);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: .12),
                child: Text(
                  item.section,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item.adviser,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    '${item.attendance}% Present',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    '${item.strength} Students',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: ${item.updated}',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: item.attendance / 100,
            minHeight: 3,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  _ClassData _toClass(Map<String, dynamic> row) {
    final label = (row['class_section'] ?? row['name'] ?? '').toString();
    final year = RegExp(
      r'(I{1,4})\s*YEAR',
      caseSensitive: false,
    ).firstMatch(label)?.group(1);
    final section = RegExp(
      r'SECTION\s*([A-Z])',
      caseSensitive: false,
    ).firstMatch(label)?.group(1);
    final attendance = _number(row['attendance_pct']);
    return _ClassData(
      year: year == null ? 'YEAR' : '${year.toUpperCase()} YEAR',
      section: section?.toUpperCase() ?? '?',
      name: label.isEmpty ? 'null' : label,
      adviser: (row['adviser_name'] ?? 'null').toString(),
      strength: _number(row['strength']).round(),
      attendance: attendance,
      status: attendance >= 75 ? 'Good' : 'Low',
      updated: (row['updated_at'] ?? row['created_at'] ?? 'null').toString(),
    );
  }

  double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;
  Color _yearColor(String year) => year.startsWith('IV')
      ? const Color(0xFF9333EA)
      : year.startsWith('III')
      ? const Color(0xFF2563EB)
      : year.startsWith('II')
      ? const Color(0xFF16A34A)
      : const Color(0xFFEA580C);
}

class _ClassData {
  final String year, section, name, adviser, status, updated;
  final int strength;
  final double attendance;
  const _ClassData({
    required this.year,
    required this.section,
    required this.name,
    required this.adviser,
    required this.strength,
    required this.attendance,
    required this.status,
    required this.updated,
  });
}
