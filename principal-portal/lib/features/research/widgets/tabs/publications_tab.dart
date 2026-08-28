import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/data_display/custom_data_table.dart';
import '../../../../core/widgets/data_display/status_chip.dart';
import '../../../../core/widgets/data_display/table_container.dart';
import '../../../../core/widgets/feedback/error_state.dart';
import '../../../../core/widgets/feedback/loading_skeleton.dart';
import '../../../../core/widgets/inputs/filter_dropdown.dart';
import '../../../../core/widgets/inputs/search_field.dart';
import '../../models/research.dart';
import '../../providers/research_providers.dart';

/// Indexed publications, searchable and filterable by index.
class PublicationsTab extends ConsumerWidget {
  const PublicationsTab({super.key});

  static const String _allIndexes = '__all__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicationsAsync = ref.watch(publicationsProvider);
    final index = ref.watch(publicationIndexFilterProvider);

    return publicationsAsync.when(
      loading: () => const CardSkeleton(height: 460),
      error: (err, st) => const ErrorState(),
      data: (publications) {
        final sorted = [...publications]
          ..sort((a, b) => b.citations.compareTo(a.citations));

        return TableContainer(
          title: 'Publications',
          subtitle: '${sorted.length} papers, most cited first',
          actions: [
            SearchField(
              width: 240,
              hintText: 'Search title, author, or venue',
              onChanged: (value) =>
                  ref.read(publicationSearchProvider.notifier).state = value,
            ),
            FilterDropdown<String>(
              value: index?.name ?? _allIndexes,
              items: [
                _allIndexes,
                ...PublicationIndex.values.map((value) => value.name),
              ],
              itemLabel: (value) => value == _allIndexes
                  ? 'All Indexes'
                  : PublicationIndex.values.byName(value).label,
              width: 175,
              onChanged: (value) =>
                  ref
                      .read(publicationIndexFilterProvider.notifier)
                      .state = value == _allIndexes
                  ? null
                  : PublicationIndex.values.byName(value!),
            ),
          ],
          child: CustomDataTable(
            emptyMessage: 'No publications match the current filters.',
            columns: const [
              DataColumnConfig(label: 'Title', size: ColumnSize.L),
              DataColumnConfig(label: 'Lead Author', size: ColumnSize.M),
              DataColumnConfig(label: 'Venue', size: ColumnSize.L),
              DataColumnConfig(label: 'Dept', size: ColumnSize.S),
              DataColumnConfig(label: 'Type', size: ColumnSize.S),
              DataColumnConfig(label: 'Year', numeric: true),
              DataColumnConfig(label: 'Citations', numeric: true),
              DataColumnConfig(label: 'Impact', numeric: true),
              DataColumnConfig(label: 'Index', size: ColumnSize.S),
            ],
            rows: [
              for (final publication in sorted) _publicationRow(publication),
            ],
          ),
        );
      },
    );
  }

  DataRow2 _publicationRow(Publication publication) {
    final isHighIndex =
        publication.index == PublicationIndex.webOfScience ||
        publication.index == PublicationIndex.scopus;

    return DataRow2(
      cells: [
        DataCell(Text(publication.title, overflow: TextOverflow.ellipsis)),
        DataCell(Text(publication.leadAuthor, overflow: TextOverflow.ellipsis)),
        DataCell(Text(publication.venue, overflow: TextOverflow.ellipsis)),
        DataCell(Text(publication.departmentCode)),
        DataCell(Text(publication.type.label)),
        DataCell(Text('${publication.year}')),
        DataCell(Text('${publication.citations}')),
        DataCell(
          Text(
            publication.impactFactor == 0
                ? '—'
                : publication.impactFactor.toStringAsFixed(1),
          ),
        ),
        DataCell(
          StatusChip(
            status: isHighIndex ? AppStatus.approved : AppStatus.info,
            customLabel: publication.index.label,
          ),
        ),
      ],
    );
  }
}
