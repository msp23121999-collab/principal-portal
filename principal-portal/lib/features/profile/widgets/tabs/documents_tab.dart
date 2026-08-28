import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/buttons/icon_action_button.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../providers/principal_profile_providers.dart';

/// Verified identity, appointment, and accreditation documents.
class DocumentsTab extends ConsumerWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(principalProfileProvider);

    return profileAsync.when(
      loading: () => const CardSkeleton(height: 320),
      error: (err, st) => const ErrorState(),
      data: (profile) => TableContainer(
        title: 'Documents (Verified)',
        subtitle: '${profile.documents.length} documents on file',
        child: CustomDataTable(
          columns: const [
            DataColumnConfig(label: 'Document', size: ColumnSize.L),
            DataColumnConfig(label: 'Type', size: ColumnSize.S),
            DataColumnConfig(label: 'Uploaded', size: ColumnSize.S),
            DataColumnConfig(label: '', size: ColumnSize.S),
          ],
          rows: [
            for (final d in profile.documents)
              DataRow2(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.document, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            d.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(d.type)),
                  DataCell(Text(DateFormatter.shortDate(d.uploadedAt))),
                  DataCell(
                    // Disabled: `principal.profile_documents` records a
                    // document's name, type and upload date — never the file.
                    // This used to say "Download simulated", which told the
                    // Principal their verified documents were retrievable.
                    const IconActionButton(
                      icon: AppIcons.download,
                      tooltip:
                          'No file stored — this lists documents on record',
                      onPressed: null,
                      color: AppColors.border,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
