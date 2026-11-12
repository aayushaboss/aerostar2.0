import 'package:flutter/material.dart';

import '../ui/tokens.dart';

/// Web layout rule: the top bar spans the window with 40px side padding, and page content starts
/// 120px from the left on every screen (never re-centred, so narrower screens keep that edge).
/// On windows narrower than 1280 the edge shrinks proportionally, never below 24px.
///
/// [inset] is the horizontal padding the child already applies inside itself.
class WebAlign extends StatelessWidget {
  final Widget child;
  final double inset;
  const WebAlign({super.key, required this.child, this.inset = 24});

  static double leftEdge(double width) => Ui.leftEdge(width);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final pad = (leftEdge(box.maxWidth) - inset).clamp(0.0, double.infinity);
      return Align(alignment: Alignment.topLeft, child: Padding(padding: EdgeInsets.only(left: pad), child: child));
    });
  }
}
