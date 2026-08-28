import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/approvals/providers/approvals_providers.dart';
import '../../features/dashboard/providers/dashboard_providers.dart';
import '../../features/leave/providers/leave_providers.dart';
import '../../features/notifications/providers/notifications_providers.dart';

/// When the portal's data was last read from the database.
///
/// Null until the first refresh. Surfaces on the Dashboard so a figure on
/// screen can be dated — the top bar shows a live clock, which made a
/// morning's numbers look like this minute's.
final lastRefreshedAtProvider = StateProvider<DateTime?>((ref) => null);

/// Refetches the surfaces worth refetching when the browser tab comes back.
///
/// ## The problem this addresses
///
/// Every provider in the portal is a plain `FutureProvider`: fetched once, held
/// for the life of the browser session, and refreshed only when a write
/// invalidates it or the Principal presses refresh. A tab left open since nine
/// o'clock shows nine o'clock's figures — beside a clock that says four.
///
/// ## Why focus, and not polling
///
/// Polling costs a request per interval per open tab whether or not anybody is
/// looking, and the portal has no realtime subscription to piggyback on. The
/// moment that actually matters is the one where the Principal returns to the
/// tab, which is exactly what `AppLifecycleState.resumed` reports on web
/// (Flutter maps the browser's `visibilitychange` onto it).
///
/// ## What is refreshed, and what is not
///
/// Only the three surfaces where staleness changes a decision: the Dashboard
/// totals, the approvals queue (including leave, which the sidebar badge counts
/// with it), and the notification feed. The analytics screens are not
/// refreshed — they are read deliberately rather than glanced at, they each
/// carry their own filters and refresh control, and refetching a dozen chart
/// queries on every tab switch would be the aggressive polling this avoids.
///
/// Invalidation only marks a provider dirty; Riverpod refetches those with a
/// live listener and leaves the rest alone. A screen the Principal is not
/// looking at costs nothing.
class RefreshOnFocus extends ConsumerStatefulWidget {
  const RefreshOnFocus({
    super.key,
    required this.child,
    this.minimumInterval = defaultMinimumInterval,
  });

  final Widget child;

  /// The shortest gap between two focus-driven refreshes.
  ///
  /// Overridable so a widget test can drive a real lifecycle event without
  /// waiting out the window on the wall clock; the app always uses the default.
  final Duration minimumInterval;

  /// The shortest gap between two focus-driven refreshes.
  ///
  /// Alt-tabbing across windows fires `resumed` repeatedly; without a floor
  /// each one would start another round of fetches. Thirty seconds is long
  /// enough to collapse a burst and short enough that a genuine return to the
  /// tab after a meeting always refreshes.
  static const Duration defaultMinimumInterval = Duration(seconds: 30);

  /// Marks the high-value surfaces stale and records when.
  ///
  /// Static and parameterised so a test can drive it without a lifecycle event
  /// and with a controlled clock — the debounce is the part most likely to
  /// regress into a refresh loop, and it is invisible in a widget test.
  ///
  /// Returns whether a refresh actually ran.
  static bool refreshNow(
    WidgetRef ref, {
    required DateTime? last,
    required void Function(DateTime) onRefreshed,
    Duration minimumInterval = defaultMinimumInterval,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();

    if (last != null && at.difference(last) < minimumInterval) return false;

    // Roots only. Everything else on these screens is derived from them, so
    // invalidating a derived provider as well would queue a second fetch of
    // data the first one already brought back.
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(recentActivitiesProvider);
    ref.invalidate(approvalRequestsProvider);
    ref.invalidate(leaveSourcedProvider);
    ref.invalidate(notificationsSourcedProvider);

    onRefreshed(at);
    ref.read(lastRefreshedAtProvider.notifier).state = at;
    return true;
  }

  @override
  ConsumerState<RefreshOnFocus> createState() => _RefreshOnFocusState();
}

class _RefreshOnFocusState extends ConsumerState<RefreshOnFocus>
    with WidgetsBindingObserver {
  DateTime? _lastRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Stamp the first load too, otherwise the Dashboard has nothing to date its
    // figures with until the Principal happens to switch tabs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      _lastRefresh = now;
      ref.read(lastRefreshedAtProvider.notifier).state = now;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only on the way back in. `paused`, `inactive` and `hidden` all fire when
    // the tab loses focus, and refetching then would spend a request on a page
    // nobody is looking at.
    if (state != AppLifecycleState.resumed) return;

    RefreshOnFocus.refreshNow(
      ref,
      last: _lastRefresh,
      minimumInterval: widget.minimumInterval,
      onRefreshed: (at) => _lastRefresh = at,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
