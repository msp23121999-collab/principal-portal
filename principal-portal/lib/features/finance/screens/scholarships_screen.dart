import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/table_export.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/layout/content_scaffold.dart';
import '../../../core/widgets/layout/page_header.dart';
import '../providers/finance_providers.dart';
import '../widgets/tabs/scholarships_tab.dart';

class ScholarshipsScreen extends ConsumerWidget {
  const ScholarshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ContentScaffold(
      children: [
        PageHeader(
          title: 'Scholarships',
          breadcrumbSegments: const ['Administration', 'Scholarships'],
          subtitle:
              'Institution-level visibility and monitoring of scholarship activities.',
          actions: [
            PrimaryButton(
              label: 'Export Report',
              icon: AppIcons.download,
              onPressed: () => _export(context, ref),
            ),
          ],
        ),
        const ScholarshipsTab(),
      ],
    );
  }

  void _export(BuildContext context, WidgetRef ref) {
    final schemes = ref.read(scholarshipsProvider).valueOrNull ?? const [];
    TableExport.run(
      context,
      fileName: 'scholarship_schemes',
      noun: 'scheme',
      headers: const [
        'Scheme',
        'Sponsor',
        'Beneficiaries',
        'Sanctioned',
        'Disbursed',
        'Pending',
        'Disbursed %',
      ],
      rows: [
        for (final s in schemes)
          [
            s.name,
            s.sponsor,
            s.beneficiaries,
            s.sanctioned,
            s.disbursed,
            s.pending,
            s.disbursedPercent.toStringAsFixed(2),
          ],
      ],
    );
  }
}
