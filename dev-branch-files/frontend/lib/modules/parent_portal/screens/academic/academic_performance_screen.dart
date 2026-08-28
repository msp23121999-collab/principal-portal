import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';

class AcademicPerformanceScreen extends StatelessWidget {
  const AcademicPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final performance = MockData.mockAcademicPerformance;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'CGPA Overview'),
            _buildCgpaCard(context, performance),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Internal Marks'),
            _buildInternalMarksList(performance),
          ],
        ),
      ),
    );
  }

  Widget _buildCgpaCard(BuildContext context, performance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.sidebarGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Cumulative Grade Point Average',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            performance.currentCgpa.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${performance.currentSemester} GPA: ${performance.currentGpa}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalMarksList(performance) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: performance.internalMarks.length,
      itemBuilder: (context, index) {
        final mark = performance.internalMarks[index];
        // Compute grade badge based on total
        String grade = 'B';
        Color color = Colors.blue;
        if (mark.total.startsWith('9')) {
          grade = 'A+';
          color = Colors.green;
        } else if (mark.total.startsWith('8')) {
          grade = 'A';
          color = Colors.teal;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CustomCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        mark.subject,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'GRADE: $grade',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMarkItem('Internal 1', mark.internal1),
                    _buildMarkItem('Internal 2', mark.internal2),
                    _buildMarkItem('Assignment', mark.assignment),
                    _buildMarkItem('Total Marks', mark.total, isTotal: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkItem(String label, String value, {bool isTotal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.accentColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
