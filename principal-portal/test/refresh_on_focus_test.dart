import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/app.dart';
import 'package:principal_portal/core/services/refresh_on_focus.dart';
import 'package:principal_portal/core/widgets/data_display/data_freshness_label.dart';
import 'package:principal_portal/features/approvals/providers/approvals_providers.dart';

import 'fixtures/portal_fixtures.dart';

/// Cover for refreshing when the browser tab comes back.
///
/// Providers here are plain `FutureProvider`s with no expiry, so a tab left
/// open all day showed the morning's figures under a clock reading the
/// afternoon. Refetching on `AppLifecycleState.resumed` closes that without
/// introducing polling — but a lifecycle event fires more often than a person
/// actually returns to the tab, so the debounce is the part that decides
/// whether this is a fix or a request loop.
void main() {
  const surface = Size(1600, 1400);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    }
  }

  group('the debounce', () {
    // Driven directly rather than through lifecycle events so the clock is
    // controlled: the whole point is what happens at 29 seconds versus 31.
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: portalOverrides());
      addTearDown(container.dispose);
    });

    test('a first refresh always runs', () {
      final ran = RefreshOnFocus.refreshNow(
        _Ref(container),
        last: null,
        onRefreshed: (_) {},
        now: DateTime(2026, 8, 15, 9),
      );

      expect(ran, isTrue);
    });

    test('a second refresh inside the window is skipped', () {
      final first = DateTime(2026, 8, 15, 9);

      final ran = RefreshOnFocus.refreshNow(
        _Ref(container),
        last: first,
        onRefreshed: (_) {},
        now: first.add(const Duration(seconds: 29)),
      );

      expect(
        ran,
        isFalse,
        reason:
            'Alt-tabbing fires resumed repeatedly. Without this floor each one '
            'would start another round of fetches.',
      );
    });

    test('a refresh after the window runs', () {
      final first = DateTime(2026, 8, 15, 9);

      final ran = RefreshOnFocus.refreshNow(
        _Ref(container),
        last: first,
        onRefreshed: (_) {},
        now: first.add(const Duration(seconds: 31)),
      );

      expect(ran, isTrue);
    });

    test('the recorded time is the refresh time, not the previous one', () {
      final at = DateTime(2026, 8, 15, 14, 5);
      DateTime? stamped;

      RefreshOnFocus.refreshNow(
        _Ref(container),
        last: null,
        onRefreshed: (t) {
          stamped = t;
        },
        now: at,
      );

      expect(stamped, at);
      expect(container.read(lastRefreshedAtProvider), at);
    });

    test('a skipped refresh does not restamp the time', () {
      final first = DateTime(2026, 8, 15, 9);
      container.read(lastRefreshedAtProvider.notifier).state = first;

      RefreshOnFocus.refreshNow(
        _Ref(container),
        last: first,
        onRefreshed: (_) {},
        now: first.add(const Duration(seconds: 5)),
      );

      expect(
        container.read(lastRefreshedAtProvider),
        first,
        reason: 'Nothing was refetched, so nothing newer was read.',
      );
    });
  });

  group('in the running app', () {
    testWidgets('the shell mounts the refresher exactly once', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() {
        tester.view.reset();
        return tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: portalOverrides(),
          child: const PrincipalPortalApp(),
        ),
      );
      await settle(tester);

      // One observer, not one per route branch — nineteen of them would fire
      // nineteen refreshes for a single tab switch.
      expect(find.byType(RefreshOnFocus), findsOneWidget);
    });

    testWidgets('the Dashboard dates its figures once a fetch is stamped', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() {
        tester.view.reset();
        return tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: portalOverrides(),
          child: const PrincipalPortalApp(),
        ),
      );
      await settle(tester);

      expect(find.byType(DataFreshnessLabel), findsOneWidget);
      expect(
        find.textContaining('Updated '),
        findsOneWidget,
        reason:
            'The top bar shows a live clock; without this the snapshot beside '
            'it reads as current to the minute.',
      );
    });

    testWidgets('losing focus refetches nothing, regaining it refetches once', (
      tester,
    ) async {
      // Mounted directly rather than through the whole app so a real lifecycle
      // event can be driven with the debounce stood down; the window itself is
      // covered by the clock-controlled tests above.
      var fetches = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...portalOverrides(),
            approvalRequestsProvider.overrideWith((ref) async {
              fetches++;
              return const [];
            }),
          ],
          child: MaterialApp(
            home: RefreshOnFocus(
              minimumInterval: Duration.zero,
              child: Consumer(
                builder: (context, ref, _) {
                  ref.watch(approvalRequestsProvider);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = fetches;
      expect(before, greaterThan(0));

      // Going away costs nothing. Flutter only permits the real transition
      // order, which is also the order a browser tab actually reports.
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
      }

      expect(
        fetches,
        before,
        reason:
            'Refetching a page nobody is looking at spends a request for '
            'nothing.',
      );

      // Coming back: hidden -> inactive -> resumed. Only the last one refetches.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(fetches, before, reason: 'Still not back yet.');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        fetches,
        before + 1,
        reason: 'One return to the tab is one refetch, not none and not many.',
      );
    });
  });
}

/// Minimal [WidgetRef] over a [ProviderContainer].
///
/// `refreshNow` needs only `invalidate` and `read`; implementing the whole
/// interface would be noise. `noSuchMethod` makes any other call fail loudly
/// rather than silently returning null.
class _Ref implements WidgetRef {
  _Ref(this._container);

  final ProviderContainer _container;

  @override
  T read<T>(ProviderListenable<T> provider) => _container.read(provider);

  @override
  void invalidate(ProviderOrFamily provider, {bool asReload = false}) =>
      _container.invalidate(provider);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not needed here.');
}
