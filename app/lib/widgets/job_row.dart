import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../models/opportunity.dart';
import '../models/opportunity_match.dart';
import '../models/user.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'ds.dart';
import 'v2.dart';
import '../ui/tokens.dart';

/// "₹17,000–₹25,000/month" -> ("₹17,000–₹25,000", "/mo"). Pay is the one number allowed 600 weight.
(String, String) splitPay(Opportunity o) {
  final raw = (o.type == 'Internship' ? (o.internStipend ?? o.stipend) : (o.salaryRange.isNotEmpty ? o.salaryRange : o.stipend)).trim();
  final i = raw.indexOf('/');
  if (i < 0) return (raw, '');
  final unit = raw.substring(i).toLowerCase().replaceAll('month', 'mo');
  return (raw.substring(0, i), unit);
}

String shortCity(Opportunity o) => o.location.split(RegExp(r'[,·(]')).first.trim();

/// One opportunity. Phone (Minimal v2): no divider, 40px mark, title, "company · city" and a pay
/// line whose tag is coloured text (match blue, urgent amber, applied grey). Wide: a table row
/// with Role / Location / Pay / Match / Deadline columns.
class JobRow extends StatelessWidget {
  final Opportunity job;
  final User? user;
  final bool saved;
  final bool applied;
  final bool wide;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;

  const JobRow({super.key, required this.job, required this.user, required this.saved, this.applied = false, this.wide = false, required this.onTap, required this.onToggleSave});

  @override
  Widget build(BuildContext context) {
    final (pay, unit) = splitPay(job);
    final match = job.matchLabelFor(user);
    final urgent = job.deadlineIsUrgent;
    final deadline = job.deadlineLabel;

    final bookmark = GestureDetector(
      onTap: onToggleSave,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 32, height: 32, child: Icon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 18, color: saved ? AppColors.blue : AppColors.gray500)),
    );

    if (wide) {
      return HairlineRow(
        onTap: onTap,
        minHeight: 64,
        child: Row(children: [
          Expanded(
            child: Row(children: [
              MarkTile(job.company.isEmpty ? '?' : job.company[0]),
              const SizedBox(width: 12),
              Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg), Text(job.company, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
            ]),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(shortCity(job), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body))),
          const SizedBox(width: 12),
          SizedBox(width: 140, child: Text.rich(TextSpan(children: [TextSpan(text: pay, style: const TextStyle(fontWeight: AppFontWeight.number)), TextSpan(text: unit, style: const TextStyle(fontWeight: AppFontWeight.regular, color: AppColors.gray500))]), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()]))),
          const SizedBox(width: 12),
          SizedBox(width: 84, child: Align(alignment: Alignment.centerLeft, child: match == null ? const SizedBox() : SignalChip(match))),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: applied
                  ? const SignalChip('Applied', kind: SignalKind.grey)
                  : (deadline == null ? const SizedBox() : (urgent ? SignalChip(deadline, kind: SignalKind.amber) : Text(deadline, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)))),
            ),
          ),
          const SizedBox(width: 12),
          bookmark,
        ]),
      );
    }

    final showUrgent = urgent && deadline != null;
    final tag = applied ? 'Applied' : (showUrgent ? deadline : match);
    final tagColor = applied ? AppColors.gray500 : (showUrgent ? AppColors.warningDark : AppColors.blue);
    return V2Row(
      onTap: onTap,
      mark: Mark8(job.company.isEmpty ? '?' : job.company[0]),
      title: job.title,
      subtitle: '${job.company} · ${shortCity(job)}',
      extra: PayLine(pay: shortPay(job), tag: tag, tagColor: tagColor),
      trailing: GestureDetector(
        onTap: onToggleSave,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(width: 28, height: 40, child: Icon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 18, color: saved ? AppColors.blue : AppColors.gray500)),
      ),
    );
  }
}

/// Column header for the wide table.
class JobTableHeader extends StatelessWidget {
  const JobTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppTextStyles.label.copyWith(fontSize: 11, letterSpacing: 0.15, color: AppColors.gray500);
    return Container(
      height: 32,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
      child: Row(children: [
        Expanded(child: Text('Role', style: s)),
        const SizedBox(width: 12),
        SizedBox(width: 100, child: Text('Location', style: s)),
        const SizedBox(width: 12),
        SizedBox(width: 140, child: Text('Pay', style: s)),
        const SizedBox(width: 12),
        SizedBox(width: 84, child: Text('Match', style: s)),
        const SizedBox(width: 12),
        SizedBox(width: 96, child: Text('Deadline', style: s)),
        const SizedBox(width: 12),
        const SizedBox(width: 32),
      ]),
    );
  }
}

/// Web card: 1px outline, 10px corners, mark + title + bookmark and the pay line (Minimal v2 web).
class JobCard extends StatelessWidget {
  final Opportunity job;
  final User? user;
  final bool saved;
  final bool applied;
  final VoidCallback onTap;
  final VoidCallback onToggleSave;
  const JobCard({super.key, required this.job, required this.user, required this.saved, this.applied = false, required this.onTap, required this.onToggleSave});

  @override
  Widget build(BuildContext context) {
    final match = job.matchLabelFor(user);
    final urgent = job.deadlineIsUrgent && job.deadlineLabel != null;
    final tag = applied ? 'Applied' : (urgent ? job.deadlineLabel : match);
    final tagColor = applied ? AppColors.gray500 : (urgent ? AppColors.warningDark : AppColors.blue);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(Ui.cardPad),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: kHair)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Mark8(job.company.isEmpty ? '?' : job.company[0]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(fontSize: 15)), const SizedBox(height: 2), Text('${job.company} · ${shortCity(job)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))])),
              GestureDetector(onTap: onToggleSave, behavior: HitTestBehavior.opaque, child: SizedBox(width: 28, height: 28, child: Icon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, size: 18, color: saved ? AppColors.blue : AppColors.gray500))),
            ]),
            const SizedBox(height: 12),
            PayLine(pay: shortPay(job), tag: tag, tagColor: tagColor),
          ]),
        ),
      ),
    );
  }
}
