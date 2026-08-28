import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../theme.dart';

class ResearchDashboardWidget extends StatelessWidget {
  final ResearchMetric metric;

  const ResearchDashboardWidget({
    super.key,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: AppTheme.accentPurple,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Research & Innovation Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.badgePurpleBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${metric.targetCompletionPct}% Target Met',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.badgePurpleText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5 Metric Tiles Grid
          Row(
            children: [
              Expanded(child: _buildResearchTile('Journal Papers', '${metric.publicationsCount}', Icons.article_outlined, AppTheme.accentBlue)),
              const SizedBox(width: 8),
              Expanded(child: _buildResearchTile('Conferences', '${metric.conferencesCount}', Icons.co_present_outlined, AppTheme.accentPurple)),
              const SizedBox(width: 8),
              Expanded(child: _buildResearchTile('Patents', '${metric.patentsCount}', Icons.verified_outlined, AppTheme.accentGreen)),
              const SizedBox(width: 8),
              Expanded(child: _buildResearchTile('FDPs / Workshops', '${metric.fdpsCount}', Icons.workspace_premium_outlined, AppTheme.accentOrange)),
              const SizedBox(width: 8),
              Expanded(child: _buildResearchTile('Funded Projects', '${metric.fundedProjectsCount}', Icons.account_balance_outlined, AppTheme.accentTeal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResearchTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
