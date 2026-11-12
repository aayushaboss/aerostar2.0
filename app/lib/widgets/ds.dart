import 'package:flutter/material.dart';

import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Primitives of the Aerostar Minimal design system. Small on purpose: hairlines, the grey
/// "mark" tile for logos and avatars, section headings, text links, signal chips and a thin
/// progress bar. Screens build their rows out of these instead of cards and shadows.

const Color kLine = AppColors.border;

class Hairline extends StatelessWidget {
  final double height;
  const Hairline({super.key, this.height = 1});

  @override
  Widget build(BuildContext context) => AppBreakpoints.isWide(context) ? Container(height: height, color: kLine) : const SizedBox(height: 0);
}

/// Grey tile with initials: a company mark (rounded square) or a person (circle).
class MarkTile extends StatelessWidget {
  final String text;
  final double size;
  final bool round;
  const MarkTile(this.text, {super.key, this.size = 40, this.round = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: round ? null : BorderRadius.circular(AppRadius.sm), shape: round ? BoxShape.circle : BoxShape.rectangle),
      child: Text(text, style: AppTextStyles.label.copyWith(fontSize: size <= 32 ? 11 : 13, color: AppColors.ink)),
    );
  }
}

/// Text-only action in a list row: "Connect", "Accept", "View all".
class LinkText extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const LinkText(this.label, {super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 13, color: onTap == null ? AppColors.gray500 : (color ?? AppColors.blue))),
          ),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final Object? count;
  final String? link;
  final VoidCallback? onLink;
  final EdgeInsetsGeometry padding;
  const SectionHeading(this.title, {super.key, this.count, this.link, this.onLink, this.padding = const EdgeInsets.only(top: 24, bottom: 4)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppTextStyles.h3),
          if (count != null) ...[const SizedBox(width: 6), Text('$count', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))],
          const Spacer(),
          if (link != null) LinkText(link!, onTap: onLink),
        ],
      ),
    );
  }
}

enum SignalKind { blue, amber, grey, green, violet }

/// Small tinted label used only for match, urgency and status.
class SignalChip extends StatelessWidget {
  final String label;
  final SignalKind kind;
  const SignalChip(this.label, {super.key, this.kind = SignalKind.blue});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      SignalKind.blue => (const Color(0x0F0A2FFF), AppColors.blue),
      SignalKind.amber => (const Color(0x1FFF9500), AppColors.warningDark),
      SignalKind.grey => (AppColors.offWhite, AppColors.body),
      SignalKind.green => (const Color(0x1A4CAF50), AppColors.successDark),
      SignalKind.violet => (const Color(0x0F7C4DFF), AppColors.violet),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 11, letterSpacing: 0.15, color: fg, fontFeatures: const [FontFeature.tabularFigures()], height: 1.3)),
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  const ScoreBar(this.value, {super.key, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: height, backgroundColor: kLine, color: AppColors.blue),
    );
  }
}

/// Grey search / input well: 40px, 6px corners, no border.
class FieldWell extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  const FieldWell({super.key, required this.child, this.height = 40, this.padding = const EdgeInsets.symmetric(horizontal: 12)});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, padding: padding, alignment: Alignment.centerLeft, decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.sm)), child: child);
  }
}

/// Tappable row with a hairline underneath and a hover fill on the web.
class HairlineRow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minHeight;
  final bool? border;
  const HairlineRow({super.key, required this.child, this.onTap, this.minHeight = 64, this.border});

  @override
  State<HairlineRow> createState() => _HairlineRowState();
}

class _HairlineRowState extends State<HairlineRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          decoration: BoxDecoration(color: _hover && widget.onTap != null ? AppColors.offWhite : Colors.transparent, border: (widget.border ?? AppBreakpoints.isWide(context)) ? const Border(bottom: BorderSide(color: kLine)) : null),
          child: widget.child,
        ),
      ),
    );
  }
}
