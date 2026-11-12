import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories.dart';
import '../../models/notification_item.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/async_value_view.dart';
import '../../widgets/ds.dart';
import '../../widgets/empty_state.dart';

const _typeIcons = {
  'opportunity': Ionicons.briefcase_outline,
  'application': Ionicons.checkmark_circle_outline,
  'message': Ionicons.chatbubble_outline,
  'network': Ionicons.person_add_outline,
  'course': Ionicons.book_outline,
  'system': Ionicons.flash_outline,
};

/// Notifications. On a tablet or desktop they open as a right-hand panel under the top bar with a
/// scrim over the page; on a phone they are a full screen.
Future<void> openNotifications(BuildContext context) {
  if (!AppBreakpoints.isWide(context)) return context.push('/notifications');
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x3D111111),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Material(
          color: AppColors.white,
          shape: const Border(left: BorderSide(color: kLine)),
          child: SizedBox(width: 420, height: MediaQuery.sizeOf(dialogContext).height - 64, child: NotificationsScreen(asPanel: true, onClose: () => Navigator.of(dialogContext).pop())),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
  );
}

class NotificationsScreen extends StatefulWidget {
  /// Rendered inside the overlay panel: header with a close button, then the list.
  final bool asPanel;
  final VoidCallback? onClose;
  const NotificationsScreen({super.key, this.asPanel = false, this.onClose});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _markedRead = false;
  // Notifications that were unread when the screen opened keep their dot for this visit.
  Set<String>? _unreadOnOpen;

  Widget _row(NotificationItem n, bool unread) {
    return HairlineRow(
      minHeight: 64,
      onTap: n.route == null
          ? null
          : () {
              widget.onClose?.call();
              n.route!.startsWith('/tabs') ? context.go(n.route!) : context.push(n.route!);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(_typeIcons[n.type] ?? Ionicons.notifications_outline, size: 18, color: AppColors.gray500)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.35, fontWeight: unread ? AppFontWeight.medium : AppFontWeight.regular, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(n.body, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, height: 1.4)),
            ]),
          ),
          const SizedBox(width: 8),
          if (unread) const Padding(padding: EdgeInsets.only(top: 6), child: CircleAvatar(radius: 3, backgroundColor: AppColors.blue)) else if (n.route != null) const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray500),
        ]),
      ),
    );
  }

  Widget _list(BuildContext context, AppState appState, EdgeInsets padding) {
    return AsyncValueView<List<NotificationItem>>(
      loader: () => context.read<Repositories>().notifications.listNotifications(isSchool: false),
      isEmpty: (items) => items.isEmpty,
      emptyBuilder: (context) => const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: EmptyState(icon: Ionicons.notifications_off_outline, title: 'No notifications yet', subtitle: "We'll let you know when there's something new."))),
      builder: (context, items) {
        _unreadOnOpen ??= {for (final n in items) if (!appState.isNotificationRead(n.id)) n.id};
        if (!_markedRead) {
          _markedRead = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.read<AppState>().markNotificationsRead(items.map((n) => n.id).toList());
          });
        }
        final groups = <String>[];
        for (final n in items) {
          if (!groups.contains(n.group)) groups.add(n.group);
        }
        return ListView(padding: padding, children: [
          for (final g in groups) ...[
            Padding(padding: const EdgeInsets.only(top: 20, bottom: 4), child: Text(g.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.gray500, letterSpacing: 0.6))),
            const Hairline(),
            for (final n in items.where((n) => n.group == g)) _row(n, _unreadOnOpen!.contains(n.id)),
          ],
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (widget.asPanel) {
      return Column(children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
          child: Row(children: [
            Expanded(child: Text('Notifications', style: AppTextStyles.h2)),
            Semantics(button: true, label: 'Close', child: GestureDetector(onTap: widget.onClose, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Ionicons.close, size: 20, color: AppColors.gray500)))),
          ]),
        ),
        Expanded(child: _list(context, appState, const EdgeInsets.symmetric(horizontal: 24))),
      ]);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
              child: Row(children: [
                IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/tabs'), icon: const Icon(Ionicons.chevron_back, size: 20, color: AppColors.ink)),
                Expanded(child: Center(child: Text('Notifications', style: AppTextStyles.bodyLg))),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: _list(context, appState, const EdgeInsets.symmetric(horizontal: 16))))),
          ]),
        ),
      ),
    );
  }
}
