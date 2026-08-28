import 'package:flutter/material.dart';
import '../models/hod_models.dart';

class KpiCardsGrid extends StatelessWidget {
  final List<KpiStatItem> kpis;

  const KpiCardsGrid({
    super.key,
    required this.kpis,
  });

  @override
  Widget build(BuildContext context) {
    final defaultKpis = [
      _KpiData(
        title: 'Total Students',
        value: '480',
        subtitle: '↑ +12 This Semester',
        subtitleColor: const Color(0xFF16A34A),
        icon: Icons.groups_outlined,
        iconBgColor: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
      ),
      _KpiData(
        title: 'Total Faculty',
        value: '24',
        subtitle: '• 2 On Leave',
        subtitleColor: const Color(0xFF2563EB),
        icon: Icons.person_outline_rounded,
        iconBgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _KpiData(
        title: 'Student Attendance (Today)',
        value: '94.1%',
        subtitle: '↑ 1.8% from yesterday',
        subtitleColor: const Color(0xFF16A34A),
        icon: Icons.school_outlined,
        iconBgColor: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _KpiData(
        title: 'Faculty Attendance (Today)',
        value: '91.6%',
        subtitle: '↑ 2.3% from yesterday',
        subtitleColor: const Color(0xFFEA580C),
        icon: Icons.badge_outlined,
        iconBgColor: const Color(0xFFFFEDD5),
        iconColor: const Color(0xFFEA580C),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount;
        if (availableWidth >= 1100) {
          crossAxisCount = 4;
        } else if (availableWidth >= 800) {
          crossAxisCount = 3;
        } else if (availableWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 110,
          ),
          itemCount: defaultKpis.length,
          itemBuilder: (context, index) {
            final item = defaultKpis[index];
            return _buildKpiCard(item);
          },
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 8),

          // Title, Value & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });
}
