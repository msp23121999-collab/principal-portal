import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_utils.dart';
import '../widgets/layout/content_scaffold.dart';
import '../widgets/layout/page_header.dart';
import '../providers/institution_providers.dart';
import '../widgets/admission_trend_section.dart';
import '../widgets/growth_trend_section.dart';
import '../widgets/institution_kpi_grid.dart';

class InstitutionAnalyticsScreen extends StatelessWidget {
  const InstitutionAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContentScaffold(
      children: [
        const PageHeader(
          title: 'Institution Analytics',
          breadcrumbSegments: ['Analytics', 'Institution'],
          subtitle:
              'Admission trends, academic growth, and institution-wide KPIs',
        ),
        const InstitutionKpiGrid(),
        const AdmissionTrendSection(),
        ResponsiveGrid(
          minTileWidth: 340,
          children: [
            GrowthTrendSection(
              title: 'Academic Growth',
              subtitle: 'Overall pass % trend',
              color: AppColors.success,
              provider: academicGrowthProvider,
            ),
            GrowthTrendSection(
              title: 'Faculty Growth',
              subtitle: 'Total faculty strength',
              color: AppColors.accentGold,
              provider: facultyGrowthProvider,
            ),
            GrowthTrendSection(
              title: 'Student Growth',
              subtitle: 'Total enrolled students',
              color: AppColors.primaryBlue,
              provider: studentGrowthProvider,
            ),
          ],
        ),
      ],
    );
  }
}
