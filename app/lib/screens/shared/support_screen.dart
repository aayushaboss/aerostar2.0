import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/v2.dart';

const _topics = [
  (Ionicons.briefcase_outline, 'Applications', 'Status, withdrawing, interviews', [
    ('How do I know my application was seen?', 'You will see "Viewed by recruiter" in the timeline of the application. We also send a notification.'),
    ('Can I withdraw an application?', 'Yes. Open the application and choose Withdraw. You can apply again while the role is open.'),
    ('How are interviews scheduled?', 'The recruiter proposes a time in the application. Accept it, or ask to reschedule.'),
  ]),
  (Ionicons.person_outline, 'Account & profile', 'Login, privacy, deleting account', [
    ('Who can see my profile?', 'Recruiters you applied to, and people you connect with. Your phone number is never shown.'),
    ('How do I delete my account?', 'Go to Profile, Edit profile, then Delete account. This removes your data after 30 days.'),
  ]),
  (Ionicons.calendar_outline, 'Bookings', 'Rescheduling and refunds', [
    ('Can I reschedule a session?', 'Yes, up to two hours before it starts, from Profile, Bookings.'),
    ('Do I pay for sessions?', 'Sessions with placement experts are included in your plan.'),
  ]),
  (Ionicons.document_text_outline, 'Resume', 'Uploading and ATS score', [
    ('What is the ATS score?', 'A score out of 100 for how well an applicant tracking system can read your resume. Fix the listed items to raise it.'),
    ('Can I upload my own PDF?', 'Yes. Choose Upload a PDF on the Resume screen. We read it and suggest fixes.'),
  ]),
];

/// Help and support: search, topics (each opens its questions) and ways to reach us.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label) => Expanded(
          child: GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label opens here in the live app.'))),
            child: Container(height: 44, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: kLine)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: AppColors.ink), const SizedBox(width: 8), Text(label, style: AppTextStyles.bodyLg)])),
          ),
        );
    return PageFrame(
      title: 'Help & support',
      backLabel: 'Profile',
      backFallback: '/tabs/profile',
      maxWidth: 720,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldWell(height: 44, child: Row(children: [const Icon(Ionicons.search_outline, size: 18, color: AppColors.placeholder), const SizedBox(width: 10), Text('Search help articles', style: AppTextStyles.body.copyWith(color: AppColors.placeholder))])),
        const SizedBox(height: 28),
        Text('Topics', style: AppTextStyles.label.copyWith(color: AppColors.gray500, letterSpacing: 0.24)),
        const SizedBox(height: 8),
        for (var i = 0; i < _topics.length; i++) ...[
          GestureDetector(
            onTap: () => setState(() => _open = _open == i ? null : i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 64,
              child: Row(children: [
                Icon(_topics[i].$1, size: 20, color: AppColors.body),
                const SizedBox(width: 14),
                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_topics[i].$2, style: AppTextStyles.bodyLg.copyWith(fontSize: 15)), Text(_topics[i].$3, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))])),
                Icon(_open == i ? Ionicons.chevron_down : Ionicons.chevron_forward, size: 16, color: AppColors.gray400),
              ]),
            ),
          ),
          if (_open == i)
            Padding(
              padding: const EdgeInsets.only(left: 34, bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final q in _topics[i].$4) ...[
                  Text(q.$1, style: AppTextStyles.bodyLg.copyWith(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(q.$2, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, height: 1.5)),
                  const SizedBox(height: 14),
                ],
              ]),
            ),
        ],
        const SizedBox(height: 24),
        Text('Still need help?', style: AppTextStyles.h3),
        const SizedBox(height: 12),
        Row(children: [action(Ionicons.chatbubble_outline, 'Chat'), const SizedBox(width: 8), action(Ionicons.call_outline, 'Call'), const SizedBox(width: 8), action(Ionicons.help_circle_outline, 'FAQs')]),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: LinkText('Message a placement expert', onTap: () => context.push('/booking?kind=placement'))),
      ]),
    );
  }
}
