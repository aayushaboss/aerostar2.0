import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../ui/components/components.dart';
import '../ui/page_shell.dart';
import '../ui/tokens.dart';
import 'v2.dart';

/// Frame for every secondary page (saved, bookings, support, details...). Phone: a bar with a back
/// chevron and a left-aligned title, then the content. Wide: the shared [PageShell] with a
/// [PageHeader], so every page shares one container and one left edge.
class PageFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String backFallback;
  final String backLabel;
  final List<Widget> actions;
  final Widget child;

  /// Wrap [child] in a scrolling list. Turn off when the child scrolls itself.
  final bool scroll;

  /// Content width on desktop. Narrower widths stay left-aligned to the container edge.
  final ContentWidth contentWidth;

  /// Pinned to the bottom of the page on a phone (an Apply / Continue bar).
  final Widget? bottomBar;

  /// Legacy pixel width from older call sites; mapped onto [ContentWidth].
  final double? maxWidth;

  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.backFallback = '/tabs',
    this.backLabel = 'Back',
    this.actions = const [],
    this.scroll = true,
    this.contentWidth = ContentWidth.full,
    this.bottomBar,
    this.maxWidth,
  });

  ContentWidth get _width {
    final m = maxWidth;
    if (m == null) return contentWidth;
    if (m >= 1000) return ContentWidth.full;
    if (m >= 800) return ContentWidth.wide;
    if (m >= 700) return ContentWidth.medium;
    return ContentWidth.narrow;
  }

  void _back(BuildContext context) => context.canPop() ? context.pop() : context.go(backFallback);

  @override
  Widget build(BuildContext context) {
    final wide = AppBreakpoints.isWide(context);
    final Widget body = wide
        ? PageShell(
            contentWidth: _width,
            scroll: scroll,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PageHeader(title: title, subtitle: subtitle, onBack: () => _back(context), actions: actions),
              child,
            ]),
          )
        : SafeArea(
            bottom: false,
            child: Column(children: [
              V2Bar(title: title, onBack: () => _back(context), actions: actions, leading: Ionicons.chevron_back),
              if (subtitle != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 0), child: Align(alignment: Alignment.centerLeft, child: Text(subtitle!, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)))),
              Expanded(child: scroll ? ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [child]) : Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child)),
              if (bottomBar != null) Container(padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom), decoration: const BoxDecoration(border: Border(top: BorderSide(color: kHair))), child: bottomBar),
            ]),
          );
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: Scaffold(backgroundColor: AppColors.white, body: body));
  }
}
