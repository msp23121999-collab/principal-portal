import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/repository.dart';
import '../data/circulars_repository.dart';
import '../models/circular.dart';

final circularsRepositoryProvider = Provider((ref) => CircularsRepository());

/// Noticeboard as fetched, plus where it came from.
final circularsSourcedProvider = FutureProvider<Sourced<List<Circular>>>((ref) {
  return ref.watch(circularsRepositoryProvider).fetchAll();
});

/// Actions on the Principal's own circulars.
///
/// Publishing, archiving and pinning now write to `principal.circulars` and
/// refetch. They used to mutate an in-memory copy, so a published circular
/// reverted to draft on refresh.
///
/// Only the Principal's own circulars can be changed — notices read from the
/// HOD and Student portals belong to them.
final circularActionsProvider = Provider((ref) => CircularActions(ref));

class CircularActions {
  const CircularActions(this._ref);

  final Ref _ref;

  Future<void> compose({
    required String title,
    required String body,
    required CircularCategory category,
    required CircularAudience audience,
    bool asDraft = true,
  }) async {
    await _ref
        .read(circularsRepositoryProvider)
        .publish(
          title: title,
          body: body,
          category: category,
          audience: audience,
          asDraft: asDraft,
        );

    _ref.invalidate(circularsSourcedProvider);
  }

  Future<void> publish(String id) => _setStatus(id, CircularStatus.published);

  Future<void> archive(String id) => _setStatus(id, CircularStatus.archived);

  Future<void> setPinned(String id, bool pinned) async {
    await _ref.read(circularsRepositoryProvider).setPinned(id, pinned);
    _ref.invalidate(circularsSourcedProvider);
  }

  Future<void> _setStatus(String id, CircularStatus status) async {
    await _ref.read(circularsRepositoryProvider).setStatus(id, status);
    _ref.invalidate(circularsSourcedProvider);
  }
}

/// The noticeboard: the Principal's own circulars merged with the notices the
/// other portals publish.
final circularsProvider = Provider<List<Circular>>((ref) {
  return ref.watch(circularsSourcedProvider).valueOrNull?.value ?? const [];
});

/// Whether the Principal may act on a circular.
///
/// Only their own. The board also shows notices read from
/// `hod.department_notices` and `student.notice_board_posts`, which belong to
/// those portals — publishing or archiving one of those would mean writing
/// into a table this portal does not own.
///
/// The reference prefix is the discriminator, set when each source is mapped.
bool canEditCircular(Circular circular) =>
    circular.reference.startsWith('KSRCE/PRIN/');

/// Category filter, null meaning every category.
final circularCategoryFilterProvider = StateProvider<CircularCategory?>(
  (ref) => null,
);

/// Notices in one lifecycle state, pinned first and newest first.
final circularsByStatusProvider =
    Provider.family<List<Circular>, CircularStatus>((ref, status) {
      final category = ref.watch(circularCategoryFilterProvider);
      final circulars = ref
          .watch(circularsProvider)
          .where(
            (circular) =>
                circular.status == status &&
                (category == null || circular.category == category),
          )
          .toList();

      circulars.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      return circulars;
    });

final publishedCircularCountProvider = Provider<int>((ref) {
  return ref
      .watch(circularsProvider)
      .where((c) => c.status == CircularStatus.published)
      .length;
});

final draftCircularCountProvider = Provider<int>((ref) {
  return ref
      .watch(circularsProvider)
      .where((c) => c.status == CircularStatus.draft)
      .length;
});

/// Average readership across published notices.
final averageReadPercentProvider = Provider<double>((ref) {
  final published = ref
      .watch(circularsProvider)
      .where((c) => c.status == CircularStatus.published)
      .toList();
  if (published.isEmpty) return 0;
  return published.fold(0.0, (sum, c) => sum + c.readPercent) /
      published.length;
});
