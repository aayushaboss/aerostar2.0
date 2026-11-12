import 'package:flutter/material.dart';
import '../../../widgets/web_align.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../models/career_dna.dart';
import '../../../models/user.dart';
import '../../../state/app_state.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/scroll_to_top_registry.dart';
import '../../../widgets/ds.dart';
import '../../../widgets/v2.dart';
import '../../../ui/components/components.dart';
import '../../../ui/page_shell.dart';
import '../../../ui/tokens.dart';
import '../../../widgets/pill_button.dart';

/// Career Quiz tab: five sequential levels. Shows what is up next, then every level as a row
/// (done, current, locked). Completed levels open their report.
class CareerDnaLandingScreen extends StatefulWidget {
  const CareerDnaLandingScreen({super.key});

  @override
  State<CareerDnaLandingScreen> createState() => _CareerDnaLandingScreenState();
}

class _CareerDnaLandingScreenState extends State<CareerDnaLandingScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ScrollToTopRegistry.register(5, () {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(5);
    _scroll.dispose();
    super.dispose();
  }

  bool _complete(CareerDnaProfile p, int level) => switch (level) {
        1 => p.level1 != null,
        2 => p.level2 != null,
        3 => p.level3 != null,
        4 => p.level4 != null,
        5 => p.level5 != null,
        _ => false,
      };

  void _open(int level, bool unlocked, bool completed) {
    HapticFeedback.selectionClick();
    if (!unlocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Finish the previous level to unlock this one.')));
      return;
    }
    if (completed && level == 5) {
      context.push('/college/career-dna/final-report');
      return;
    }
    context.push(completed ? '/college/career-dna/level/$level/report' : '/college/career-dna/level/$level/intro');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final profile = user?.careerDnaOrEmpty ?? const CareerDnaProfile();
    final wide = AppBreakpoints.isWide(context);
    final expanded = AppBreakpoints.isExpanded(context);
    final doneCount = [for (final m in careerDnaLevelMeta) if (_complete(profile, m.level)) 1].length;
    CareerDnaLevelMeta? next;
    for (final m in careerDnaLevelMeta) {
      if (!_complete(profile, m.level) && (user?.isCareerDnaLevelUnlocked(m.level) ?? m.level == 1)) {
        next = m;
        break;
      }
    }

    if (!wide) return _compactMap(user, profile, next, doneCount);
    return _webMap(user, profile, next, doneCount);
    final progress = SizedBox(
      width: wide ? 260 : double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('Progress', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))), Text('$doneCount/5 levels', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.ink, fontFeatures: const [FontFeature.tabularFigures()]))]),
        const SizedBox(height: 8),
        ScoreBar(doneCount / 5),
      ]),
    );

    final header = Padding(
      padding: EdgeInsets.only(top: wide ? 32 : 8, bottom: 20),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Career Quiz', style: AppTextStyles.display), const SizedBox(height: 6), Text('Approved by 100+ psychologists, researchers and business leaders.', style: AppTextStyles.body.copyWith(color: AppColors.body))])),
              const SizedBox(width: 32),
              progress,
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: 48, child: Align(alignment: Alignment.centerLeft, child: Text('Career Quiz', style: AppTextStyles.h1))),
              Text('Approved by 100+ psychologists, researchers and business leaders.', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body)),
              const SizedBox(height: 16),
              progress,
            ]),
    );

    final upNext = next == null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(children: [
              const Icon(Ionicons.checkmark, size: 18, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(child: Text('All levels complete. Your final report is ready.', style: AppTextStyles.bodyLg)),
              LinkText('View report', onTap: () => context.push('/college/career-dna/final-report')),
            ]),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Up next', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                  const SizedBox(height: 2),
                  Text('Level ${next.level} · ${next.title}', style: AppTextStyles.h2.copyWith(fontSize: wide ? 24 : 18)),
                  const SizedBox(height: 2),
                  Text('${next.tagline} · ${next.questionCount} questions · ${next.estTime}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
                ]),
              ),
              if (wide) ...[const SizedBox(width: 24), PillButton(label: 'Start Level ${next.level}', full: false, onPressed: () => _open(next!.level, true, false))],
            ]),
          );

    final levels = Column(children: [
      for (final m in careerDnaLevelMeta)
        Builder(builder: (context) {
          final unlocked = user?.isCareerDnaLevelUnlocked(m.level) ?? (m.level == 1);
          final done = _complete(profile, m.level);
          final current = next?.level == m.level;
          return HairlineRow(
            minHeight: 64,
            onTap: () => _open(m.level, unlocked, done),
            child: Row(children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: current ? AppColors.blue : AppColors.gray200, width: current ? 1.5 : 1)),
                child: done ? const Icon(Ionicons.checkmark, size: 13, color: AppColors.success) : Text('${m.level}', style: AppTextStyles.label.copyWith(fontSize: 11, color: current ? AppColors.blue : AppColors.gray500)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.title, style: AppTextStyles.bodyLg.copyWith(color: unlocked ? AppColors.ink : AppColors.body)),
                    Text(m.tagline, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                  ]),
                ),
              ),
              if (wide) SizedBox(width: 170, child: Text('${m.questionCount} questions · ${m.estTime}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body))),
              Icon(!unlocked ? Ionicons.lock_closed_outline : Ionicons.chevron_forward, size: 16, color: AppColors.gray500),
            ]),
          );
        }),
    ]);

    final info = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Ionicons.ribbon_outline, size: 18, color: AppColors.gray500),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Free 10-min career test', style: AppTextStyles.h3), const SizedBox(height: 4), Text('Stand out to recruiters with an international-standard assessment, added to your resume.', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, height: 1.45))])),
      ]),
    );

    final main = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Hairline(),
      upNext,
      SectionHeading('All levels', count: 5, padding: const EdgeInsets.only(top: 8, bottom: 8)),
      const Hairline(),
      levels,
      if (!expanded) info,
      if (!wide && next != null) Padding(padding: const EdgeInsets.only(top: 8, bottom: 24), child: PillButton(label: 'Start Level ${next.level}', onPressed: () => _open(next!.level, true, false))),
    ]);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: WebAlign(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200 + 48),
            child: ListView(controller: _scroll, padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 20), children: [
              header,
              if (expanded)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: main),
                  const SizedBox(width: 32),
                  Container(width: 300, padding: const EdgeInsets.only(left: 32), decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))), child: info),
                ])
              else
                main,
            ]),
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final double sx;
  const _PathPainter(this.sx);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(120 * sx, 76)
      ..cubicTo(120 * sx, 130, 240 * sx, 130, 240 * sx, 184)
      ..cubicTo(240 * sx, 238, 140 * sx, 238, 140 * sx, 292)
      ..cubicTo(140 * sx, 346, 250 * sx, 346, 250 * sx, 400)
      ..cubicTo(250 * sx, 454, 150 * sx, 454, 150 * sx, 508);
    final paint = Paint()
      ..color = const Color(0xFFE2E2DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 2), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.sx != sx;
}

extension _QuizCompact on _CareerDnaLandingScreenState {
  /// Minimal v2 phone layout: a winding dotted path with five round level nodes. The next level
  /// carries the one yellow Start button; locked levels are pale with a lock.
  Widget _compactMap(User? user, CareerDnaProfile profile, CareerDnaLevelMeta? next, int doneCount) {
    // (x of node's left edge, top, text on the right?) per level, from the 375px design.
    const spots = [(92.0, 48.0, true), (212.0, 156.0, false), (112.0, 264.0, true), (222.0, 372.0, false), (122.0, 480.0, true)];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(builder: (context, box) {
          final sx = box.maxWidth / 375;
          Widget node(CareerDnaLevelMeta m, (double, double, bool) spot) {
            final unlocked = user?.isCareerDnaLevelUnlocked(m.level) ?? (m.level == 1);
            final done = _complete(profile, m.level);
            final current = next?.level == m.level;
            final x = spot.$1 * sx;
            final y = spot.$2;
            final circle = Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () => _open(m.level, unlocked, done),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: current ? AppColors.blue : (done ? AppColors.success : AppColors.offWhite),
                    border: current || done ? null : Border.all(color: kLine),
                    boxShadow: [BoxShadow(color: current ? const Color(0xFF0722B8) : (done ? const Color(0xFF2E7D32) : kLine), offset: const Offset(0, 4))],
                  ),
                  child: current || done ? (done ? const Icon(Ionicons.checkmark, size: 24, color: AppColors.white) : Text('${m.level}', style: AppTextStyles.h2.copyWith(color: AppColors.white, fontWeight: AppFontWeight.number))) : Icon(m.level == 5 ? Ionicons.ribbon_outline : Ionicons.lock_closed_outline, size: 20, color: AppColors.gray500),
                ),
              ),
            );
            final textLeft = spot.$3;
            final label = Column(crossAxisAlignment: textLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text('Level ${m.level} · ${m.estTime}', style: AppTextStyles.label.copyWith(color: current ? AppColors.gray500 : const Color(0xFF8A8A8A))),
              const SizedBox(height: 2),
              Text(m.level == 5 && !unlocked ? 'Holland RIASEC · your career map' : m.title, textAlign: textLeft ? TextAlign.left : TextAlign.right, style: AppTextStyles.bodyLg.copyWith(fontSize: current ? 15 : 14, color: current ? AppColors.ink : const Color(0xFF5C5C5C), height: 1.3)),
              if (current)
                GestureDetector(
                  onTap: () => _open(m.level, true, false),
                  child: Padding(padding: const EdgeInsets.only(top: 8), child: UnconstrainedBox(child: Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)), child: Text('Start', style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: AppFontWeight.number, color: AppColors.ink))))),
                ),
            ]);
            final text = textLeft ? Positioned(left: x + 72, top: y - 4, width: 180 * sx, child: label) : Positioned(left: x - 16 - 140 * sx, top: y + 4, width: 140 * sx, child: label);
            return Stack(clipBehavior: Clip.none, children: [circle, text]);
          }

          return ListView(padding: const EdgeInsets.only(bottom: 32), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(kPad, 12, kPad, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Career Quiz', style: AppTextStyles.h1.copyWith(fontSize: 28, letterSpacing: -1.12)),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: SegBar(doneCount, 5)), const SizedBox(width: 12), Text('$doneCount of 5', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500, fontFeatures: const [FontFeature.tabularFigures()]))]),
              ]),
            ),
            SizedBox(
              height: 560,
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _PathPainter(sx))),
                for (var i = 0; i < careerDnaLevelMeta.length && i < spots.length; i++) Positioned.fill(child: node(careerDnaLevelMeta[i], spots[i])),
              ]),
            ),
          ]);
        }),
      ),
    );
  }
}

extension _QuizWeb on _CareerDnaLandingScreenState {
  /// Desktop (B9 journey): the path takes the remaining width; a 420px "Up next" highlight card
  /// on the right holds the only yellow button.
  Widget _webMap(User? user, CareerDnaProfile profile, CareerDnaLevelMeta? next, int doneCount) {
    final path = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (var i = 0; i < careerDnaLevelMeta.length; i++)
        Builder(builder: (context) {
          final m = careerDnaLevelMeta[i];
          final unlocked = user?.isCareerDnaLevelUnlocked(m.level) ?? (m.level == 1);
          final done = _complete(profile, m.level);
          final current = next?.level == m.level;
          return Padding(
            padding: EdgeInsets.only(left: (i % 2) * 96.0, bottom: Ui.s32),
            child: GestureDetector(
              onTap: () => _open(m.level, unlocked, done),
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: current ? Ui.blue : (done ? Ui.statusSuccess : Ui.surface), border: current || done ? null : Border.all(color: Ui.inputBorder)),
                    child: done ? const Icon(Ionicons.checkmark, size: 24, color: Colors.white) : (current ? Text('${m.level}', style: Ui.sectionHeading.copyWith(color: Colors.white)) : Icon(m.level == 5 ? Ionicons.ribbon_outline : Ionicons.lock_closed_outline, size: 20, color: Ui.secondary)),
                  ),
                  const SizedBox(width: Ui.s16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Level ${m.level} · ${m.estTime}', style: Ui.label.copyWith(color: Ui.tertiary)),
                    const SizedBox(height: 2),
                    Text(m.title, style: Ui.rowTitle.copyWith(color: unlocked ? Ui.ink : Ui.secondary)),
                  ]),
                ]),
              ),
            ),
          );
        }),
    ]);

    final upNext = HighlightCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(next == null ? 'All levels complete' : 'Up next · Level ${next.level} of 5', style: Ui.label.copyWith(color: Ui.blue)),
        const SizedBox(height: Ui.s8),
        Text(next == null ? 'Your career map is ready' : next.title, style: Ui.innerTitle),
        const SizedBox(height: Ui.s8),
        Text(next == null ? 'See where all five assessments point you.' : next.tagline, style: Ui.meta.copyWith(fontSize: 14)),
        if (next != null) ...[
          const SizedBox(height: Ui.s20),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Questions', style: Ui.label), const SizedBox(height: 2), Text('${next.questionCount}', style: Ui.rowTitle)])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Time', style: Ui.label), const SizedBox(height: 2), Text(next.estTime, style: Ui.rowTitle)])),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Answers', style: Ui.label), const SizedBox(height: 2), const Text('No wrong', style: Ui.rowTitle)])),
          ]),
        ],
        const SizedBox(height: Ui.s24),
        UiButton(next == null ? 'View report' : 'Start level ${next.level}', kind: UiButtonKind.primary, expand: true, onTap: () => next == null ? context.push('/college/career-dna/final-report') : _open(next.level, true, false)),
      ]),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageShell(
        rail: upNext,
        railWidth: 420,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(title: 'Career Quiz', subtitle: 'Five levels. Finish all to unlock your career map.', actions: [Text('$doneCount of 5', style: Ui.meta)]),
          Padding(padding: const EdgeInsets.only(bottom: Ui.s40), child: UiProgress(doneCount / 5, height: 6)),
          path,
        ]),
      ),
    );
  }
}
