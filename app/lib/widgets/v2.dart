import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/opportunity.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'ds.dart';

/// Aerostar Minimal v2 ("more room, fewer lines") building blocks for the phone layouts:
/// 20px side margins, 32px between sections, no divider under every row, text tabs instead of
/// chips, status as coloured text. Blue marks the active item and links; yellow is the one filled
/// button per screen.

const double kPad = 20;
const Color kHair = Color(0xFFEFEFED);
const Color kPaleBlue = Color(0xFFF6F8FF);
const Color kPaleBlueLine = Color(0xFFE4E9FF);
const Color kTrack = Color(0xFFE2E2DF);

/// "₹17,000–₹25,000/month" -> "₹17–25k/mo"; "₹3.5–₹6.8 LPA" stays as written.
String shortPay(Opportunity o) {
  final raw = (o.type == 'Internship' ? (o.internStipend ?? o.stipend) : (o.salaryRange.isNotEmpty ? o.salaryRange : o.stipend)).trim();
  final isMonthly = raw.toLowerCase().contains('month') || raw.contains('/mo');
  final nums = RegExp(r'[\d,]+(?:\.\d+)?').allMatches(raw).map((m) => m.group(0)!.replaceAll(',', '')).toList();
  if (isMonthly && nums.isNotEmpty) {
    String k(String n) {
      final v = double.tryParse(n) ?? 0;
      final x = v >= 1000 ? v / 1000 : v;
      return x == x.roundToDouble() ? x.round().toString() : x.toStringAsFixed(1);
    }
    return nums.length >= 2 ? '₹${k(nums[0])}–${k(nums[1])}k/mo' : '₹${k(nums[0])}k/mo';
  }
  return raw.replaceAll('₹3.5–₹6.8', '₹3.5–6.8').replaceAllMapped(RegExp(r'–₹'), (_) => '–');
}

/// Tabs as text with a 2px underline on the active one.
class TextTabs extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelect;
  final Map<String, int> counts;
  final EdgeInsetsGeometry padding;
  const TextTabs({super.key, required this.labels, required this.selected, required this.onSelect, this.counts = const {}, this.padding = const EdgeInsets.fromLTRB(kPad, 16, kPad, 0)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(children: [
        for (final l in labels)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(l);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: l == selected ? AppColors.blue : Colors.transparent, width: 2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(l, style: AppTextStyles.bodyLg.copyWith(color: l == selected ? AppColors.ink : const Color(0xFF8A8A8A))),
                  if (counts[l] != null) ...[const SizedBox(width: 6), Text('${counts[l]}', style: AppTextStyles.caption.copyWith(color: const Color(0xFF8A8A8A), fontFeatures: const [FontFeature.tabularFigures()]))],
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 17/500 section title with an optional "View all" link; 32px above.
class V2Section extends StatelessWidget {
  final String title;
  final String? link;
  final VoidCallback? onLink;
  final double top;
  const V2Section(this.title, {super.key, this.link, this.onLink, this.top = 32});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(kPad, top, kPad, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Expanded(child: Text(title, style: AppTextStyles.h2.copyWith(fontSize: 17, letterSpacing: -0.17))),
        if (link != null) GestureDetector(onTap: onLink, child: Text(link!, style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue))),
      ]),
    );
  }
}

/// Rows separated by space, not lines.
class V2List extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final double top;
  final double side;
  const V2List({super.key, required this.children, this.gap = 24, this.top = 20, this.side = kPad});

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return Padding(padding: EdgeInsets.fromLTRB(side, top, side, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out));
  }
}

/// Pale grey card (#F6F6F4, 8px corners).
class FillCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  const FillCard({super.key, required this.child, this.margin = const EdgeInsets.fromLTRB(kPad, 32, kPad, 0), this.padding = const EdgeInsets.all(16), this.radius = 8, this.color = AppColors.offWhite});

  @override
  Widget build(BuildContext context) => Container(margin: margin, padding: padding, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)), child: child);
}

/// Small 32px outlined text button ("Connect", "Follow", "Restore").
class MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool active; // blue text
  const MiniButton(this.label, {super.key, this.onTap, this.active = true});

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null ? AppColors.gray500 : (active ? AppColors.blue : AppColors.ink);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: onTap == null ? Colors.transparent : kLine)),
        child: Text(label, style: AppTextStyles.label.copyWith(fontSize: 13, color: fg)),
      ),
    );
  }
}

/// Segmented progress bars (resume / profile completion, quiz levels).
class SegBar extends StatelessWidget {
  final int done;
  final int total;
  const SegBar(this.done, this.total, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [for (var i = 0; i < total; i++) Expanded(child: Container(margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4), height: 4, decoration: BoxDecoration(color: i < done ? AppColors.blue : kTrack, borderRadius: BorderRadius.circular(2))))]);
}

/// Row with a 40px mark, title and a subtitle; trailing widget at the end.
class V2Row extends StatelessWidget {
  final Widget mark;
  final String title;
  final String? subtitle;
  final Widget? extra;
  final Widget? trailing;
  final VoidCallback? onTap;
  final CrossAxisAlignment align;
  const V2Row({super.key, required this.mark, required this.title, this.subtitle, this.extra, this.trailing, this.onTap, this.align = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(crossAxisAlignment: align, children: [
        mark,
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(fontSize: 15, height: 1.3)),
            if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))),
            if (extra != null) Padding(padding: const EdgeInsets.only(top: 4), child: extra),
          ]),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ]),
    );
  }
}

/// 40px grey square mark with an initial.
class Mark8 extends StatelessWidget {
  final String text;
  final double size;
  final bool round;
  final bool outlined;
  const Mark8(this.text, {super.key, this.size = 40, this.round = false, this.outlined = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: outlined ? AppColors.white : AppColors.offWhite, borderRadius: round ? null : BorderRadius.circular(8), shape: round ? BoxShape.circle : BoxShape.rectangle, border: outlined ? Border.all(color: kLine) : null),
        child: Text(text, style: AppTextStyles.bodyLg.copyWith(fontSize: size >= 44 ? 14 : 14)),
      );
}

/// "₹17–25k/mo · 75% match" with the pay in 600 ink and the tag in coloured text.
class PayLine extends StatelessWidget {
  final String pay;
  final String? tag;
  final Color tagColor;
  const PayLine({super.key, required this.pay, this.tag, this.tagColor = AppColors.blue});

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: pay, style: const TextStyle(fontWeight: AppFontWeight.number, color: AppColors.ink)),
          if (tag != null) ...[const TextSpan(text: ' · ', style: TextStyle(color: AppColors.body)), TextSpan(text: tag, style: TextStyle(color: tagColor, fontWeight: AppFontWeight.medium))],
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, fontFeatures: const [FontFeature.tabularFigures()]),
      );
}

/// Compact top bar of an inner screen: back chevron, title, optional trailing icons.
class V2Bar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget> actions;
  final IconData leading;
  const V2Bar({super.key, required this.title, required this.onBack, this.actions = const [], this.leading = Icons.chevron_left});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            GestureDetector(onTap: onBack, behavior: HitTestBehavior.opaque, child: SizedBox(width: 40, height: 40, child: Icon(leading, size: 24, color: AppColors.ink))),
            const SizedBox(width: 4),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h2.copyWith(fontSize: 17, letterSpacing: -0.17))),
            ...actions,
          ]),
        ),
      );
}

class BarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool dot;
  const BarIcon(this.icon, {super.key, this.onTap, this.color = AppColors.body, this.dot = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [Icon(icon, size: 20, color: color), if (dot) const Positioned(top: 10, right: 11, child: CircleAvatar(radius: 3, backgroundColor: AppColors.error))])),
      );
}
