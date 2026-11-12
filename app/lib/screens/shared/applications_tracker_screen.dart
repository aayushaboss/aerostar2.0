import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/ats.dart';
import '../../models/application.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/relative_time.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/badges.dart';
import '../../widgets/ds.dart';
import '../../widgets/v2.dart';
import '../../ui/components/components.dart';
import '../../ui/page_shell.dart';
import '../../ui/tokens.dart';
import '../../widgets/empty_state.dart';

/// Applications tab: three number tabs (in progress, offers, not selected), then one hairline row
/// per application. Wide windows get a table and a right rail with the next step and preparation.
class ApplicationsTrackerScreen extends StatefulWidget {
  const ApplicationsTrackerScreen({super.key});

  @override
  State<ApplicationsTrackerScreen> createState() => _ApplicationsTrackerScreenState();
}

class _ApplicationsTrackerScreenState extends State<ApplicationsTrackerScreen> {
  List<Application> _apps = [];
  bool _loaded = false;
  int _lastSeenDataVersion = -1;
  final _scroll = ScrollController();
  String _tab = 'In progress';
  String _query = '';

  @override
  void initState() {
    super.initState();
    ScrollToTopRegistry.register(1, () {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(1);
    _scroll.dispose();
    super.dispose();
  }

  static bool _inProgress(Application a) => a.status == 'Applied' || a.status == 'In Review' || a.status == 'Interview';

  List<Application> _bucket(String tab) => switch (tab) {
        'Offers' => _apps.where((a) => a.status == 'Offer').toList(),
        'Not selected' => _apps.where((a) => a.status == 'Rejected').toList(),
        _ => _apps.where(_inProgress).toList(),
      };

  List<Application> get _visible {
    var list = _bucket(_tab);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((a) => a.opportunity.title.toLowerCase().contains(q) || a.opportunity.company.toLowerCase().contains(q)).toList();
    list.sort((a, b) => (DateTime.tryParse(b.createdAt) ?? DateTime(2000)).compareTo(DateTime.tryParse(a.createdAt) ?? DateTime(2000)));
    return list;
  }

  Future<void> _load() async {
    final apps = await context.read<Repositories>().applications.listApplications();
    if (mounted) {
      setState(() {
        _apps = apps;
        _loaded = true;
      });
    }
  }

  Future<void> _remove(Application a) async {
    final repo = context.read<Repositories>().applications;
    await repo.removeApplication(a.id);
    await _load();
    if (!mounted) return;
    context.read<AppState>().bumpDataVersion();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${a.opportunity.title}'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.yellow,
          onPressed: () async {
            await repo.restoreApplication(a.id);
            await _load();
            if (!mounted) return;
            context.read<AppState>().bumpDataVersion();
          },
        ),
        duration: const Duration(seconds: 4),
        persist: false,
      ));
  }

  Application? get _nextInterview {
    for (final a in _apps) {
      if (a.status == 'Interview') return a;
    }
    return null;
  }

  InterviewDetails? _interviewOf(Application a) {
    for (final m in a.messages.reversed) {
      if (m.interview != null) return m.interview;
    }
    return null;
  }

  Widget _tabs(bool wide) {
    Widget tab(String label, bool first) {
      final n = _bucket(label).length;
      final on = _tab == label;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = label),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 0, 14),
            decoration: BoxDecoration(border: Border(left: first ? BorderSide.none : const BorderSide(color: kLine), bottom: BorderSide(color: on ? AppColors.blue : Colors.transparent, width: 2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$n', style: AppTextStyles.h1.copyWith(fontSize: 28, fontFeatures: const [FontFeature.tabularFigures()])),
              Text(label, style: AppTextStyles.label.copyWith(fontSize: 13, color: on ? AppColors.blue : AppColors.gray500)),
            ]),
          ),
        ),
      );
    }

    final row = Row(children: [tab('In progress', true), tab('Offers', false), tab('Not selected', false)]);
    return Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))), child: wide ? Row(children: [SizedBox(width: 510, child: row), const Spacer()]) : row);
  }

  Widget _row(Application a, bool wide) {
    final when = DateTime.tryParse(a.createdAt);
    final menu = PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Ionicons.ellipsis_horizontal, size: 18, color: AppColors.gray500),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'remove') _remove(a);
      },
      itemBuilder: (_) => [const PopupMenuItem(value: 'remove', child: Text('Remove'))],
    );
    return HairlineRow(
      minHeight: 64,
      onTap: () => context.push('/application/${a.id}'),
      child: Row(children: [
        MarkTile(a.opportunity.company.isEmpty ? '?' : a.opportunity.company[0]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.opportunity.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg),
            Text(wide ? a.opportunity.company : '${a.opportunity.company} · ${when == null ? '' : relativeTimeLabel(when)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
          ]),
        ),
        if (wide) SizedBox(width: 130, child: Text(when == null ? '' : '${when.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][when.month - 1]} ${when.year}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, fontFeatures: const [FontFeature.tabularFigures()]))),
        SizedBox(width: wide ? 120 : null, child: Align(alignment: wide ? Alignment.centerLeft : Alignment.centerRight, child: StatusBadge(status: a.status))),
        if (wide) SizedBox(width: 40, child: menu) else const SizedBox(width: 4),
      ]),
    );
  }

  Widget _tabsV2() {
    final labels = ['In progress', 'Offers', 'Not selected'];
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kHair))),
      child: Row(children: [
        for (final l in labels)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = l),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _tab == l ? AppColors.blue : Colors.transparent, width: 2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(l, style: AppTextStyles.bodyLg.copyWith(color: _tab == l ? AppColors.ink : const Color(0xFF8A8A8A))),
                  const SizedBox(width: 6),
                  Container(constraints: const BoxConstraints(minWidth: 20), height: 20, padding: const EdgeInsets.symmetric(horizontal: 6), alignment: Alignment.center, decoration: BoxDecoration(color: _tab == l ? const Color(0x140A2FFF) : AppColors.offWhite, borderRadius: BorderRadius.circular(10)), child: Text('${_bucket(l).length}', style: AppTextStyles.caption.copyWith(fontSize: 11, color: _tab == l ? AppColors.blue : AppColors.gray500, fontFeatures: const [FontFeature.tabularFigures()]))),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  static Color _statusColor(String s) => switch (s) {
        'Interview' => AppColors.violet,
        'In Review' => AppColors.warningDark,
        'Offer' => AppColors.successDark,
        'Applied' => AppColors.blue,
        _ => AppColors.gray500,
      };

  Widget _groupsV2(List<Application> list) {
    final now = DateTime.now();
    final week = <Application>[];
    final earlier = <Application>[];
    for (final a in list) {
      final d = DateTime.tryParse(a.createdAt);
      (d != null && now.difference(d).inDays < 7 ? week : earlier).add(a);
    }
    Widget group(String label, List<Application> items) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(label, style: AppTextStyles.label.copyWith(color: AppColors.gray500, letterSpacing: 0.24)),
              const SizedBox(height: 16),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 22),
                  child: V2Row(
                    onTap: () => context.push('/application/${items[i].id}'),
                    mark: Mark8(items[i].opportunity.company.isEmpty ? '?' : items[i].opportunity.company[0]),
                    title: items[i].opportunity.title,
                    subtitle: '${items[i].opportunity.company} · ${DateTime.tryParse(items[i].createdAt) == null ? '' : relativeTimeLabel(DateTime.parse(items[i].createdAt))}',
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor(items[i].status), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(applicationStatusLabel(items[i].status), style: AppTextStyles.label.copyWith(fontSize: 13, color: _statusColor(items[i].status))),
                    ]),
                  ),
                ),
            ]),
          );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [group('This week', week), group('Earlier', earlier)]);
  }

  Widget _rail() {
    final next = _nextInterview;
    final iv = next == null ? null : _interviewOf(next);
    final user = context.watch<AppState>().user;
    Widget prep(IconData icon, String t, String s, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(height: 56, child: Row(children: [Icon(icon, size: 16, color: AppColors.ink), const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: AppTextStyles.bodyLg), Text(s, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))]))])),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (next != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next step', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 2),
            Text('Interview · ${next.opportunity.company}', style: AppTextStyles.h3),
            if (iv != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text('${iv.dateLabel}, ${iv.timeLabel} · ${iv.mode}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body))),
            Row(children: [LinkText('Details', onTap: () => context.push('/application/${next.id}')), const SizedBox(width: 16), LinkText('Message', onTap: () => context.push('/messages'))]),
          ]),
        ),
      const Hairline(),
      Padding(padding: const EdgeInsets.only(top: 16, bottom: 4), child: Text('Prepare', style: AppTextStyles.h3)),
      prep(Ionicons.mic_outline, 'Mock interview', '10 minutes', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock interviews arrive soon.')))),
      prep(Ionicons.chatbubble_outline, 'Message your recruiter', 'Ask about the next round', () => context.push('/messages')),
      prep(Ionicons.document_text_outline, 'Tailor your resume', 'ATS score ${user?.atsScore ?? 0}', () => context.push('/college/resume')),
      const Hairline(),
      GestureDetector(
        onTap: () => context.push('/applications/recently-deleted'),
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Row(children: [const Icon(Ionicons.trash_outline, size: 16, color: AppColors.body), const SizedBox(width: 8), Text('Recently deleted', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body))])),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.dataVersion != _lastSeenDataVersion) {
      _lastSeenDataVersion = app.dataVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    final wide = AppBreakpoints.isWide(context);
    final expanded = AppBreakpoints.isExpanded(context);
    final list = _visible;
    if (wide) return Scaffold(backgroundColor: AppColors.white, body: _webBody(list));

    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (wide) _tabs(wide) else _tabsV2(),
      if (wide)
        Container(
          height: 36,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
          child: Row(children: [
            Expanded(child: Text('Role', style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.gray500))),
            SizedBox(width: 130, child: Text('Applied', style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.gray500))),
            SizedBox(width: 120, child: Text('Status', style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.gray500))),
            const SizedBox(width: 40),
          ]),
        ),
      if (!_loaded)
        const Padding(padding: EdgeInsets.only(top: 48), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
      else if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: EmptyState(icon: Ionicons.document_text_outline, title: _query.isNotEmpty ? 'No matches' : (_tab == 'In progress' ? 'No applications yet' : 'Nothing here yet'), subtitle: _query.isNotEmpty ? 'Try a different role or company.' : 'Roles you apply to show up here with their status.'),
        )
      else
        if (wide) for (final a in list) _row(a, wide) else _groupsV2(list),
      const SizedBox(height: 32),
    ]);

    final header = wide
        ? Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Text('Applications', style: AppTextStyles.display)),
              SizedBox(
                width: 320,
                child: FieldWell(
                  child: Row(children: [
                    const Icon(Ionicons.search_outline, size: 16, color: AppColors.placeholder),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                        decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Search your applications…', hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder)),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          )
        : Padding(padding: const EdgeInsets.only(top: 12), child: Text('Applications', style: AppTextStyles.h1.copyWith(fontSize: 28, letterSpacing: -1.12)));

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
                  Expanded(child: body),
                  const SizedBox(width: 32),
                  Container(width: 300, padding: const EdgeInsets.only(left: 32), decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))), child: _rail()),
                ])
              else
                body,
            ]),
          ),
        ),
      ),
    );
  }
}

extension _ApplicationsWeb on _ApplicationsTrackerScreenState {
  /// Desktop (B2 directory, table): tabs with counts, then Role / Applied / Status / menu with
  /// 12px uppercase headers. Rail: next step and preparation. Status is a dot plus coloured text.
  Widget _webBody(List<Application> list) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final head = Ui.label.copyWith(fontSize: 12, letterSpacing: 0.6, color: Ui.tertiary);
    Widget cell(double w, Widget c) => SizedBox(width: w, child: c);
    final table = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        height: 40,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Ui.line))),
        child: Row(children: [
          Expanded(child: Text('ROLE', style: head)),
          cell(140, Text('APPLIED', style: head)),
          cell(140, Text('STATUS', style: head)),
          const SizedBox(width: 40),
        ]),
      ),
      if (!_loaded)
        const Padding(padding: EdgeInsets.only(top: Ui.s48), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
      else if (list.isEmpty)
        const Padding(padding: EdgeInsets.only(top: Ui.s32), child: Text('Nothing here yet. Roles you apply to show up with their status.', style: Ui.meta))
      else
        for (final a in list)
          Padding(
            padding: const EdgeInsets.only(top: Ui.s20),
            child: Row(children: [
              Expanded(child: ListRow(mark: a.opportunity.company.isEmpty ? '?' : a.opportunity.company[0], title: a.opportunity.title, meta: a.opportunity.company, onTap: () => context.push('/application/${a.id}'))),
              cell(140, Builder(builder: (_) {
                final d = DateTime.tryParse(a.createdAt);
                return Text(d == null ? '' : '${d.day} ${months[d.month - 1]} ${d.year}', style: Ui.meta.copyWith(color: Ui.ink));
              })),
              cell(140, StatusText(a.status)),
              SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Ionicons.ellipsis_horizontal, size: 18, color: Ui.secondary),
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'remove') _remove(a);
                  },
                  itemBuilder: (_) => [const PopupMenuItem(value: 'remove', child: Text('Remove'))],
                ),
              ),
            ]),
          ),
    ]);

    final next = _nextInterview;
    final iv = next == null ? null : _interviewOf(next);
    final user = context.watch<AppState>().user;
    final rail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (next != null)
        InfoBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Next step', style: Ui.label),
            const SizedBox(height: Ui.s4),
            Text('Interview · ${next.opportunity.company}', style: Ui.rowTitle),
            if (iv != null) Padding(padding: const EdgeInsets.only(top: Ui.s4), child: Text('${iv.dateLabel}, ${iv.timeLabel} · ${iv.mode}', style: Ui.meta)),
            const SizedBox(height: Ui.s16),
            Row(children: [UiButton('Details', compact: true, onTap: () => context.push('/application/${next.id}')), const SizedBox(width: Ui.s8), UiButton('Message', compact: true, kind: UiButtonKind.tertiary, onTap: () => context.push('/messages'))]),
          ]),
        ),
      SectionHeader('Prepare', top: next == null ? 0 : Ui.betweenSections),
      Padding(padding: const EdgeInsets.only(bottom: Ui.s16), child: ListRow(mark: 'M', title: 'Mock interview', meta: '10 minutes', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock interviews arrive soon.'))))),
      Padding(padding: const EdgeInsets.only(bottom: Ui.s16), child: ListRow(mark: 'R', title: 'Message your recruiter', meta: 'Ask about the next round', onTap: () => context.push('/messages'))),
      ListRow(mark: 'A', title: 'Tailor your resume', meta: 'ATS score ${user?.atsScore ?? 0}', onTap: () => context.push('/college/resume')),
    ]);

    return PageShell(
      controller: _scroll,
      rail: rail,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(title: 'Applications', actions: [UiButton('Recently deleted', kind: UiButtonKind.tertiary, onTap: () => context.push('/applications/recently-deleted'))]),
        UiTabs(labels: const ['In progress', 'Offers', 'Closed'], selected: _tab == 'Not selected' ? 'Closed' : _tab, counts: {for (final l in const ['In progress', 'Offers', 'Closed']) l: _bucket(l == 'Closed' ? 'Not selected' : l).length}, onSelect: (t) => setState(() => _tab = t == 'Closed' ? 'Not selected' : t)),
        const SizedBox(height: Ui.s8),
        table,
      ]),
    );
  }
}
