import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../mockData/mock_opportunities.dart' show searchRelevance;
import '../../widgets/async_value_view.dart';
import '../../widgets/ds.dart';
import '../../ui/components/components.dart';
import '../../ui/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_row.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/sort_dropdown.dart';

/// A list of opportunities: search results, "View all" from Home, a notification's roles or one
/// category. Same hairline rows as Home. Filters live on their own screen (the tune button).
class OpportunityListScreen extends StatefulWidget {
  final String title;
  final String? category;

  /// Explicit ids, in order (a notification or a "View all" list). Wins over [category].
  final List<String>? ids;

  /// Free-text query from the Home search bar.
  final String? query;

  const OpportunityListScreen({super.key, required this.title, this.category, this.ids, this.query});

  @override
  State<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

class _OpportunityListScreenState extends State<OpportunityListScreen> {
  String _sort = 'match';
  late final TextEditingController _search = TextEditingController(text: widget.query ?? '');
  late String _query = widget.query ?? '';
  int _limit = 30;
  final Set<String> _locs = {};
  final Set<String> _modes = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Opportunity>> _load(User? user) async {
    final repo = context.read<Repositories>().opportunities;
    if (widget.ids != null) return widget.ids!.map(repo.getOpportunityById).whereType<Opportunity>().toList();
    final prefs = user?.preferences;
    final goal = user?.goal;
    final roles = user?.roles ?? const <String>[];
    final results = await repo.listOpportunities(
      type: widget.category != null ? null : (goal == 'internship' ? 'Internship' : (goal == 'job' ? 'Full-time' : null)),
      workMode: prefs?.workMode,
      employmentType: prefs?.employmentType,
      categories: widget.category != null ? [widget.category!] : (roles.isEmpty ? null : roles),
      locations: (prefs?.cities.isEmpty ?? true) ? null : prefs!.cities,
      query: _query.trim().isEmpty ? null : _query,
    );
    final q = _query.trim().isEmpty ? null : _query;
    results.sort((a, b) {
      if (_sort == 'deadline') {
        final da = DateTime.tryParse(a.deadline);
        final db = DateTime.tryParse(b.deadline);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      }
      if (q != null) {
        final r = searchRelevance(b, q).compareTo(searchRelevance(a, q));
        if (r != 0) return r;
      }
      return b.matchScoreFor(user).compareTo(a.matchScoreFor(user));
    });
    return results;
  }

  String _filterSig(User? u) => '${u?.goal}|${(u?.roles ?? const <String>[]).join(',')}|${u?.preferences?.workMode}|${u?.preferences?.employmentType}|${(u?.preferences?.cities ?? const <String>[]).join(',')}';

  int _filterCount(User? u) => (u?.goal == 'internship' || u?.goal == 'job' ? 1 : 0) + ((u?.roles ?? const <String>[]).isEmpty ? 0 : 1) + (u?.preferences?.workMode != null ? 1 : 0) + (u?.preferences?.employmentType != null ? 1 : 0) + (u?.preferences?.cities.length ?? 0);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final wide = AppBreakpoints.isWide(context);
    final repos = context.read<Repositories>();

    if (wide) {
      // Desktop (B3 browse): 220px filter column, 56px gap, results in the remaining width.
      Widget group(String title, List<String> options, Set<String> chosen) => Padding(
            padding: const EdgeInsets.only(bottom: Ui.s28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Ui.rowTitle),
              const SizedBox(height: Ui.s12),
              for (final o in options)
                GestureDetector(
                  onTap: () => setState(() => chosen.contains(o) ? chosen.remove(o) : chosen.add(o)),
                  behavior: HitTestBehavior.opaque,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Ui.s12),
                      child: Row(children: [
                        Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: chosen.contains(o) ? Ui.blue : Ui.inputBorder), color: chosen.contains(o) ? Ui.blue : Colors.transparent), child: chosen.contains(o) ? const Icon(Ionicons.checkmark, size: 12, color: Colors.white) : null),
                        const SizedBox(width: Ui.s12),
                        Text(o, style: Ui.body.copyWith(height: 1.2)),
                      ]),
                    ),
                  ),
                ),
            ]),
          );
      final filters = SizedBox(
        width: Ui.filterColumn,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Filters', style: Ui.sectionHeading)),
            GestureDetector(onTap: () => setState(() {
                  _locs.clear();
                  _modes.clear();
                }), child: const MouseRegion(cursor: SystemMouseCursors.click, child: Text('Reset', style: Ui.link))),
          ]),
          const SizedBox(height: Ui.s20),
          group('Location', const ['Bengaluru', 'Mumbai', 'Gurugram', 'Remote'], _locs),
          group('Work mode', const ['Onsite', 'Hybrid', 'Remote'], _modes),
          GestureDetector(onTap: () => context.push('/college/opportunity-filter'), child: const MouseRegion(cursor: SystemMouseCursors.click, child: Text('More filters', style: Ui.link))),
        ]),
      );
      final results = AsyncValueView<List<Opportunity>>(
        key: ValueKey('$_sort|$_query|${app.dataVersion}|${_filterSig(user)}'),
        loader: () => _load(user),
        isEmpty: (items) => items.isEmpty,
        emptyBuilder: (context) => const Padding(padding: EdgeInsets.only(top: Ui.s48), child: EmptyState(icon: Ionicons.search_outline, title: 'No matches', subtitle: 'Try a different role, skill or company.')),
        builder: (context, all) {
          final items = all.where((o) => (_locs.isEmpty || _locs.any((l) => o.location.toLowerCase().contains(l.toLowerCase()))) && (_modes.isEmpty || _modes.any((m) => o.workMode.toLowerCase().contains(m.toLowerCase())))).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text('${items.length} results', style: Ui.meta)),
              SortDropdown(value: _sort, options: const [('match', 'Best match'), ('deadline', 'Closing soon')], onChanged: (v) => setState(() => _sort = v)),
            ]),
            const SizedBox(height: Ui.s20),
            if (items.isEmpty) const Padding(padding: EdgeInsets.only(top: Ui.s32), child: Text('No roles match these filters.', style: Ui.meta)),
            for (final o in items.take(_limit))
              Padding(
                padding: const EdgeInsets.only(bottom: Ui.betweenRows),
                child: JobRow(job: o, user: user, wide: false, saved: app.isOpportunitySaved(o.id), applied: repos.applications.isOpportunityApplied(o.id), onToggleSave: () => app.toggleSavedOpportunity(o.id), onTap: () => context.push('/opportunity/${o.id}')),
              ),
            if (items.length > _limit) Padding(padding: const EdgeInsets.only(top: Ui.s8), child: UiButton('Show more', kind: UiButtonKind.tertiary, onTap: () => setState(() => _limit += 30))),
          ]);
        },
      );
      return PageFrame(
        title: widget.title,
        backFallback: '/tabs',
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [filters, const SizedBox(width: Ui.s48 + Ui.s8), Expanded(child: results)]),
      );
    }

    final tools = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(
          child: FieldWell(
            child: Row(children: [
              const Icon(Ionicons.search_outline, size: 16, color: AppColors.placeholder),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Role, skill or company', hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/college/opportunity-filter'),
          behavior: HitTestBehavior.opaque,
          child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 10), alignment: Alignment.center, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.options_outline, size: 18, color: AppColors.ink), if (_filterCount(user) > 0) ...[const SizedBox(width: 6), Text('${_filterCount(user)}', style: AppTextStyles.label.copyWith(color: AppColors.blue))]])),
        ),
        SortDropdown(value: _sort, options: const [('match', 'Best match'), ('deadline', 'Closing soon')], onChanged: (v) => setState(() => _sort = v)),
      ]),
    );

    final list = AsyncValueView<List<Opportunity>>(
      key: ValueKey('$_sort|$_query|${app.dataVersion}|${_filterSig(user)}'),
      loader: () => _load(user),
      isEmpty: (items) => items.isEmpty,
      emptyBuilder: (context) => const Padding(padding: EdgeInsets.only(top: 48), child: EmptyState(icon: Ionicons.search_outline, title: 'No matches', subtitle: 'Try a different role, skill or company.')),
      builder: (context, items) => Column(children: [
        if (wide) const JobTableHeader() else const SizedBox(height: 12),
        for (final o in items.take(_limit))
          Padding(
            padding: EdgeInsets.only(bottom: wide ? 0 : 24, top: wide ? 0 : 0),
            child: JobRow(
            job: o,
            user: user,
            wide: wide,
            saved: app.isOpportunitySaved(o.id),
            applied: repos.applications.isOpportunityApplied(o.id),
            onToggleSave: () => app.toggleSavedOpportunity(o.id),
            onTap: () => context.push('/opportunity/${o.id}'),
          )),
        if (items.length > _limit) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: LinkText('Show more', onTap: () => setState(() => _limit += 30))),
      ]),
    );

    return PageFrame(
      title: widget.title,
      backFallback: '/tabs',
      maxWidth: 1040,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [tools, list]),
    );
  }
}
