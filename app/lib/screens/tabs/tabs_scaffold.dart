import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/network_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../college/home_screen.dart';
import '../shared/applications_tracker_screen.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/accessible_tap_target.dart';
import '../../widgets/app_nav.dart';
import '../../widgets/app_shell.dart';

/// One bottom-tab-bar entry — used only by [TabsScaffold] now that there's
/// no separate top-nav-bar chrome to also share it with.
class TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int branchIndex;
  const TabItem({required this.icon, required this.activeIcon, required this.label, required this.branchIndex});
}

/// Home tab body (Aerostar has one student experience; the school segment was dropped).
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

/// Applications tab body.
class BrowseTabScreen extends StatelessWidget {
  const BrowseTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const ApplicationsTrackerScreen();
}

/// Bottom tab bar shell on a phone, top navigation bar on a wider window. Tabs: Home, Applications,
/// Network, Career Quiz, Profile. Every other screen (job detail, resume builder, messages...) is a
/// pushed route that covers the tab bar on a phone and keeps the top bar on a wide window.
class TabsScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;
  const TabsScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    const items = <TabItem>[
      TabItem(icon: Ionicons.home_outline, activeIcon: Ionicons.home, label: 'Home', branchIndex: 0),
      TabItem(icon: Ionicons.list_outline, activeIcon: Ionicons.list, label: 'Applications', branchIndex: 1),
      TabItem(icon: Ionicons.people_outline, activeIcon: Ionicons.people, label: 'Network', branchIndex: 3),
      TabItem(icon: Ionicons.finger_print_outline, activeIcon: Ionicons.finger_print, label: 'Career Quiz', branchIndex: 5),
      TabItem(icon: Ionicons.person_outline, activeIcon: Ionicons.person, label: 'Profile', branchIndex: 4),
    ];

    void goTo(int target) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).clearSnackBars();
      final wasAlreadyActive = target == shell.currentIndex;
      shell.goBranch(target, initialLocation: wasAlreadyActive);
      if (wasAlreadyActive) ScrollToTopRegistry.trigger(target);
    }

    if (AppBreakpoints.isWide(context)) {
      final activeKey = switch (shell.currentIndex) {
        0 => 'home',
        1 => 'applications',
        3 => 'network',
        4 => 'profile',
        _ => 'quiz',
      };
      return Scaffold(
        backgroundColor: AppColors.white,
        body: AppShellFrame(activeKey: activeKey, onSelect: (d) => goTo(d.branchIndex ?? 0), child: shell),
      );
    }

    final messagesDot = context.watch<NetworkStore>().hasUnreadMessages;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: Color(0xFFEFEFED), width: 1))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: items.map((item) {
                final active = shell.currentIndex == item.branchIndex;
                final color = active ? AppColors.blue : AppColors.gray500;
                return Expanded(
                  child: AccessibleTapTarget(
                    label: item.label,
                    selected: active,
                    onTap: () => goTo(item.branchIndex),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                                                Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              Icon(active ? item.activeIcon : item.icon, size: 20, color: color),
                              if (item.label == 'Network' && messagesDot) const Positioned(top: -1, right: -3, child: CircleAvatar(radius: 3, backgroundColor: AppColors.error)),
                            ]),
                            const SizedBox(height: 3),
                            Text(item.label, style: AppTextStyles.label.copyWith(fontSize: 11, letterSpacing: 0.15, color: color)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
