import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_notifications.dart';
import '../../models/ats.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../state/network_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/ds.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/job_row.dart';
import '../../widgets/v2.dart';
import '../../ui/components/components.dart';
import '../../ui/page_shell.dart';
import '../../ui/tokens.dart';
import '../shared/notifications_screen.dart' show openNotifications;

/// Home: search, a type filter, then internships and jobs as hairline rows. On a wide window the
/// list is a table with a right rail (resume score, people you may know, saved, expert help).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Opportunity> _all = [];
  bool _loading = true;
  String _type = 'All';
  int _seenVersion = -1;
  String _filterSig = '';
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ScrollToTopRegistry.register(0, () {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(0);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    final prefs = user?.preferences;
    final results = await context.read<Repositories>().opportunities.listOpportunities(
      workMode: prefs?.workMode,
      employmentType: prefs?.employmentType,
      locations: (prefs?.cities.isEmpty ?? true) ? null : prefs!.cities,
    );
    final scores = {for (final o in results) o.id: o.matchScoreFor(user)};
    results.sort((a, b) => scores[b.id]!.compareTo(scores[a.id]!));
    if (!mounted) return;
    setState(() {
      _all = results;
      _loading = false;
      if (_type == 'All') {
        final g = user?.goal;
        if (g == 'internship') _type = 'Internship';
        if (g == 'job') _type = 'Full-time';
      }
    });
  }

  static String _first(String? name) {
    final n = (name ?? '').trim();
    return n.isEmpty ? 'there' : n.split(RegExp(r'\s+')).first;
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
  }

  Widget _row(Opportunity o, AppState app, User? user, {required bool wide}) {
    final repos = context.read<Repositories>();
    return JobRow(
      job: o,
      user: user,
      wide: wide,
      saved: app.isOpportunitySaved(o.id),
      applied: repos.applications.isOpportunityApplied(o.id),
      onToggleSave: () => app.toggleSavedOpportunity(o.id),
      onTap: () => context.push('/opportunity/${o.id}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final sig = '${user?.goal}|${user?.preferences?.workMode}|${user?.preferences?.employmentType}|${(user?.preferences?.cities ?? const <String>[]).join(',')}|${(user?.roles ?? const <String>[]).join(',')}';
    if (app.dataVersion != _seenVersion || sig != _filterSig) {
      _seenVersion = app.dataVersion;
      _filterSig = sig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final wide = AppBreakpoints.isWide(context);
    final expanded = AppBreakpoints.isExpanded(context);
    final unread = app.hasUnreadNotifications(mockNotifications.map((n) => n.id).toList());
    final messages = context.watch<NetworkStore>().hasUnreadMessages;

    final internships = _all.where((o) => o.type == 'Internship').toList();
    final jobs = _all.where((o) => o.type != 'Internship').toList();
    final showInternships = _type != 'Full-time';
    final showJobs = _type != 'Internship';

    final repos2 = context.read<Repositories>();
    Widget cards(List<Opportunity> items) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - 16) / 2;
            return Wrap(spacing: 16, runSpacing: 16, children: [
              for (final o in items)
                SizedBox(
                  width: w,
                  child: JobCard(job: o, user: user, saved: app.isOpportunitySaved(o.id), applied: repos2.applications.isOpportunityApplied(o.id), onToggleSave: () => app.toggleSavedOpportunity(o.id), onTap: () => context.push('/opportunity/${o.id}')),
                ),
            ]);
          }),
        );
    String viewAllRoute(String title, List<Opportunity> l) => '/opportunities?title=${Uri.encodeQueryComponent(title)}&ids=${l.map((o) => o.id).join(',')}';
    Opportunity? topPick;
    for (final o in _all) {
      if (!repos2.applications.isOpportunityApplied(o.id) && (_type == 'All' || (_type == 'Internship') == (o.type == 'Internship'))) {
        topPick = o;
        break;
      }
    }
    final list = <Widget>[
      if (_loading)
        const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
      else if (wide) ...[
        if (topPick != null) _WebTopPick(job: topPick, user: user, onOpen: () => context.push('/opportunity/${topPick!.id}')),
        if (showInternships) ...[
          SectionHeading('Internships for you', link: 'View all', onLink: () => context.push(viewAllRoute('Internships for you', internships)), padding: const EdgeInsets.only(top: 36)),
          cards(internships.where((o) => o.id != topPick?.id).take(4).toList()),
        ],
        if (showJobs) ...[
          SectionHeading('Jobs for you', link: 'View all', onLink: () => context.push(viewAllRoute('Jobs for you', jobs)), padding: const EdgeInsets.only(top: 36)),
          cards(jobs.where((o) => o.id != topPick?.id).take(4).toList()),
        ],
      ],
      const SizedBox(height: 32),
    ];

    final search = const HomeSearchBar(height: 40, hint: 'Role, skill or company', compactHint: 'Role, skill or company');
    final filters = Row(children: [for (final f in const ['All', 'Internship', 'Full-time']) Padding(padding: const EdgeInsets.only(right: 6), child: AppChip(label: f, selected: _type == f, onPressed: () => setState(() => _type = f)))]);

    Widget body;
    if (!wide) {
      // Minimal v2 phone layout: greeting, search, text tabs, one pale "top pick" card, three rows
      // per list, a resume score card between them.
      final repos = context.read<Repositories>();
      Opportunity? top;
      for (final o in _all) {
        if (!repos.applications.isOpportunityApplied(o.id) && (_type == 'All' || (_type == 'Internship') == (o.type == 'Internship'))) {
          top = o;
          break;
        }
      }
      String viewAll(String title, List<Opportunity> l) => '/opportunities?title=${Uri.encodeQueryComponent(title)}&ids=${l.map((o) => o.id).join(',')}';
      body = ListView(controller: _scroll, padding: const EdgeInsets.only(bottom: 32), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(kPad, 12, 12, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_greeting(), style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)), Text(_first(user?.name), style: AppTextStyles.h1.copyWith(letterSpacing: -0.72))])),
            BarIcon(Ionicons.chatbubble_outline, dot: messages, onTap: () => context.push('/messages')),
            BarIcon(Ionicons.notifications_outline, dot: unread, onTap: () => openNotifications(context)),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(kPad, 20, kPad, 0), child: _SearchWell(onFilter: () => context.push('/college/opportunity-filter'))),
        TextTabs(labels: const ['All', 'Internships', 'Full-time'], selected: _type == 'Internship' ? 'Internships' : _type, onSelect: (l) => setState(() => _type = l == 'Internships' ? 'Internship' : l)),
        if (_loading)
          const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
        else ...[
          if (top != null) _TopPick(job: top, user: user, onOpen: () => context.push('/opportunity/${top!.id}')),
          if (showInternships) ...[
            V2Section('Internships for you', link: 'View all', onLink: () => context.push(viewAll('Internships for you', internships)), top: 28),
            V2List(children: [for (final o in internships.where((o) => o.id != top?.id).take(3)) _row(o, app, user, wide: false)]),
          ],
          if (user != null) _ResumeCard(user: user),
          if (showJobs) ...[
            V2Section('Jobs for you', link: 'View all', onLink: () => context.push(viewAll('Jobs for you', jobs))),
            V2List(children: [for (final o in jobs.where((o) => o.id != top?.id).take(3)) _row(o, app, user, wide: false)]),
          ],
        ],
      ]);
    } else {
      // Desktop: shared PageShell (centred 1200 container, 360 rail that stacks under 1100).
      final tabs = UiTabs(
        labels: const ['All', 'Internships', 'Full-time'],
        selected: _type == 'Internship' ? 'Internships' : _type,
        onSelect: (t) => setState(() => _type = t == 'Internships' ? 'Internship' : t),
      );
      Widget grid(List<Opportunity> items) => LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - Ui.gridGap) / 2;
            return Wrap(spacing: Ui.gridGap, runSpacing: Ui.gridGap, children: [
              for (final o in items)
                SizedBox(
                  width: w,
                  child: JobCard(job: o, user: user, saved: app.isOpportunitySaved(o.id), applied: repos2.applications.isOpportunityApplied(o.id), onToggleSave: () => app.toggleSavedOpportunity(o.id), onTap: () => context.push('/opportunity/${o.id}')),
                ),
            ]);
          });
      body = PageShell(
        controller: _scroll,
        rail: _WebRail(user: user, opportunities: _all),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(title: '${_greeting()}, ${_first(user?.name)}'),
          tabs,
          if (_loading)
            const Padding(padding: EdgeInsets.only(top: Ui.s48), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else ...[
            if (topPick != null) Padding(padding: const EdgeInsets.only(top: Ui.s28), child: _WebTopPick(job: topPick, user: user, onOpen: () => context.push('/opportunity/${topPick!.id}'))),
            if (showInternships) ...[
              SectionHeader('Internships for you', link: 'View all', onLink: () => context.push(viewAllRoute('Internships for you', internships))),
              grid(internships.where((o) => o.id != topPick?.id).take(4).toList()),
            ],
            if (showJobs) ...[
              SectionHeader('Jobs for you', link: 'View all', onLink: () => context.push(viewAllRoute('Jobs for you', jobs))),
              grid(jobs.where((o) => o.id != topPick?.id).take(4).toList()),
            ],
          ],
        ]),
      );
    }

    return Scaffold(backgroundColor: AppColors.white, body: wide ? body : SafeArea(bottom: false, child: body));
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final bool dot;
  final VoidCallback onTap;
  const _TopIcon({required this.icon, required this.dot, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, size: 20, color: AppColors.ink),
            if (dot) const Positioned(top: 9, right: 9, child: CircleAvatar(radius: 3, backgroundColor: AppColors.error)),
          ]),
        ),
      );
}

class _FilterBtn extends StatelessWidget {
  final VoidCallback onTap;
  final String? label;
  const _FilterBtn({required this.onTap, this.label});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Filter',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 14),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Ionicons.options_outline, size: 18, color: AppColors.ink),
              if (label != null) ...[const SizedBox(width: 6), Text(label!, style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.body))],
            ]),
          ),
        ),
      );
}

/// One-line nudge between lists on a phone.
class _ResumeNudge extends StatelessWidget {
  final User user;
  const _ResumeNudge({required this.user});

  @override
  Widget build(BuildContext context) {
    final score = user.atsScore;
    final hasResume = user.resume != null;
    final next = user.atsFixes.where((f) => !f.done).toList();
    return HairlineRow(
      minHeight: 60,
      onTap: () => context.push('/college/resume'),
      child: Row(children: [
        const Icon(Ionicons.document_text_outline, size: 18, color: AppColors.ink),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(hasResume ? 'Your resume scores $score / 100' : 'Build your resume with AI', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.ink)),
            Text(hasResume ? (next.isEmpty ? 'Looking strong for ATS filters.' : '${next.first.title} to reach ${user.atsPotential}.') : 'Takes about 5 minutes in chat.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
          ]),
        ),
        const LinkText('Improve'),
      ]),
    );
  }
}

class _Rail extends StatelessWidget {
  final User? user;
  final List<Opportunity> opportunities;
  const _Rail({required this.user, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final app = context.watch<AppState>();
    final saved = opportunities.where((o) => app.isOpportunitySaved(o.id)).take(2).toList();
    final score = user?.atsScore ?? 0;
    final fixes = (user?.atsFixes ?? const []).where((f) => !f.done).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text('Resume score', style: AppTextStyles.h3)),
            Text(user?.resume == null ? 'Not built' : '$score / 100', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.ink, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 10),
          ScoreBar(score / 100),
          const SizedBox(height: 10),
          Text(user?.resume == null ? 'Build an ATS-ready resume in a short chat.' : (fixes.isEmpty ? 'Looking strong for ATS filters.' : '${fixes.first.title} to reach ${user!.atsPotential}.'), style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, height: 1.45)),
          LinkText(user?.resume == null ? 'Build resume' : 'Improve resume', onTap: () => context.push('/college/resume')),
        ]),
      ),
      const Hairline(),
      SectionHeading('People you may know', link: 'View all', onLink: () => context.go('/tabs/network'), padding: const EdgeInsets.only(top: 20, bottom: 4)),
      for (final p in store.suggestions.take(2))
        Container(
          height: 56,
          child: Row(children: [
            MarkTile(p.initials, size: 32, round: true),
            const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: AppTextStyles.bodyLg), Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
            p.link == LinkState.requested ? Text('Requested', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500)) : LinkText('Connect', onTap: () => store.connect(p.id)),
          ]),
        ),
      const SizedBox(height: 8),
      const Hairline(),
      SectionHeading('Saved', count: saved.length, link: 'View all', onLink: () => context.push('/saved'), padding: const EdgeInsets.only(top: 20, bottom: 4)),
      if (saved.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Tap the bookmark on a role to keep it here.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))),
      for (final o in saved)
        GestureDetector(
          onTap: () => context.push('/opportunity/${o.id}'),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            alignment: Alignment.centerLeft,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg), Text('${o.company} · ${o.deadlineLabel ?? 'Open'}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))]),
          ),
        ),
      const SizedBox(height: 8),
      const Hairline(),
      GestureDetector(
        onTap: () => context.push('/booking?kind=counseling'),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Ionicons.chatbubble_ellipses_outline, size: 18, color: AppColors.gray500),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Talk to a placement expert', style: AppTextStyles.bodyLg), Text('1:1 guidance to land your next role.', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
          ]),
        ),
      ),
    ]);
  }
}

/// Search field of the phone Home: 44px, 8px corners, grey fill; the tune icon opens filters.
class _SearchWell extends StatelessWidget {
  final VoidCallback onFilter;
  const _SearchWell({required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Ionicons.search_outline, size: 18, color: AppColors.placeholder),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) context.push('/opportunities?q=${Uri.encodeQueryComponent(v.trim())}');
            },
            style: AppTextStyles.body,
            decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Role, skill or company', hintStyle: AppTextStyles.body.copyWith(color: AppColors.placeholder)),
          ),
        ),
        GestureDetector(onTap: onFilter, behavior: HitTestBehavior.opaque, child: const SizedBox(width: 32, height: 32, child: Icon(Ionicons.options_outline, size: 18, color: AppColors.ink))),
      ]),
    );
  }
}

/// The one pale blue card on Home: the best match, with the single yellow action.
class _TopPick extends StatelessWidget {
  final Opportunity job;
  final User? user;
  final VoidCallback onOpen;
  const _TopPick({required this.job, required this.user, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final match = job.matchLabelFor(user);
    final dl = job.deadlineLabel;
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(kPad, 24, kPad, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kPaleBlue, borderRadius: BorderRadius.circular(10), border: Border.all(color: kPaleBlueLine)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const Icon(Ionicons.star, size: 13, color: AppColors.blue), const SizedBox(width: 6), Text('Top pick for you', style: AppTextStyles.label.copyWith(color: AppColors.blue))]),
          const SizedBox(height: 12),
          Row(children: [
            Mark8(job.company.isEmpty ? '?' : job.company[0], outlined: true),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.title, style: AppTextStyles.h3.copyWith(fontSize: 16, height: 1.3)), const SizedBox(height: 2), Text('${job.company} · ${shortCity(job)}${dl == null ? '' : ' · $dl'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PayLine(pay: shortPay(job), tag: match)),
            const SizedBox(width: 12),
            Container(height: 34, padding: const EdgeInsets.symmetric(horizontal: 18), alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)), child: Text('Apply', style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: AppFontWeight.number, color: AppColors.ink))),
          ]),
        ]),
      ),
    );
  }
}

/// Grey resume score card between the two lists.
class _ResumeCard extends StatelessWidget {
  final User user;
  const _ResumeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final has = user.resume != null;
    final score = user.atsScore;
    final gain = user.atsPotential - score;
    final next = user.atsFixes.where((f) => !f.done).toList();
    return GestureDetector(
      onTap: () => context.push('/college/resume'),
      behavior: HitTestBehavior.opaque,
      child: FillCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text.rich(TextSpan(text: has ? 'Resume score ' : 'Build your resume', children: [if (has) TextSpan(text: '$score', style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])), if (has) const TextSpan(text: ' / 100', style: TextStyle(color: AppColors.gray500, fontWeight: AppFontWeight.regular))]), style: AppTextStyles.bodyLg)),
            Text(has ? 'Improve' : 'Start', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue)),
          ]),
          const SizedBox(height: 12),
          ScoreBar(has ? score / 100 : 0),
          const SizedBox(height: 12),
          Text(!has ? 'Chat with AI and get an ATS-ready resume in minutes.' : (next.isEmpty ? 'Looking strong for ATS filters.' : '${next.first.title} to reach ${score + gain}.'), style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
        ]),
      ),
    );
  }
}

/// Right rail of the desktop Home: resume score, people you may know, saved, expert help. No
/// dividers; sections are separated by space.
class _WebRail extends StatelessWidget {
  final User? user;
  final List<Opportunity> opportunities;
  const _WebRail({required this.user, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final app = context.watch<AppState>();
    final saved = opportunities.where((o) => app.isOpportunitySaved(o.id)).take(3).toList();
    final has = user?.resume != null;
    final score = user?.atsScore ?? 0;
    final fixes = (user?.atsFixes ?? const <AtsFix>[]).where((f) => !f.done).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InfoBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            const Expanded(child: Text('Resume score', style: Ui.rowTitle)),
            Text(has ? '$score / 100' : 'Not built', style: Ui.meta.copyWith(color: Ui.ink, fontFeatures: const [FontFeature.tabularFigures()])),
          ]),
          Padding(padding: const EdgeInsets.symmetric(vertical: Ui.s16), child: UiProgress(has ? score / 100 : 0)),
          Text(!has ? 'Build an ATS-ready resume in a short chat.' : (fixes.isEmpty ? 'Looking strong for ATS filters.' : '${fixes.first.title} to reach ${user!.atsPotential}.'), style: Ui.meta),
          const SizedBox(height: Ui.s12),
          GestureDetector(onTap: () => context.push('/college/resume'), child: MouseRegion(cursor: SystemMouseCursors.click, child: Text(has ? 'Improve resume' : 'Build resume', style: Ui.link))),
        ]),
      ),
      SectionHeader('People you may know', link: 'View all', onLink: () => context.go('/tabs/network')),
      for (final p in store.suggestions.take(2))
        Padding(
          padding: const EdgeInsets.only(bottom: Ui.betweenRows),
          child: ListRow(
            wrap: true,
            round: true,
            mark: p.initials,
            title: p.name,
            meta: p.headline,
            onTap: () => context.push('/person/${p.id}'),
            action: p.link == LinkState.requested ? Text('Requested', style: Ui.meta) : UiButton('Connect', compact: true, onTap: () => store.connect(p.id)),
          ),
        ),
      SectionHeader('Saved', link: 'View all', onLink: () => context.push('/saved')),
      if (saved.isEmpty) Text('Tap the bookmark on a role to keep it here.', style: Ui.meta),
      for (final o in saved)
        Padding(
          padding: const EdgeInsets.only(bottom: Ui.s16),
          child: GestureDetector(
            onTap: () => context.push('/opportunity/${o.id}'),
            behavior: HitTestBehavior.opaque,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.title, style: Ui.rowTitle), const SizedBox(height: 2), Text('${o.company} · ${o.deadlineLabel ?? 'Open'}', style: Ui.meta)]),
          ),
        ),
      const SizedBox(height: Ui.s24),
      GestureDetector(
        onTap: () => context.push('/booking?kind=counseling'),
        behavior: HitTestBehavior.opaque,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Ionicons.chatbubble_ellipses_outline, size: 18, color: Ui.secondary),
          const SizedBox(width: Ui.s12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Talk to a placement expert', style: Ui.rowTitle), const SizedBox(height: 2), Text('1:1 guidance to land your next role.', style: Ui.meta)])),
        ]),
      ),
    ]);
  }
}

/// The one highlight card on the desktop Home: the best match and the single yellow action.
class _WebTopPick extends StatelessWidget {
  final Opportunity job;
  final User? user;
  final VoidCallback onOpen;
  const _WebTopPick({required this.job, required this.user, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final match = job.matchLabelFor(user);
    final dl = job.deadlineLabel;
    return HighlightCard(
      onTap: onOpen,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [const Icon(Ionicons.star, size: 13, color: Ui.blue), const SizedBox(width: 6), Text('Top pick for you', style: Ui.label.copyWith(color: Ui.blue))]),
        const SizedBox(height: Ui.s16),
        Row(children: [
          Avatar(job.company.isEmpty ? '?' : job.company[0], size: 48),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(job.title, style: Ui.sectionHeading), const SizedBox(height: 2), Text('${job.company} · ${shortCity(job)}${dl == null ? '' : ' · $dl'}', style: Ui.meta)])),
          Padding(padding: const EdgeInsets.only(right: Ui.s16), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(shortPay(job), style: Ui.meta.copyWith(color: Ui.ink, fontWeight: FontWeight.w600)), if (match != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(match, style: Ui.link))])),
          UiButton('Apply', kind: UiButtonKind.primary, onTap: onOpen),
        ]),
      ]),
    );
  }
}
