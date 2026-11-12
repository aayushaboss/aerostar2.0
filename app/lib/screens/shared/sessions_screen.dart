import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_bookings.dart';
import '../../models/booking.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/scroll_to_top_registry.dart';
import '../../widgets/ds.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/pill_button.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// Bookings: the student's placement / mock-interview sessions with the date, time and mode, and
/// Reschedule / Cancel. Reached from Profile.
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    ScrollToTopRegistry.register(2, () {});
    _load();
  }

  @override
  void dispose() {
    ScrollToTopRegistry.unregister(2);
    super.dispose();
  }

  void _load() => setState(() => _bookings = listBookings());

  void _reschedule(Booking b) {
    context.push(Uri(path: '/booking', queryParameters: {'kind': b.kind, 'bookingId': b.id, 'date': b.date, 'time': b.time, 'mode': b.mode, 'sessionType': b.sessionType ?? ''}).toString());
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm), side: const BorderSide(color: kLine)),
        title: Text('Cancel this session?', style: AppTextStyles.h3),
        content: Text('You can always book a new session later.', style: AppTextStyles.body.copyWith(color: AppColors.body)),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text('Keep session', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500))),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: Text('Yes, cancel', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    deleteBooking(b.id);
    context.read<AppState>().bumpDataVersion();
    _load();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: const Text('Session cancelled'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.yellow,
          onPressed: () {
            undoDeleteBooking(b.id);
            context.read<AppState>().bumpDataVersion();
            _load();
          },
        ),
        duration: const Duration(seconds: 4),
        persist: false,
      ));
  }

  Widget _row(Booking b) {
    DateTime? d;
    try {
      d = DateTime.parse(b.date);
    } catch (_) {}
    final online = b.mode.toLowerCase() == 'online';
    final title = (b.sessionType ?? '').isNotEmpty ? b.sessionType! : (b.kind == 'placement' ? 'Placement session' : 'Counselling session');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Column(children: [Text(d == null ? '' : _months[d.month - 1].toUpperCase(), style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.gray500, letterSpacing: 0.6)), Text(d == null ? '–' : '${d.day}', style: AppTextStyles.h2.copyWith(fontSize: 20, fontFeatures: const [FontFeature.tabularFigures()]))]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.bodyLg),
            const SizedBox(height: 2),
            Text('${b.time} · ${online ? 'Online' : 'In person'} · ${b.counselor}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
            if (!online && (b.venueName ?? '').isNotEmpty) Text('${b.venueName}${(b.venueCity ?? '').isEmpty ? '' : ', ${b.venueCity}'}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
            const SizedBox(height: 4),
            Row(children: [LinkText('Reschedule', onTap: () => _reschedule(b)), const SizedBox(width: 20), LinkText('Cancel', color: AppColors.gray500, onTap: () => _cancel(b))]),
          ]),
        ),
        Icon(online ? Ionicons.videocam_outline : Ionicons.location_outline, size: 18, color: AppColors.gray500),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    return PageFrame(
      title: 'Bookings',
      subtitle: _bookings.isEmpty ? null : '${_bookings.length} upcoming ${_bookings.length == 1 ? 'session' : 'sessions'}',
      backLabel: 'Profile',
      backFallback: '/tabs/profile',
      bottomBar: PillButton(label: 'Book a session', onPressed: () => context.push('/booking?kind=placement')),
      child: _bookings.isEmpty
          ? Padding(padding: const EdgeInsets.only(top: 48), child: EmptyState(icon: Ionicons.calendar_outline, title: 'No sessions booked', subtitle: 'Book a mock interview or a placement session with an expert.', buttonLabel: 'Book a session', onButtonTap: () => context.push('/booking?kind=placement')))
          : Column(children: [const Hairline(), for (final b in _bookings) _row(b)]),
    );
  }
}
