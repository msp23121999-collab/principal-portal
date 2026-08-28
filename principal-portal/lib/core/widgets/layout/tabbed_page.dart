import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../utils/responsive_utils.dart';
import '../motion/fade_in.dart';
import 'page_header.dart';

/// A single tab in a [TabbedPage] — label plus its scrollable content.
class PageTab {
  const PageTab({required this.label, required this.content, this.icon});

  final String label;
  final Widget content;
  final IconData? icon;
}

/// Standard shell for tabbed feature pages (Attendance Analytics, Principal
/// Profile): fixed PageHeader + TabBar, with each tab's content scrolling
/// independently beneath — used instead of nesting TabBarView inside a
/// page-level ScrollView, which doesn't give TabBarView the bounded height
/// it needs.
class TabbedPage extends StatefulWidget {
  const TabbedPage({
    super.key,
    this.title,
    required this.tabs,
    this.breadcrumbSegments,
    this.subtitle,
    this.actions = const [],
    this.filterBar,
    this.header,
    this.onTabChanged,
    this.onRefresh,
  });

  final String? title;
  final List<PageTab> tabs;
  final List<String>? breadcrumbSegments;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? filterBar;

  /// Called with the new index whenever the visible tab changes.
  ///
  /// The header actions are built by the screen and handed in, so a button up
  /// there has no way of knowing which tab is below it. Screens that need it —
  /// the ones whose Export button should act on the table in view — record the
  /// index in [activeTabProvider] from here.
  final ValueChanged<int>? onTabChanged;

  /// Custom header replacing the default [PageHeader] — used by screens
  /// like Principal Profile that need a [ProfileBanner] instead.
  final Widget? header;

  /// Opt-in pull-to-refresh, applied to every tab of the page.
  ///
  /// Left null by default because most pages here are analytics that recompute
  /// from the shared filters, and a pull gesture that silently did nothing
  /// would be worse than none. Pages whose content is a work queue the
  /// Principal acts on — Approvals — supply it. The returned future is awaited
  /// by the indicator, so it must complete only when the data has actually
  /// landed.
  final Future<void> Function()? onRefresh;

  @override
  State<TabbedPage> createState() => _TabbedPageState();
}

class _TabbedPageState extends State<TabbedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabs.length,
    vsync: this,
  );

  /// Guards against reporting the same index twice. The controller notifies
  /// several times per tap — once when the index jumps, again as the animation
  /// settles — and a listener that fires on every one would write the same
  /// value to a provider repeatedly, rebuilding the header for nothing.
  int _reportedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.onTabChanged != null) {
      _controller.addListener(_reportIndex);
    }
  }

  void _reportIndex() {
    if (_controller.index == _reportedIndex) return;
    _reportedIndex = _controller.index;
    widget.onTabChanged!(_controller.index);
  }

  @override
  void dispose() {
    _controller.removeListener(_reportIndex);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.pagePadding(context);

    return Column(
      // Stretch, not the default centre. Each child here shrink-wraps its own
      // content — the header to its title and actions, the tab bar to its
      // labels — so a centring Column left the title, the tabs and the cards
      // below them all starting at different distances from the edge. It was
      // most obvious on pages with wide header actions, where the title sat
      // 260px in from the content beneath it.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
          child:
              widget.header ??
              PageHeader(
                title: widget.title!,
                breadcrumbSegments: widget.breadcrumbSegments,
                subtitle: widget.subtitle,
                actions: widget.actions,
              ),
        ),
        if (widget.filterBar != null)
          Padding(
            padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
            child: widget.filterBar!,
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: TabBar(
                controller: _controller,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: AppColors.accentBlue,
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.accentBlue,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.accentBlue.withValues(alpha: 0.06);
                  }
                  return Colors.transparent;
                }),
                dividerColor: Colors.transparent,
                tabs: [
                  for (final t in widget.tabs)
                    Tab(
                      height: 48,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (t.icon != null) ...[
                            Icon(t.icon, size: 18),
                            const SizedBox(width: 6),
                          ],
                          Text(t.label),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              for (final t in widget.tabs)
                _TabBody(
                  padding: padding,
                  onRefresh: widget.onRefresh,
                  // Keyed on the tab so the entrance replays when the Principal
                  // switches tabs. Without a key the subtree is reused and the
                  // new tab's content simply appears, which on a page of dense
                  // tables reads as a flicker rather than a change of view.
                  child: FadeIn(
                    key: ValueKey(t.label),
                    duration: AppMotion.fast,
                    offsetY: 6,
                    child: t.content,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One tab's scrollable body, with pull-to-refresh when the page offers it.
class _TabBody extends StatelessWidget {
  const _TabBody({required this.padding, required this.child, this.onRefresh});

  final double padding;
  final Widget child;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      // A tab whose content is shorter than the viewport does not scroll, and a
      // RefreshIndicator over a non-scrollable child never receives the drag.
      // This keeps the gesture available on a queue that has emptied out —
      // exactly when the Principal is most likely to pull to check for new
      // arrivals.
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      child: child,
    );

    if (onRefresh == null) return scroll;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: AppColors.primaryBlue,
      child: scroll,
    );
  }
}
