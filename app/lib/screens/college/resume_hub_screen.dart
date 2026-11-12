import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../models/ats.dart';
import '../../models/parsed_resume.dart';
import '../../models/user.dart';
import '../../nav.dart';
import '../../services/resume_pdf.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/pill_button.dart';

/// Resume hub: ATS score and what to fix, three templates, a live preview, then the actions
/// (improve with the AI chat, download, upload a PDF). The chat builder is the main way to build.
class ResumeHubScreen extends StatefulWidget {
  const ResumeHubScreen({super.key});

  @override
  State<ResumeHubScreen> createState() => _ResumeHubScreenState();
}

class _ResumeHubScreenState extends State<ResumeHubScreen> {
  int _template = 0;
  bool _downloading = false;

  Future<void> _download(User user) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await buildResumePdf(user);
      final name = (user.resume?.name.isNotEmpty ?? false) ? user.resume!.name : (user.name ?? 'resume');
      await Printing.sharePdf(bytes: bytes, filename: '${name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_')}_resume.pdf');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't generate the PDF")));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _chat() => context.push(resumeBuildLocation());

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) return const SizedBox.shrink();
    final wide = AppBreakpoints.isWide(context);
    final has = user.resume != null;
    final score = user.atsScore;
    final fixes = user.atsFixes;

    final scoreBlock = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Expanded(child: Text('ATS score', style: AppTextStyles.h3)),
        Text.rich(TextSpan(text: has ? '$score' : '–', children: [TextSpan(text: ' / 100', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500, letterSpacing: 0))]), style: AppTextStyles.h1.copyWith(fontSize: 28, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      const SizedBox(height: 10),
      ScoreBar(has ? score / 100 : 0),
      const SizedBox(height: 8),
      Text(!has ? 'Build your resume to get a score.' : (fixes.every((f) => f.done) ? 'Looking strong for ATS filters.' : '${score >= 75 ? 'Good' : 'Needs work'}. ${fixes.where((f) => !f.done).length} fixes to reach ${user.atsPotential}.'), style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
    ]);

    final fixList = Column(children: [
      for (var i = 0; i < fixes.length; i++)
        Container(
          height: 44,
          decoration: BoxDecoration(border: i == fixes.length - 1 ? null : const Border(bottom: BorderSide(color: kLine))),
          child: Row(children: [
            Expanded(child: Text(fixes[i].title, style: AppTextStyles.body.copyWith(fontSize: 13, color: fixes[i].done ? AppColors.gray500 : AppColors.ink))),
            if (fixes[i].done)
              Row(children: [const Icon(Ionicons.checkmark, size: 14, color: AppColors.gray500), const SizedBox(width: 4), Text('Done', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])
            else ...[
              Text('+${fixes[i].points}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 12),
              LinkText('Fix', onTap: _chat),
            ],
          ]),
        ),
    ]);

    final templates = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Template', style: AppTextStyles.h3),
      const SizedBox(height: 10),
      Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _template = i),
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    height: 64,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: _template == i ? AppColors.blue : kLine, width: _template == i ? 2 : 1)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(height: 5, width: 28, decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(2))),
                      for (final w in const [0.9, 0.8, 0.7]) Padding(padding: const EdgeInsets.only(top: 5), child: FractionallySizedBox(widthFactor: w, child: Container(height: 3, decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(2))))),
                    ]),
                  ),
                  const SizedBox(height: 5),
                  Text(const ['Clean', 'Compact', 'Modern'][i], style: AppTextStyles.label.copyWith(fontSize: 11, color: _template == i ? AppColors.blue : AppColors.ink)),
                ]),
              ),
            ),
          ),
      ]),
    ]);

    final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PillButton(label: has ? 'Improve with AI chat' : 'Build with AI chat', icon: Ionicons.flash_outline, onPressed: _chat),
      if (has) ...[
        const SizedBox(height: 8),
        PillButton(label: 'Download PDF', variant: PillVariant.secondary, icon: Ionicons.download_outline, loading: _downloading, onPressed: () => _download(user)),
      ],
      const SizedBox(height: 8),
      PillButton(label: 'Upload a PDF', variant: PillVariant.secondary, icon: Ionicons.cloud_upload_outline, onPressed: () => context.push('/college/resume/import')),
    ]);

    final preview = _Preview(user: user, template: _template);

    final back = GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go('/tabs/profile'),
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.chevron_back, size: 16, color: AppColors.gray500), const SizedBox(width: 6), Text('Profile', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))]),
    );

    if (!wide) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/tabs/profile'), icon: const Icon(Ionicons.chevron_back, size: 20, color: AppColors.ink)), Expanded(child: Center(child: Text('Resume', style: AppTextStyles.bodyLg))), const SizedBox(width: 48)]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: [
                scoreBlock,
                const SizedBox(height: 8),
                if (has) ...[const Hairline(), fixList, const Hairline()],
                const SizedBox(height: 20),
                templates,
                const SizedBox(height: 20),
                if (has) Center(child: preview),
              ]),
            ),
            Container(padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom), decoration: const BoxDecoration(border: Border(top: BorderSide(color: kLine))), child: actions),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: WebAlign(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200 + 48),
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 24), children: [
            Padding(padding: const EdgeInsets.fromLTRB(0, 24, 0, 16), child: Align(alignment: Alignment.centerLeft, child: back)),
            const Hairline(),
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 40),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Resume', style: AppTextStyles.display), const SizedBox(height: 6), Text(has ? 'Pick a template, then keep improving it with the AI chat.' : 'Answer a few questions in chat and your resume writes itself.', style: AppTextStyles.body.copyWith(color: AppColors.body)), const SizedBox(height: 24), Center(child: preview)])),
                const SizedBox(width: 32),
                Container(
                  width: 320,
                  padding: const EdgeInsets.only(left: 32),
                  decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    scoreBlock,
                    const SizedBox(height: 12),
                    if (has) ...[const Hairline(), fixList, const Hairline()],
                    const SizedBox(height: 20),
                    templates,
                    const SizedBox(height: 20),
                    actions,
                  ]),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A4-proportioned live preview of the saved resume. Template changes the heading treatment.
class _Preview extends StatelessWidget {
  final User user;
  final int template;
  const _Preview({required this.user, required this.template});

  @override
  Widget build(BuildContext context) {
    final r = user.resume;
    final base = AppTextStyles.body.copyWith(fontSize: 9, height: 1.5, color: AppColors.body);
    Widget section(String t, List<Widget> kids) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.only(bottom: 3),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(border: template == 2 ? null : const Border(bottom: BorderSide(color: kLine))),
              width: double.infinity,
              child: Text(template == 2 ? t.toUpperCase() : t, style: base.copyWith(color: template == 2 ? AppColors.blue : AppColors.ink, fontWeight: AppFontWeight.medium, letterSpacing: template == 2 ? 1 : 0)),
            ),
            ...kids,
          ]),
        );
    return Container(
      width: 408,
      constraints: const BoxConstraints(minHeight: 560),
      padding: EdgeInsets.symmetric(horizontal: template == 1 ? 24 : 30, vertical: template == 1 ? 22 : 28),
      decoration: BoxDecoration(border: Border.all(color: kLine), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: r == null
          ? SizedBox(height: 500, child: Center(child: Text('Your resume appears here as you answer the chat.', textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.gray500))))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name.isEmpty ? (user.name ?? '') : r.name, style: AppTextStyles.h2.copyWith(fontSize: template == 1 ? 15 : 18)),
              Text([if ((user.city ?? '').isNotEmpty) user.city!, if ((r.phone ?? '').isNotEmpty) r.phone!, user.identifier].join(' · '), style: base.copyWith(color: AppColors.gray500)),
              if ((r.summary ?? '').isNotEmpty) section('Summary', [Text(r.summary!, style: base)]),
              if (r.education.isNotEmpty) section('Education', [for (final e in r.education) Row(children: [Expanded(child: Text('${e.degree}, ${e.institution}', style: base.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium))), Text(e.duration, style: base)])]),
              if (r.workExperience.isNotEmpty) section('Experience', [for (final w in r.workExperience) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('${w.role}, ${w.company}', style: base.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium))), Text(w.duration, style: base)]), if (w.description.isNotEmpty) Text(w.description, style: base)])]),
              if (r.projects.isNotEmpty) section('Projects', [for (final p in r.projects) Text('• ${p.title}', style: base)]),
              if (r.skills.isNotEmpty) section('Skills', [Text(r.skills.join(' · '), style: base)]),
            ]),
    );
  }
}

// Silences an unused-import lint if ParsedResume is only referenced through User.
// ignore: unused_element
typedef _R = ParsedResume;
