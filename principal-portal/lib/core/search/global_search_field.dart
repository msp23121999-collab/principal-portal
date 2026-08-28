import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../filters/portal_filter_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/inputs/search_field.dart';
import 'global_search.dart';

/// The top bar's search box, with results.
///
/// The field used to have no handler at all: it sat on every screen inviting
/// the Principal to type and did nothing with what they typed. It now matches
/// against the roll, the roster and the department list, and selecting a
/// result opens the relevant screen already narrowed to that department —
/// otherwise the Principal lands on a page showing the whole institution and
/// has to find the row again.
class GlobalSearchField extends ConsumerStatefulWidget {
  const GlobalSearchField({super.key, required this.onNavigate});

  /// Called with the route to open once a result is chosen.
  final void Function(String route) onNavigate;

  @override
  ConsumerState<GlobalSearchField> createState() => _GlobalSearchFieldState();
}

class _GlobalSearchFieldState extends ConsumerState<GlobalSearchField> {
  final _controller = TextEditingController();
  final _link = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _onChanged(String value) {
    ref.read(globalSearchQueryProvider.notifier).state = value;
    final hasResults = ref.read(globalSearchResultsProvider).isNotEmpty;

    if (!hasResults) {
      _removeOverlay();
      return;
    }
    if (_overlay == null) {
      _overlay = _buildOverlay();
      Overlay.of(context).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _select(SearchHit hit) {
    // Narrowing to the hit's department is what makes the jump useful: the
    // screen opens showing the thing that was searched for.
    ref.read(portalFiltersProvider.notifier).setDepartment(hit.departmentCode);

    _controller.clear();
    ref.read(globalSearchQueryProvider.notifier).state = '';
    _removeOverlay();
    widget.onNavigate(hit.kind.route);
  }

  OverlayEntry _buildOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 520,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: AppRadius.mdRadius,
            child: Consumer(
              builder: (context, ref, _) {
                final hits = ref.watch(globalSearchResultsProvider);
                if (hits.isEmpty) return const SizedBox.shrink();

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: hits.length,
                    itemBuilder: (context, i) => _hitTile(context, hits[i]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _hitTile(BuildContext context, SearchHit hit) {
    final icon = switch (hit.kind) {
      SearchHitKind.student => AppIcons.students,
      SearchHitKind.faculty => AppIcons.faculty,
      SearchHitKind.department => AppIcons.department,
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.primaryBlue),
      title: Text(hit.title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(
        hit.subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      // The kind is worth stating: a name alone does not say whether it is a
      // student or a member of staff.
      trailing: Text(
        hit.kind.label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.secondaryText),
      ),
      onTap: () => _select(hit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: SearchField(
        controller: _controller,
        hintText: 'Search students, faculty, departments...',
        onChanged: _onChanged,
      ),
    );
  }
}
