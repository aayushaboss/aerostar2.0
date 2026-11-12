import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../mockData/mock_opportunities.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/ds.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_row.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/v2.dart';

/// Saved opportunities: the roles the student bookmarked, split into Internships and Jobs on a
/// phone (text tabs) and shown as one table on a wide window.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  String _tab = 'Internships';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final repos = context.read<Repositories>();
    final wide = AppBreakpoints.isWide(context);
    final all = mockOpportunities.where((o) => app.isOpportunitySaved(o.id)).toList();
    final interns = all.where((o) => o.type == 'Internship').toList();
    final jobs = all.where((o) => o.type != 'Internship').toList();
    final items = wide ? all : (_tab == 'Internships' ? interns : jobs);

    Widget row(o) => JobRow(job: o, user: app.user, wide: wide, saved: true, applied: repos.applications.isOpportunityApplied(o.id), onToggleSave: () => app.toggleSavedOpportunity(o.id), onTap: () => context.push('/opportunity/${o.id}'));

    return PageFrame(
      title: 'Saved',
      subtitle: wide ? '${all.length} bookmarked ${all.length == 1 ? 'role' : 'roles'}' : null,
      backLabel: 'Profile',
      backFallback: '/tabs/profile',
      maxWidth: 1040,
      child: all.isEmpty
          ? Padding(padding: const EdgeInsets.only(top: 48), child: EmptyState(icon: Ionicons.bookmark_outline, title: 'Nothing saved yet', subtitle: 'Tap the bookmark on any role to keep it here.', buttonLabel: 'Browse roles', onButtonTap: () => context.go('/tabs')))
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (!wide) TextTabs(labels: const ['Internships', 'Jobs'], selected: _tab, counts: {'Internships': interns.length, 'Jobs': jobs.length}, onSelect: (t) => setState(() => _tab = t), padding: const EdgeInsets.only(bottom: 4)),
              if (wide) const JobTableHeader(),
              if (wide) for (final o in items) row(o) else V2List(top: 24, side: 0, children: [for (final o in items) row(o)]),
            ]),
    );
  }
}
