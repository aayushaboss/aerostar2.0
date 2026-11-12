import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/application.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/v2.dart';

/// Recently deleted applications: removed for good after 30 days; restore one or all.
class RecentlyDeletedApplicationsScreen extends StatefulWidget {
  const RecentlyDeletedApplicationsScreen({super.key});

  @override
  State<RecentlyDeletedApplicationsScreen> createState() => _RecentlyDeletedApplicationsScreenState();
}

class _RecentlyDeletedApplicationsScreenState extends State<RecentlyDeletedApplicationsScreen> {
  List<Application> _apps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await context.read<Repositories>().applications.listRecentlyDeleted();
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _restore(Application a, {bool quiet = false}) async {
    await context.read<Repositories>().applications.restoreApplication(a.id);
    if (!quiet) await _load();
    if (!mounted) return;
    context.read<AppState>().bumpDataVersion();
    if (!quiet) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Restored ${a.opportunity.title}. Check Applications.')));
    }
  }

  Future<void> _restoreAll() async {
    for (final a in List.of(_apps)) {
      await _restore(a, quiet: true);
    }
    await _load();
  }

  Future<void> _deleteForever(Application a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: const BorderSide(color: kLine)),
        title: Text('Delete forever?', style: AppTextStyles.h3),
        content: Text("This application will be permanently removed and can't be recovered.", style: AppTextStyles.body.copyWith(color: AppColors.body)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text('Cancel', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500))),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text('Delete', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<Repositories>().applications.permanentlyDelete(a.id);
    await _load();
  }

  int _daysLeft(Application a) {
    final d = DateTime.tryParse(a.deletedAt ?? '');
    if (d == null) return 30;
    return (30 - DateTime.now().difference(d).inDays).clamp(0, 30);
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Recently deleted',
      subtitle: 'Removed for good after 30 days.',
      backLabel: 'Applications',
      backFallback: '/tabs/browse',
      actions: [if (_apps.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: LinkText('Restore all', onTap: _restoreAll)))],
      child: _apps.isEmpty
          ? Padding(padding: const EdgeInsets.only(top: 48), child: EmptyState(icon: Ionicons.trash_outline, title: 'Nothing here', subtitle: 'Applications you remove stay here for 30 days.'))
          : V2List(top: 20, side: 0, gap: 22, children: [
              for (final a in _apps)
                V2Row(
                  mark: Mark8(a.opportunity.company.isEmpty ? '?' : a.opportunity.company[0]),
                  title: a.opportunity.title,
                  subtitle: '${a.opportunity.company} · ${_daysLeft(a)} days left',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    GestureDetector(onTap: () => _deleteForever(a), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Ionicons.trash_outline, size: 16, color: AppColors.gray500))),
                    MiniButton('Restore', onTap: () => _restore(a)),
                  ]),
                ),
            ]),
    );
  }
}
