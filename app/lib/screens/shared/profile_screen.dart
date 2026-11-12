import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/ats.dart';
import '../../models/profile_readiness.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../state/network_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/initials.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/ds.dart';
import '../../widgets/v2.dart';
import '../../ui/components/components.dart';
import '../../ui/page_shell.dart';
import '../../ui/tokens.dart';

/// Profile tab: who you are, your numbers, what is left to complete (the resume with its ATS score
/// first), and the menu (saved, bookings, notifications, support, log out).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    ScrollToTopRegistry.register(4, () {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(4);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: const BorderSide(color: kLine)),
        title: Text('Log out?', style: AppTextStyles.h3),
        content: Text("You'll need to sign in again to get back to your account.", style: AppTextStyles.body.copyWith(color: AppColors.body)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text('Cancel', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500))),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text('Log out', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AppState>().logout();
    if (!mounted) return;
    context.go('/onboarding');
  }

  String _summary(User u) {
    final parts = <String>[
      if ((u.course ?? '').isNotEmpty) u.course!,
      if ((u.college ?? '').isNotEmpty) u.college!,
      if ((u.city ?? '').isNotEmpty) u.city!,
    ];
    return parts.isEmpty ? 'Add your college and city' : parts.join(' · ');
  }

  static IconData _icon(String id) => switch (id) {
        'resume' => Ionicons.document_text_outline,
        'photo' => Ionicons.camera_outline,
        'video' => Ionicons.videocam_outline,
        _ => Ionicons.person_outline,
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final store = context.watch<NetworkStore>();
    final user = app.user;
    if (user == null) return const SizedBox.shrink();
    final wide = AppBreakpoints.isWide(context);
    final expanded = AppBreakpoints.isExpanded(context);
    final items = user.profileChecklist;
    final done = items.where((i) => i.done).length;
    if (!wide) return _compact(user, store, items, done);
    return _web(user, store, items, done);

    Widget stat(String n, String l) => Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: AppTextStyles.h1.copyWith(fontSize: 28, fontFeatures: const [FontFeature.tabularFigures()])), Text(l, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))]),
        );

    final header = Padding(
      padding: EdgeInsets.only(top: wide ? 32 : 16, bottom: wide ? 24 : 20),
      child: Row(children: [
        MarkTile(initialsFor(user.name), size: wide ? 72 : 56, round: true),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.name ?? 'Student', style: wide ? AppTextStyles.display : AppTextStyles.h1), const SizedBox(height: 4), Text(_summary(user), maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.body))])),
        if (wide) OutlinedButton.icon(onPressed: () => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile'), icon: const Icon(Ionicons.create_outline, size: 16), label: const Text('Edit profile'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: kLine), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)), textStyle: AppTextStyles.label.copyWith(fontSize: 13), minimumSize: const Size(0, 40))) else GestureDetector(onTap: () => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile'), child: const Padding(padding: EdgeInsets.all(8), child: Icon(Ionicons.create_outline, size: 20, color: AppColors.ink))),
      ]),
    );

    final stats = Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: kLine))),
      child: Row(children: [stat('${store.connectionCount}', 'Connections'), stat('36', 'Following'), GestureDetector(onTap: () => context.push('/search-appearances'), child: stat('12', 'Profile views this week'))]),
    );

    final completion = Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        Text('Profile completion', style: AppTextStyles.h3),
        const SizedBox(width: 16),
        Expanded(child: ScoreBar(items.isEmpty ? 0 : done / items.length)),
        const SizedBox(width: 16),
        Text.rich(TextSpan(text: '$done/${items.length}', style: const TextStyle(fontWeight: AppFontWeight.medium, color: AppColors.ink), children: [TextSpan(text: ' sections', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))]), style: AppTextStyles.body.copyWith(fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );

    final rows = <Widget>[
      for (final i in items)
        HairlineRow(
          minHeight: 68,
          onTap: () => i.route.startsWith('/tabs') ? context.go(i.route) : context.push(i.route),
          child: Row(children: [
            Icon(_icon(i.id), size: 20, color: AppColors.ink),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.title, style: AppTextStyles.bodyLg),
                  Text(i.id == 'resume' && i.done ? 'ATS score ${user.atsScore} · ${user.resume?.name ?? 'Resume'}' : i.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
                ]),
              ),
            ),
            LinkText(i.done ? (i.id == 'resume' ? 'Update' : 'Edit') : 'Add'),
          ]),
        ),
    ];

    Widget menuRow(IconData icon, String label, VoidCallback onTap, {bool last = false}) => HairlineRow(minHeight: 52, border: !last, onTap: onTap, child: Row(children: [Icon(icon, size: 18, color: AppColors.ink), const SizedBox(width: 14), Expanded(child: Text(label, style: AppTextStyles.body)), if (!wide) const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray500)]));
    final menu = Column(children: [
      menuRow(Ionicons.bookmark_outline, 'Saved', () => context.push('/saved')),
      menuRow(Ionicons.calendar_outline, 'Bookings', () => context.go('/tabs/sessions')),
      menuRow(Ionicons.chatbubble_outline, 'Messages', () => context.push('/messages')),
      menuRow(Ionicons.notifications_outline, 'Notifications', () => context.push('/notifications')),
      menuRow(Ionicons.help_circle_outline, 'Support & Help', () => context.push('/support')),
      menuRow(Ionicons.log_out_outline, 'Log out', _logout, last: true),
      Padding(padding: const EdgeInsets.only(top: 12), child: Align(alignment: Alignment.centerLeft, child: Text('Aerostar Edge · v2.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)))),
    ]);

    final main = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [stats, completion, const Hairline(), ...rows, const SizedBox(height: 24), if (!expanded) ...[const Hairline(), menu, const SizedBox(height: 32)]]);

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
                  Container(width: 300, padding: const EdgeInsets.fromLTRB(32, 12, 0, 0), decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))), child: menu),
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

extension _ProfileCompact on _ProfileScreenState {
  /// Minimal v2 phone layout: avatar and name, three numbers, a pale completion card, spaced
  /// sections (no dividers), one hairline, then the menu.
  Widget _compact(User user, NetworkStore store, List<ProfileChecklistItem> items, int done) {
    Widget section(ProfileChecklistItem i) => SizedBox(
          height: 60,
          child: GestureDetector(
            onTap: () => i.route.startsWith('/tabs') ? context.go(i.route) : context.push(i.route),
            behavior: HitTestBehavior.opaque,
            child: Row(children: [
              Icon(_ProfileScreenState._icon(i.id), size: 20, color: AppColors.body),
              const SizedBox(width: 14),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(i.title, style: AppTextStyles.bodyLg.copyWith(fontSize: 15)), Text(i.id == 'resume' && i.done ? 'ATS score ${user.atsScore}' : i.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))])),
              Text(i.done ? (i.id == 'resume' ? 'Update' : 'Edit') : 'Add', style: AppTextStyles.label.copyWith(fontSize: 13, color: i.done ? AppColors.gray500 : AppColors.blue)),
            ]),
          ),
        );
    Widget menu(IconData icon, String label, VoidCallback onTap) => GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: SizedBox(height: 52, child: Row(children: [Icon(icon, size: 20, color: AppColors.body), const SizedBox(width: 14), Expanded(child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 15, color: AppColors.ink))), const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray400)])));
    Widget stat(String n, String l) => Padding(padding: const EdgeInsets.only(right: 32), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: AppTextStyles.h2.copyWith(letterSpacing: -0.4, fontFeatures: const [FontFeature.tabularFigures()])), Text(l, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))]));
    final next = items.where((i) => !i.done).toList();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(controller: _scroll, padding: const EdgeInsets.only(bottom: 32), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kPad, 12, 8, 0),
            child: Row(children: [
              Mark8(initialsFor(user.name), size: 64, round: true),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.name ?? 'Student', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.h1.copyWith(letterSpacing: -0.72)), Text((user.city ?? '').isEmpty ? _summary(user) : user.city!, style: AppTextStyles.body.copyWith(color: AppColors.gray500))])),
              Align(alignment: Alignment.topCenter, child: BarIcon(Ionicons.create_outline, color: AppColors.ink, onTap: () => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile'))),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(kPad, 24, kPad, 0), child: Row(children: [stat('${store.connectionCount}', 'Connections'), stat('36', 'Following'), GestureDetector(onTap: () => context.push('/search-appearances'), child: stat('12', 'Profile views'))])),
          FillCard(
            margin: const EdgeInsets.fromLTRB(kPad, 28, kPad, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Expanded(child: Text('Complete your profile', style: AppTextStyles.bodyLg)), Text('$done of ${items.length}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500, fontFeatures: const [FontFeature.tabularFigures()]))]),
              const SizedBox(height: 12),
              SegBar(done, items.length),
              const SizedBox(height: 12),
              Text(next.isEmpty ? 'Your profile is complete.' : 'Next: ${next.first.title.toLowerCase()}.', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(kPad, 8, kPad, 0), child: Column(children: [for (final i in items) section(i)])),
          Container(height: 1, color: kHair, margin: const EdgeInsets.fromLTRB(kPad, 12, kPad, 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(kPad, 8, kPad, 0),
            child: Column(children: [
              menu(Ionicons.bookmark_outline, 'Saved', () => context.push('/saved')),
              menu(Ionicons.calendar_outline, 'Bookings', () => context.push('/tabs/sessions')),
              menu(Ionicons.help_circle_outline, 'Support & help', () => context.push('/support')),
              menu(Ionicons.log_out_outline, 'Log out', _logout),
            ]),
          ),
        ]),
      ),
    );
  }
}

extension _ProfileWeb on _ProfileScreenState {
  /// Desktop (B1 dashboard): identity header with Edit profile, plain stats, the sections in the
  /// main column; completion and the menu in the rail.
  Widget _web(User user, NetworkStore store, List<ProfileChecklistItem> items, int done) {
    Widget stat(String n, String l) => Padding(
          padding: const EdgeInsets.only(right: Ui.s48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: Ui.innerTitle.copyWith(fontFeatures: const [FontFeature.tabularFigures()])), const SizedBox(height: 2), Text(l, style: Ui.meta)]),
        );
    Widget menu(IconData icon, String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: Ui.s16),
          child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: MouseRegion(cursor: SystemMouseCursors.click, child: Row(children: [Icon(icon, size: 20, color: Ui.secondary), const SizedBox(width: 14), Expanded(child: Text(label, style: Ui.body)), const Icon(Ionicons.chevron_forward, size: 16, color: Ui.tertiary)]))),
        );
    final next = items.where((i) => !i.done).toList();
    final rail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InfoBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [const Expanded(child: Text('Complete your profile', style: Ui.rowTitle)), Text('$done of ${items.length}', style: Ui.meta)]),
          Padding(padding: const EdgeInsets.symmetric(vertical: Ui.s16), child: UiProgress(items.isEmpty ? 0 : done / items.length)),
          Text(next.isEmpty ? 'Your profile is complete.' : 'Next: ${next.first.title.toLowerCase()}.', style: Ui.meta),
        ]),
      ),
      const SectionHeader('More'),
      menu(Ionicons.bookmark_outline, 'Saved', () => context.push('/saved')),
      menu(Ionicons.calendar_outline, 'Bookings', () => context.push('/tabs/sessions')),
      menu(Ionicons.chatbubble_outline, 'Messages', () => context.push('/messages')),
      menu(Ionicons.help_circle_outline, 'Support & help', () => context.push('/support')),
      menu(Ionicons.log_out_outline, 'Log out', _logout),
    ]);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageShell(
        controller: _scroll,
        rail: rail,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Ui.headerToContent),
            child: Row(children: [
              Avatar(initialsFor(user.name), round: true, size: 72),
              const SizedBox(width: Ui.s20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.name ?? 'Student', style: Ui.pageTitle), const SizedBox(height: Ui.titleToSubtitle), Text(_summary(user), style: Ui.meta.copyWith(fontSize: 14))])),
              UiButton('Edit profile', icon: Ionicons.create_outline, onTap: () => context.push('/profile-edit?returnTo=%2Ftabs%2Fprofile')),
            ]),
          ),
          Row(children: [stat('${store.connectionCount}', 'Connections'), stat('36', 'Following'), GestureDetector(onTap: () => context.push('/search-appearances'), child: stat('12', 'Views this week'))]),
          const SectionHeader('Your profile', top: Ui.betweenSections),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Ui.betweenRows),
              child: Row(children: [
                Expanded(child: ListRow(mark: i.title[0], title: i.title, meta: i.id == 'resume' && i.done ? 'ATS score ${user.atsScore}' : i.subtitle, onTap: () => i.route.startsWith('/tabs') ? context.go(i.route) : context.push(i.route))),
                UiButton(i.done ? (i.id == 'resume' ? 'Update' : 'Edit') : 'Add', kind: UiButtonKind.tertiary, onTap: () => i.route.startsWith('/tabs') ? context.go(i.route) : context.push(i.route)),
              ]),
            ),
        ]),
      ),
    );
  }
}
