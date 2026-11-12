import 'package:flutter/material.dart';

import 'tokens.dart';

/// Body of every desktop screen. The top bar (AppTopNav) sits in the same container; this places
/// the page content inside it: a centred 1200px container with responsive side padding, narrower
/// content left-aligned to the container edge, and an optional 360px rail that stacks under the
/// main column below 1100px. [ContentWidth.tight] is the one width that centres itself.
class PageShell extends StatelessWidget {
  final ContentWidth contentWidth;
  final Widget child;
  final Widget? rail;
  final double railWidth;
  final bool scroll;
  final ScrollController? controller;

  const PageShell({super.key, required this.child, this.contentWidth = ContentWidth.full, this.rail, this.railWidth = Ui.railWidth, this.scroll = true, this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final stacked = w < Ui.railStackBelow;
      final main = ConstrainedBox(constraints: BoxConstraints(maxWidth: contentWidth.max), child: child);
      final Widget content;
      if (rail == null) {
        content = contentWidth == ContentWidth.tight ? Center(child: main) : Align(alignment: Alignment.topLeft, child: main);
      } else if (stacked) {
        content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [main, const SizedBox(height: Ui.betweenSections), rail!]);
      } else {
        content = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: main), const SizedBox(width: Ui.railGap), SizedBox(width: railWidth, child: rail)]);
      }
      final padded = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Ui.contentWidth(w)),
          child: Padding(padding: const EdgeInsets.only(top: Ui.topBarToHeader, bottom: Ui.s64), child: content),
        ),
      );
      return scroll ? SingleChildScrollView(controller: controller, child: SizedBox(width: w, child: padded)) : padded;
    });
  }
}
