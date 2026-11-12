import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/ds.dart';
import '../../../theme/breakpoints.dart';
import '../../../ui/components/components.dart';
import '../../../ui/page_shell.dart';
import '../../../ui/tokens.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/v2.dart';

/// Intro to one Career Quiz level: what it measures, how long it takes, what you will find out.
class CareerDnaLevelIntroScreen extends StatelessWidget {
  final int level;
  const CareerDnaLevelIntroScreen({super.key, required this.level});

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (AppBreakpoints.isWide(context)) {
      // Desktop (B7 focused flow with a highlight card): close x, content left, a 360px card with
      // the facts and the one yellow button on the right.
      Widget row(String k, String v) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Expanded(child: Text(k, style: Ui.body.copyWith(color: Ui.secondary, height: 1.2))), Text(v, style: Ui.body.copyWith(fontWeight: FontWeight.w500, height: 1.2))]));
      return Scaffold(
        backgroundColor: AppColors.white,
        body: PageShell(
          rail: Padding(padding: const EdgeInsets.only(top: 92), child: HighlightCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              row('Questions', '${meta.questionCount}'),
              row('Time', meta.estTime),
              row('Answers', 'No wrong'),
              const SizedBox(height: Ui.s8),
              UiButton('Start level ${meta.level}', kind: UiButtonKind.primary, expand: true, onTap: () => context.push('/college/career-dna/level/${meta.level}/quiz')),
            ]),
          )),
          railWidth: 360,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(onTap: () => context.canPop() ? context.pop() : context.go('/tabs/career-dna'), child: const SizedBox(width: 36, height: 36, child: Icon(Ionicons.close, size: 22, color: Ui.ink))),
            const SizedBox(height: Ui.s20),
            Container(width: 64, height: 64, alignment: Alignment.center, decoration: const BoxDecoration(color: Ui.blue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF0722B8), offset: Offset(0, 4))]), child: Text('${meta.level}', style: Ui.innerTitle.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
            const SizedBox(height: Ui.s28),
            Text('Level ${meta.level} of 5', style: Ui.label),
            const SizedBox(height: Ui.s8),
            Text(meta.title, style: Ui.pageTitle.copyWith(fontSize: 36, height: 1.1)),
            const SizedBox(height: Ui.s8),
            Text(meta.tagline, style: Ui.body.copyWith(fontSize: 16, color: const Color(0xFF3F3F46))),
            const SizedBox(height: Ui.s24),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: Text(meta.whatThisMeasures, style: Ui.body.copyWith(color: const Color(0xFF3F3F46)))),
            const SectionHeader('What you’ll find out'),
            for (final p in const ['Your core strengths on this measure', 'How you work with others', 'Roles that suit your natural style'])
              Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [const Icon(Ionicons.checkmark, size: 16, color: Ui.blue), const SizedBox(width: Ui.s12), Text(p, style: Ui.body.copyWith(height: 1.2))])),
          ]),
        ),
      );
    }
    Widget stat(String k, String v) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)), const SizedBox(height: 2), Text(v, style: AppTextStyles.bodyLg)]));
    Widget point(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Ionicons.checkmark, size: 16, color: AppColors.blue)), const SizedBox(width: 12), Expanded(child: Text(t, style: AppTextStyles.body.copyWith(color: AppColors.body, height: 1.4)))]));
    final points = [
      'Your core strengths on this measure',
      'How you work with others',
      'Roles that suit your natural style',
    ];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(children: [
              V2Bar(title: '', onBack: () => context.canPop() ? context.pop() : context.go('/tabs/career-dna'), leading: Ionicons.close),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(kPad, 8, kPad, 24), children: [
                  Align(alignment: Alignment.centerLeft, child: Container(width: 56, height: 56, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle), child: Text('${meta.level}', style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: AppFontWeight.number)))),
                  const SizedBox(height: 16),
                  Text('Level ${meta.level} of 5', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
                  const SizedBox(height: 4),
                  Text(meta.title, style: AppTextStyles.h1.copyWith(fontSize: 28, letterSpacing: -1.12)),
                  const SizedBox(height: 6),
                  Text(meta.tagline, style: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.body)),
                  FillCard(margin: const EdgeInsets.only(top: 24), radius: 10, child: Row(children: [stat('Questions', '${meta.questionCount}'), stat('Time', meta.estTime), stat('Answers', 'No wrong')])),
                  const SizedBox(height: 28),
                  Text('What you’ll find out', style: AppTextStyles.h3),
                  const SizedBox(height: 14),
                  for (final p in points) point(p),
                  const SizedBox(height: 4),
                  Text(meta.whatThisMeasures, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500, height: 1.5)),
                ]),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(kPad, 12, kPad, 12 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: kHair))),
                child: PillButton(label: 'Start level ${meta.level}', onPressed: () => context.push('/college/career-dna/level/${meta.level}/quiz')),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
