import 'package:flutter/material.dart';
import 'package:erp_unified/modules/admin/app/theme/app_typography.dart';

class AppLoadingState extends StatelessWidget {
  final String label;

  const AppLoadingState({
    super.key,
    this.label = 'Loading Admin Portal...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                backgroundColor: Color(0xFFE2E8F0),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'KSRCE ERP System',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: AppTypography.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


