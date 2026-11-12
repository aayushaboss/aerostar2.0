import 'package:flutter/material.dart';
import '../ui/tokens.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import '../utils/initials.dart';
import 'brand.dart';

/// One place the app can go from the sidebar, the navigation rail or the bottom tab bar.
class NavDest {
  final String key;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  /// Set for the entries that are tabs (their position in the tab shell); null for the
  /// "More" entries, which are plain pushed pages.
  final int? branchIndex;

  const NavDest({required this.key, required this.label, required this.icon, required this.activeIcon, required this.route, this.branchIndex});
}

/// The app's navigation items for a student: the tabs (same as the phone's tab bar) and, on a
/// wide window, a "More" group for the pages that live inside Profile on a phone.
class AppNavigation {
  AppNavigation._();

  static List<NavDest> primary(User? user) {
    return const [
      NavDest(key: 'home', label: 'Home', icon: Ionicons.home_outline, activeIcon: Ionicons.home, route: '/tabs', branchIndex: 0),
      NavDest(key: 'applications', label: 'Applications', icon: Ionicons.list_outline, activeIcon: Ionicons.list, route: '/tabs/browse', branchIndex: 1),
      NavDest(key: 'network', label: 'Network', icon: Ionicons.people_outline, activeIcon: Ionicons.people, route: '/tabs/network', branchIndex: 3),
      NavDest(key: 'quiz', label: 'Career Quiz', icon: Ionicons.finger_print_outline, activeIcon: Ionicons.finger_print, route: '/tabs/career-dna', branchIndex: 5),
      NavDest(key: 'profile', label: 'Profile', icon: Ionicons.person_outline, activeIcon: Ionicons.person, route: '/tabs/profile', branchIndex: 4),
    ];
  }

  static List<NavDest> secondary(User? user) {
    final school = user?.segment == Segment.school;
    return [
      if (!school) const NavDest(key: 'saved', label: 'Saved', icon: Ionicons.bookmark_outline, activeIcon: Ionicons.bookmark, route: '/saved'),
      const NavDest(key: 'bookings', label: 'Bookings', icon: Ionicons.calendar_outline, activeIcon: Ionicons.calendar, route: '/tabs/sessions'),
      const NavDest(key: 'notifications', label: 'Notifications', icon: Ionicons.notifications_outline, activeIcon: Ionicons.notifications, route: '/notifications'),
      const NavDest(key: 'support', label: 'Support & Help', icon: Ionicons.help_circle_outline, activeIcon: Ionicons.help_circle, route: '/support'),
    ];
  }

  /// Which item is highlighted for a page. Detail pages light up the section they belong to, so
  /// the student always sees where they are.
  static String activeKeyFor(String location, User? user) {
    final school = user?.segment == Segment.school;
    final path = location.split('?').first;
    if (path == '/tabs') return 'home';
    if (path.startsWith('/tabs/browse')) return 'applications';
    if (path.startsWith('/tabs/sessions')) return school ? 'sessions' : 'bookings';
    if (path.startsWith('/tabs/network') || path.startsWith('/messages')) return 'network';
    if (path.startsWith('/tabs/career-dna')) return 'quiz';
    if (path.startsWith('/tabs/profile')) return 'profile';
    if (path.startsWith('/saved')) return 'saved';
    if (path.startsWith('/notifications')) return 'notifications';
    if (path.startsWith('/support')) return 'support';
    if (path.startsWith('/application')) return 'applications';
    if (path.startsWith('/course')) return 'home';
    if (path.startsWith('/college/career-dna')) return 'quiz';
    if (path.startsWith('/profile-edit') || path.startsWith('/college/resume') || path.startsWith('/search-appearances') || path.startsWith('/recruiter-actions')) return 'profile';
    return 'home';
  }

  static String segmentLabel(User? user) {
    switch (user?.segment) {
      case Segment.school:
        return 'School Student';
      case Segment.ug:
        return 'Undergraduate';
      case Segment.pg:
        return 'Postgraduate';
      case Segment.working:
        return 'Working';
      case null:
        return 'Student';
    }
  }
}

/// Top bar shown on a medium or expanded window: logo, the five destinations with an underline on
/// the active one, then messages, notifications and the avatar. (The phone uses the bottom tab bar.)
class AppTopNav extends StatelessWidget {
  final User? user;
  final String activeKey;
  final bool unreadNotifications;
  final bool unreadMessages;
  final ValueChanged<NavDest> onSelect;
  final VoidCallback onMessages;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const AppTopNav({
    super.key,
    required this.user,
    required this.activeKey,
    required this.unreadNotifications,
    required this.unreadMessages,
    required this.onSelect,
    required this.onMessages,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border, width: 1))),
      child: LayoutBuilder(
        builder: (context, box) => Padding(
          // Same container as the page: logo, page title and first content share the left edge.
          padding: EdgeInsets.symmetric(horizontal: Ui.leftEdge(box.maxWidth)),
            child: Row(
              children: [
                const Wordmark(size: 22),
                const SizedBox(width: Ui.s40),
                for (final d in AppNavigation.primary(user)) _TopNavItem(dest: d, active: d.key == activeKey, onTap: () => onSelect(d)),
                const Spacer(),
                const _NavSearch(),
                _TopIcon(icon: Ionicons.chatbubble_outline, label: 'Messages', dot: unreadMessages, onTap: onMessages),
                _TopIcon(icon: Ionicons.notifications_outline, label: 'Notifications', dot: unreadNotifications, onTap: onNotifications),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Profile',
                  child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onProfile, child: _Avatar(name: user?.name, photoUrl: user?.photoUrl, size: 32, fontSize: 12))),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

class _TopNavItem extends StatefulWidget {
  final NavDest dest;
  final bool active;
  final VoidCallback onTap;
  const _TopNavItem({required this.dest, required this.active, required this.onTap});

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.active;
    return Semantics(
      button: true,
      selected: a,
      label: widget.dest.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 64,
            margin: const EdgeInsets.only(right: 28),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: a ? AppColors.blue : Colors.transparent, width: 2))),
            alignment: Alignment.center,
            child: Text(widget.dest.label, style: AppTextStyles.label.copyWith(fontSize: 14, color: a ? AppColors.blue : (_hover ? AppColors.ink : AppColors.placeholder))),
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dot;
  final VoidCallback onTap;
  const _TopIcon({required this.icon, required this.label, required this.dot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.ink),
                if (dot) const Positioned(top: 10, right: 10, child: _UnreadDot()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final double size;
  final double fontSize;
  const _Avatar({required this.name, required this.photoUrl, required this.size, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.offWhite,
        alignment: Alignment.center,
        child: photoUrl != null
            ? Image.network(photoUrl!, width: size, height: size, fit: BoxFit.cover)
            : Text(initialsFor(name), style: AppTextStyles.label.copyWith(color: AppColors.ink, fontSize: fontSize)),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  final bool withRing;
  const _UnreadDot({this.withRing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: withRing ? Border.all(color: AppColors.offWhite, width: 1.5) : null,
      ),
    );
  }
}

class _NavSearch extends StatelessWidget {
  const _NavSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 38,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Ionicons.search_outline, size: 16, color: AppColors.placeholder),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) context.push('/opportunities?q=${Uri.encodeQueryComponent(v.trim())}');
            },
            style: AppTextStyles.body.copyWith(fontSize: 13),
            decoration: InputDecoration(isCollapsed: true, border: InputBorder.none, hintText: 'Role, skill or company', hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder)),
          ),
        ),
      ]),
    );
  }
}
