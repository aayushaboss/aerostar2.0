import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/spacing.dart';
import '../ui/onboarding_split.dart';

/// Frames an onboarding or sign-in screen on a tablet or desktop; phones get [child] untouched.
///
/// * 960px and wider: the shared [OnboardingSplit]: brand content on the left (same frame as the
///   landing screen), the screen's own content as the form on the right.
/// * 600 to 959px: just a centred column.
class OnboardingFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  /// Hide the brand column (the "you're all set" page is already a single message).
  final bool showPanel;

  /// Kept for older call sites; the split frame is always light.
  final bool onBlue;

  const OnboardingFrame({super.key, required this.child, this.maxWidth = 480, this.showPanel = true, this.onBlue = false});

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isWide(context)) return child;
    final width = MediaQuery.sizeOf(context).width;

    if (width >= OnboardingSplit.stackBelow && showPanel) {
      return OnboardingSplit(
        footer: "India's Startup Talent Network",
        contentMaxWidth: 560,
        // Older step screens lay themselves out against a bounded height; give them one.
        content: SizedBox(height: math.max(520.0, MediaQuery.sizeOf(context).height - 220), child: child),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth, maxWidth + AppSpacing.xl * 2);
        return Padding(padding: EdgeInsets.symmetric(horizontal: (box.maxWidth - w) / 2), child: child);
      },
    );
  }
}
