import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import 'page_header.dart';

/// A single tab in a [TabbedPage] — label plus its scrollable content.
class PageTab {
  const PageTab({required this.label, required this.content});

  final String label;
  final Widget content;
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
    this.header,
  });

  final String? title;
  final List<PageTab> tabs;
  final List<String>? breadcrumbSegments;
  final String? subtitle;
  final List<Widget> actions;

  /// Custom header replacing the default [PageHeader] — used by screens
  /// like Principal Profile that need a [ProfileBanner] instead.
  final Widget? header;

  @override
  State<TabbedPage> createState() => _TabbedPageState();
}

class _TabbedPageState extends State<TabbedPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.tabs.length,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.pagePadding(context);

    return Column(
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _controller,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final t in widget.tabs) Tab(text: t.label)],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              for (final t in widget.tabs)
                SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: t.content,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
