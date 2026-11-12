import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/ats.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../state/network_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/v2.dart';
import '../../ui/components/components.dart';
import '../../ui/page_shell.dart';
import '../../ui/tokens.dart';
import '../../widgets/job_row.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/pill_button.dart';

/// Opportunity detail. Phone: one column with a pinned Apply bar. Wide: the role on the left and a
/// rail on the right (deadline, Apply, Save / Message, resume fit, recruiter).
class OpportunityDetailScreen extends StatefulWidget {
  final String id;
  const OpportunityDetailScreen({super.key, required this.id});

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  Opportunity? _o;
  List<Opportunity> _similar = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<Repositories>().opportunities;
    final opp = repo.getOpportunityById(widget.id);
    if (opp == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final same = await repo.listOpportunities(categories: [opp.category]);
    if (!mounted) return;
    setState(() {
      _o = opp;
      _similar = same.where((o) => o.id != opp.id).take(3).toList();
      _loading = false;
    });
  }

  bool get _applied => _o != null && context.read<Repositories>().applications.isOpportunityApplied(_o!.id);

  void _apply() {
    final o = _o;
    if (o == null || _applied) return;
    startApplyFlow(context, o, onApplied: () => setState(() {}));
  }

  void _openCompany(String name) {
    final store = context.read<NetworkStore>();
    for (final c in store.companies) {
      if (c.name.toLowerCase() == name.toLowerCase()) {
        context.push('/company/${c.id}');
        return;
      }
    }
  }

  void _message() {
    final store = context.read<NetworkStore>();
    final recruiter = store.people.firstWhere((p) => p.recruiter && p.link == LinkState.connected, orElse: () => store.people.first);
    final id = store.openChat(recruiter.id);
    context.push('/messages/$id');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.white, body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    final o = _o;
    if (o == null) return const NotFoundView(title: 'Opportunity not found', message: 'This opportunity may have been removed, or the link you followed is out of date.');

    final app = context.watch<AppState>();
    final user = app.user;
    final wide = AppBreakpoints.isWide(context);
    final saved = app.isOpportunitySaved(o.id);

    final back = GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go('/tabs'),
      behavior: HitTestBehavior.opaque,
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Ionicons.chevron_back, size: wide ? 14 : 20, color: AppColors.ink), if (wide) ...[const SizedBox(width: 6), Text('Back to results', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))]]),
    );

    final main = _Main(o: o, user: user, similar: _similar, wide: wide, applied: _applied);

    if (!wide) {
      // Minimal v2 phone layout.
      final dl = _applied ? null : o.deadlineLabel;
      final match = _applied ? null : o.matchLabelFor(user);
      final skills = o.requirements.where((r) => !r.startsWith('Experience')).toList();
      final have = skills.where((s) => (user?.resume?.skills ?? const <String>[]).any((k) => s.toLowerCase().contains(k.toLowerCase()))).length;
      Widget stat(String k, String v) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)), const SizedBox(height: 2), Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg)]));
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            V2Bar(title: '', onBack: () => context.canPop() ? context.pop() : context.go('/tabs'), leading: Ionicons.chevron_back, actions: [const BarIcon(Ionicons.share_outline), BarIcon(saved ? Ionicons.bookmark : Ionicons.bookmark_outline, color: saved ? AppColors.blue : AppColors.body, onTap: () => app.toggleSavedOpportunity(o.id))]),
            Expanded(
              child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(kPad, 4, kPad, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Mark8(o.company.isEmpty ? '?' : o.company[0], size: 48),
                    const SizedBox(height: 12),
                    Text(o.title, style: AppTextStyles.h1.copyWith(fontSize: 22, letterSpacing: -0.66)),
                    const SizedBox(height: 4),
                    GestureDetector(onTap: () => _openCompany(o.company), child: Text('${o.company} · ${shortCity(o)}${dl == null ? '' : ' · $dl'}', style: AppTextStyles.body.copyWith(color: AppColors.gray500))),
                  ]),
                ),
                FillCard(
                  margin: const EdgeInsets.fromLTRB(kPad, 20, kPad, 0),
                  radius: 10,
                  child: Row(children: [stat(o.type == 'Internship' ? 'Stipend' : 'Salary', shortPay(o)), const SizedBox(width: 12), stat('Duration', o.duration.isEmpty ? '—' : o.duration), const SizedBox(width: 12), stat('Mode', o.workMode)]),
                ),
                if (match != null)
                  Padding(padding: const EdgeInsets.fromLTRB(kPad, 16, kPad, 0), child: Row(children: [Text(match, style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue)), const SizedBox(width: 10), Expanded(child: Text(skills.isEmpty ? '' : '$have of ${skills.length} skills on your profile', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)))])),
                const V2Section('About the role', top: 28),
                Padding(padding: const EdgeInsets.fromLTRB(kPad, 10, kPad, 0), child: Text(o.about, style: AppTextStyles.body.copyWith(color: AppColors.body, height: 1.55))),
                if (skills.isNotEmpty) ...[
                  const V2Section('Skills', top: 28),
                  Padding(padding: const EdgeInsets.fromLTRB(kPad, 12, kPad, 0), child: Wrap(spacing: 8, runSpacing: 8, children: [for (final s in skills) _Tag(s)])),
                ],
                _FitBlock(o: o, user: user, top: 28),
              ]),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(kPad, 12, kPad, 12 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: kHair))),
              child: Row(children: [
                GestureDetector(onTap: _message, child: Container(width: 48, height: 48, decoration: BoxDecoration(border: Border.all(color: kLine), borderRadius: BorderRadius.circular(6)), child: const Icon(Ionicons.chatbubble_outline, size: 20, color: AppColors.ink))),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(onTap: _applied ? null : _apply, child: Container(height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: _applied ? AppColors.offWhite : AppColors.yellow, borderRadius: BorderRadius.circular(6)), child: Text(_applied ? 'Applied' : 'Apply now', style: AppTextStyles.bodyLg.copyWith(color: _applied ? AppColors.gray500 : AppColors.ink))))),
              ]),
            ),
          ]),
        ),
      );
    }

    // Desktop (B4 detail): inner-screen header, identity block, content sections; a 320px action
    // card on the right with the key facts and the single yellow action.
    final dl = _applied ? null : o.deadlineLabel;
    final match = _applied ? null : o.matchLabelFor(user);
    final skills = o.requirements.where((r) => !r.startsWith('Experience')).toList();
    Widget fact(String k, String v) => Padding(
          padding: const EdgeInsets.only(bottom: Ui.s12),
          child: Row(children: [SizedBox(width: 96, child: Text(k, style: Ui.meta)), Expanded(child: Text(v, style: Ui.rowTitle.copyWith(fontWeight: FontWeight.w500)))]),
        );
    final (pay, unit) = splitPay(o);
    final action = UiCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        fact(o.type == 'Internship' ? 'Stipend' : 'Salary', '$pay$unit'),
        fact('Duration', o.duration.isEmpty ? '—' : o.duration),
        fact('Work mode', o.workMode),
        fact('Department', o.department.isEmpty ? o.category : o.department),
        if (dl != null) fact('Closes in', dl.replaceAll(' left', '')),
        if (o.applicantCount > 0) fact('Applicants', '${o.applicantCount}'),
        const SizedBox(height: Ui.s8),
        UiButton(_applied ? 'Applied' : 'Apply Now', kind: UiButtonKind.primary, expand: true, onTap: _applied ? null : _apply),
        const SizedBox(height: Ui.s8),
        Row(children: [
          Expanded(child: UiButton(saved ? 'Saved' : 'Save', expand: true, icon: saved ? Ionicons.bookmark : Ionicons.bookmark_outline, onTap: () => app.toggleSavedOpportunity(o.id))),
          const SizedBox(width: Ui.s8),
          Expanded(child: UiButton('Message', expand: true, icon: Ionicons.chatbubble_outline, onTap: _message)),
        ]),
        const SizedBox(height: Ui.s20),
        _FitBlock(o: o, user: user, top: 0),
      ]),
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageShell(
        rail: action,
        railWidth: Ui.actionCard,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(title: o.title, onBack: () => context.canPop() ? context.pop() : context.go('/tabs')),
          Row(children: [
            Avatar(o.company.isEmpty ? '?' : o.company[0], size: 56),
            const SizedBox(width: Ui.s16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(onTap: () => _openCompany(o.company), child: MouseRegion(cursor: SystemMouseCursors.click, child: Text('${o.company}${o.sector.isEmpty ? '' : ' · ${o.sector}'} · ${o.location}', style: Ui.meta.copyWith(fontSize: 14)))),
                if (match != null) Padding(padding: const EdgeInsets.only(top: Ui.s4), child: Text(match, style: Ui.link)),
              ]),
            ),
          ]),
          const SectionHeader('About the role'),
          Text(o.about, style: Ui.body.copyWith(color: Ui.secondary)),
          if (skills.isNotEmpty) ...[
            const SectionHeader('Skills'),
            Wrap(spacing: Ui.s8, runSpacing: Ui.s8, children: [for (final s in skills) _Tag(s)]),
          ],
          if (_similar.isNotEmpty) ...[
            const SectionHeader('Similar roles'),
            for (final s in _similar)
              Padding(padding: const EdgeInsets.only(bottom: Ui.betweenRows), child: ListRow(mark: s.company[0], title: s.title, meta: '${s.company} · ${shortCity(s)}', onTap: () => context.push('/opportunity/${s.id}'))),
          ],
        ]),
      ),
    );
  }
}

class _Main extends StatelessWidget {
  final Opportunity o;
  final User? user;
  final List<Opportunity> similar;
  final bool wide;
  final bool applied;
  const _Main({required this.o, required this.user, required this.similar, required this.wide, required this.applied});

  @override
  Widget build(BuildContext context) {
    final (pay, unit) = splitPay(o);
    final match = applied ? null : o.matchLabelFor(user);
    Widget fact(String k, Widget v, {bool first = false}) => Expanded(
          child: Container(
            padding: EdgeInsets.fromLTRB(first ? 0 : 16, 16, 16, 16),
            decoration: BoxDecoration(border: first ? null : const Border(left: BorderSide(color: kLine))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)), const SizedBox(height: 2), v]),
          ),
        );
    TextStyle big() => AppTextStyles.h2.copyWith(fontSize: wide ? 20 : 17, letterSpacing: -0.4);

    final payText = Text.rich(TextSpan(children: [TextSpan(text: pay, style: big().copyWith(fontWeight: AppFontWeight.number)), if (unit.isNotEmpty) TextSpan(text: ' $unit', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))]), maxLines: 2);
    final facts = wide
        ? Container(
            decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: kLine))),
            child: Row(children: [
              fact('Pay', payText, first: true),
              fact('Duration', Text(o.duration.isEmpty ? '—' : o.duration, style: big())),
              fact('Department', Text(o.department.isEmpty ? o.category : o.department, style: big(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              fact('Work mode', Text(o.workMode, style: big())),
            ]),
          )
        : Container(
            decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: kLine))),
            child: Column(children: [
              Row(children: [fact('Pay', payText, first: true), fact('Duration', Text(o.duration.isEmpty ? '—' : o.duration, style: big()))]),
              const Hairline(),
              Row(children: [fact('Department', Text(o.department.isEmpty ? o.category : o.department, style: big(), maxLines: 1, overflow: TextOverflow.ellipsis), first: true), fact('Work mode', Text(o.workMode, style: big()))]),
            ]),
          );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MarkTile(o.company.isEmpty ? '?' : o.company[0], size: wide ? 56 : 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.title, style: wide ? AppTextStyles.display : AppTextStyles.h1.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text('${o.company}${o.sector.isEmpty ? '' : ' · ${o.sector}'} · ${o.location}', style: AppTextStyles.body.copyWith(color: AppColors.body)),
            const SizedBox(height: 10),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              if (match != null) SignalChip(match),
              if (o.applicantCount > 0) Text('${o.applicantCount} applicants', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
            ]),
          ]),
        ),
      ]),
      const SizedBox(height: 24),
      facts,
      const SizedBox(height: 24),
      Text('About the role', style: AppTextStyles.h3),
      const SizedBox(height: 6),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: Text(o.about, style: AppTextStyles.body.copyWith(color: AppColors.body, height: 1.5))),
      if (o.requirements.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Skills', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final r in o.requirements.where((r) => !r.startsWith('Experience'))) _Tag(r)]),
      ],
      if (similar.isNotEmpty) ...[
        SectionHeading('Similar roles', count: similar.length, padding: const EdgeInsets.only(top: 32, bottom: 4)),
        const Hairline(),
        for (final s in similar)
          HairlineRow(
            minHeight: 56,
            onTap: () => context.push('/opportunity/${s.id}'),
            child: Row(children: [
              MarkTile(s.company[0], size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text.rich(TextSpan(text: s.title, style: AppTextStyles.bodyLg, children: [TextSpan(text: ' · ${s.company}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))]), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (wide) Text(shortCity(s), style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body)),
              const SizedBox(width: 12),
              const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray500),
            ]),
          ),
      ],
    ]);
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: AppTextStyles.label.copyWith(color: AppColors.body)),
      );
}

/// "Your resume vs this role": ATS fit and the keywords the resume is missing.
class _FitBlock extends StatelessWidget {
  final Opportunity o;
  final User? user;
  final double top;
  const _FitBlock({required this.o, required this.user, this.top = 24});

  @override
  Widget build(BuildContext context) {
    final has = user?.resume != null;
    final fit = o.atsFitFor(user);
    final missing = o.missingKeywordsFor(user);
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text('Your resume vs this role', style: AppTextStyles.h3)),
          if (has) Text('$fit', style: AppTextStyles.h2.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
        if (has) ...[const SizedBox(height: 10), ScoreBar(fit / 100)],
        const SizedBox(height: 8),
        Text(has ? (missing.isEmpty ? 'ATS fit. Your resume covers what this role asks for.' : 'ATS fit. Missing keywords: ${missing.join(', ')}.') : 'Build a resume to see how well you fit this role.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, height: 1.45)),
        LinkText(has ? 'Improve resume' : 'Build resume', onTap: () => context.push('/college/resume')),
      ]),
    );
  }
}

class _RecruiterRow extends StatelessWidget {
  final VoidCallback onMessage;
  final double top;
  const _RecruiterRow({required this.onMessage, this.top = 0});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final p = store.people.firstWhere((p) => p.recruiter && p.link == LinkState.connected, orElse: () => store.people.first);
    return Container(
      padding: EdgeInsets.only(top: top),
      decoration: top == 0 ? const BoxDecoration(border: Border(top: BorderSide(color: kLine))) : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (top == 0) const SizedBox(height: 16),
        Text('Recruiter', style: AppTextStyles.h3),
        SizedBox(
          height: 64,
          child: Row(children: [
            MarkTile(p.initials, size: 36, round: true),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: AppTextStyles.bodyLg), Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
            p.link == LinkState.connected ? LinkText('Message', onTap: onMessage) : LinkText('Connect', onTap: () => store.connect(p.id)),
          ]),
        ),
      ]),
    );
  }
}
