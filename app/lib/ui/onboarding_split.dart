import 'package:flutter/material.dart';

import '../widgets/brand.dart';
import 'tokens.dart';

/// Shared two-column frame for every desktop onboarding screen. Left: the photo, in a panel with a
/// 16px radius. Right: white column with the logo pinned top-left, the content (sign-in buttons or
/// the form) vertically centred, and a footer line pinned bottom-left. Going from landing to a step
/// only changes the content on the right; the photo stays.
///
/// Side padding follows the app container ([Ui.sidePad]: 24 / 48 / 64), the same as every page.
/// Below [stackBelow] the photo is hidden and the content stacks under the logo.
class OnboardingSplit extends StatelessWidget {
  final Widget content;
  final String footer;
  final double contentMaxWidth;

  static const double stackBelow = 960;
  static const String photo = 'assets/images/landing-hero.png';

  const OnboardingSplit({super.key, required this.content, required this.footer, this.contentMaxWidth = 480});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight.isFinite ? box.maxHeight : MediaQuery.sizeOf(context).height;
      final side = Ui.sidePad(w);

      if (w < stackBelow) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(side, Ui.s32, side, Ui.s32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Wordmark(size: 24),
              const SizedBox(height: Ui.s32),
              ConstrainedBox(constraints: BoxConstraints(maxWidth: contentMaxWidth), child: content),
              const SizedBox(height: Ui.s32),
              Text(footer, style: Ui.meta),
            ]),
          ),
        );
      }

      final photoPanel = Padding(
        padding: EdgeInsets.fromLTRB(side, Ui.s32, 0, Ui.s32),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(photo, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
      );
      final contentColumn = Padding(
        padding: EdgeInsets.fromLTRB(side, Ui.s32, side, Ui.s32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Wordmark(size: 26),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: contentMaxWidth), child: SingleChildScrollView(child: content)))),
          Text(footer, style: Ui.meta),
        ]),
      );
      final row = SizedBox(height: h < 720 ? 720 : h, child: Row(children: [Expanded(child: photoPanel), Expanded(child: contentColumn)]));
      return h < 720 ? SingleChildScrollView(child: row) : row;
    });
  }
}
