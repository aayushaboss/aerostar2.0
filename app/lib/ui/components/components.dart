import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../tokens.dart';

/// Shared components for every desktop screen. Built once, reused everywhere.

/// Main tabs: 32px title + optional subtitle, actions on the right. Inner screens: back chevron
/// (or close x), 24px title, subtitle, actions. 28px gap below.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool close;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const [], this.onBack, this.close = false});

  @override
  Widget build(BuildContext context) {
    final inner = onBack != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Ui.headerToContent),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (inner)
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.only(right: Ui.s12), child: SizedBox(width: 36, height: 36, child: Icon(close ? Ionicons.close : Ionicons.chevron_back, size: 22, color: Ui.ink))),
          ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: inner ? Ui.innerTitle : Ui.pageTitle),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: Ui.titleToSubtitle), child: Text(subtitle!, style: Ui.meta.copyWith(fontSize: 14))),
          ]),
        ),
        for (final a in actions) Padding(padding: const EdgeInsets.only(left: Ui.s12), child: a),
      ]),
    );
  }
}

/// 17/500 heading with an optional "View all" link on the same baseline. 16 to its content.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? link;
  final VoidCallback? onLink;
  final double top;
  const SectionHeader(this.title, {super.key, this.link, this.onLink, this.top = Ui.betweenSections});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: Ui.headingToContent),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(title, style: Ui.sectionHeading)),
          if (link != null) GestureDetector(onTap: onLink, child: MouseRegion(cursor: SystemMouseCursors.click, child: Text(link!, style: Ui.link))),
        ]),
      );
}

class Avatar extends StatelessWidget {
  final String text;
  final bool round;
  final double size;
  const Avatar(this.text, {super.key, this.round = false, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Ui.surface, shape: round ? BoxShape.circle : BoxShape.rectangle, borderRadius: round ? null : BorderRadius.circular(Ui.rAvatar)),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Ui.ink)),
      );
}

/// 40px avatar or logo, 14px gap, title, meta, optional third line, optional action. Separated by
/// space, not lines. In a rail ([wrap]) text wraps to two lines and the action moves below it.
class ListRow extends StatelessWidget {
  final String mark;
  final bool round;
  final String title;
  final String? meta;
  final String? third;
  final Widget? action;
  final VoidCallback? onTap;
  final bool wrap;
  const ListRow({super.key, required this.mark, this.round = false, required this.title, this.meta, this.third, this.action, this.onTap, this.wrap = false});

  @override
  Widget build(BuildContext context) {
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: wrap ? 3 : 1, overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis, style: Ui.rowTitle),
      if (meta != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(meta!, maxLines: wrap ? 3 : 1, overflow: wrap ? TextOverflow.visible : TextOverflow.ellipsis, style: Ui.meta)),
      if (third != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(third!, style: Ui.label.copyWith(color: Ui.tertiary))),
      if (wrap && action != null) Padding(padding: const EdgeInsets.only(top: Ui.s12), child: action),
    ]);
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(crossAxisAlignment: wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
          Avatar(mark, round: round),
          const SizedBox(width: 14),
          Expanded(child: text),
          if (!wrap && action != null) ...[const SizedBox(width: Ui.s12), action!],
        ]),
      ),
    );
  }
}

/// 1px #EFEFED outline, 10px radius, 20px padding.
class UiCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const UiCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(padding: const EdgeInsets.all(Ui.cardPad), decoration: BoxDecoration(borderRadius: BorderRadius.circular(Ui.rCard), border: Border.all(color: Ui.line)), child: child),
        ),
      );
}

/// #F6F6F4, 10px radius, 20px padding: scores, summaries, label/value grids.
class InfoBox extends StatelessWidget {
  final Widget child;
  const InfoBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(Ui.cardPad), decoration: BoxDecoration(color: Ui.surface, borderRadius: BorderRadius.circular(Ui.rCard)), child: child);
}

/// The one highlight per screen: pale blue fill, 1px pale blue border, 24px padding.
class HighlightCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const HighlightCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(width: double.infinity, padding: const EdgeInsets.all(Ui.featuredPad), decoration: BoxDecoration(color: Ui.highlightBg, borderRadius: BorderRadius.circular(Ui.rCard), border: Border.all(color: Ui.highlightLine)), child: child),
        ),
      );
}

/// Plain text tabs: 14/500, 28px gap, 2px blue underline on the active one, 1px line under the
/// row. Counts follow the label. Not pills.
class UiTabs extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  final Map<String, int> counts;
  const UiTabs({super.key, required this.labels, required this.selected, required this.onSelect, this.counts = const {}});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Ui.line))),
        child: Row(children: [
          for (final l in labels)
            Padding(
              padding: const EdgeInsets.only(right: Ui.s28),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(l),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: Ui.s12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: l == selected ? Ui.blue : Colors.transparent, width: 2))),
                    child: Text(counts[l] == null ? l : '$l ${counts[l]}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: l == selected ? Ui.ink : Ui.tertiary)),
                  ),
                ),
              ),
            ),
        ]),
      );
}

enum UiButtonKind { primary, secondary, tertiary }

/// 44px tall buttons (32 when [compact], for rail actions): yellow primary, white secondary with a
/// 1px border, blue-text tertiary.
class UiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final UiButtonKind kind;
  final bool compact;
  final bool expand;
  final IconData? icon;

  /// Put the icon after the label ("Let's go →").
  final bool iconAfter;
  const UiButton(this.label, {super.key, this.onTap, this.kind = UiButtonKind.secondary, this.compact = false, this.expand = false, this.icon, this.iconAfter = false});

  @override
  Widget build(BuildContext context) {
    final fg = kind == UiButtonKind.tertiary ? Ui.blue : (onTap == null ? Ui.tertiary : Ui.ink);
    final box = Container(
      height: compact ? 32 : 44,
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: kind == UiButtonKind.tertiary ? Ui.s4 : (compact ? Ui.s16 : Ui.s24)),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kind == UiButtonKind.primary ? Ui.yellow : Colors.transparent, borderRadius: BorderRadius.circular(Ui.rField), border: kind == UiButtonKind.secondary ? Border.all(color: Ui.inputBorder) : null),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null && !iconAfter) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: Ui.s8)],
        Text(label, style: TextStyle(fontSize: compact ? 13 : 14, fontWeight: FontWeight.w500, color: fg)),
        if (icon != null && iconAfter) ...[const SizedBox(width: Ui.s8), Icon(icon, size: 16, color: fg)],
      ]),
    );
    final tappable = MouseRegion(cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click, child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: box));
    return expand ? tappable : UnconstrainedBox(alignment: Alignment.centerLeft, constrainedAxis: Axis.vertical, child: tappable);
  }
}

/// 6px dot plus coloured text. No pills.
class StatusText extends StatelessWidget {
  final String status;
  const StatusText(this.status, {super.key});

  static Color colorFor(String s) => switch (s) {
        'Interview' => Ui.statusInterview,
        'In Review' || 'In review' => Ui.statusReview,
        'Offer' || 'Success' => Ui.statusSuccess,
        _ => Ui.statusApplied,
      };

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: Ui.s8),
      Text(status == 'Rejected' ? 'Closed' : status, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c)),
    ]);
  }
}

/// 4-6px bar, #EFEFED track, blue fill.
class UiProgress extends StatelessWidget {
  final double value;
  final double height;
  const UiProgress(this.value, {super.key, this.height = 4});

  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(height / 2), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: height, backgroundColor: Ui.line, color: Ui.blue));
}

/// 12px label above a 44px input with a 1px #E8E8E6 border and 6px radius.
class UiField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  const UiField({super.key, required this.label, this.controller, this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Ui.label),
        const SizedBox(height: Ui.s8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: Ui.s12),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Ui.rField), border: Border.all(color: Ui.inputBorder)),
          child: TextField(controller: controller, onChanged: onChanged, style: Ui.body.copyWith(height: 1.2), decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: hint, hintStyle: Ui.body.copyWith(color: Ui.placeholder, height: 1.2))),
        ),
      ]);
}
