import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/v2.dart';

class _Action {
  final String company;
  final String kind; // Viewed | Shortlisted | Messages
  final String text;
  final String when;
  final String? cta;
  final String? route;
  const _Action(this.company, this.kind, this.text, this.when, {this.cta, this.route});
}

const _actions = [
  _Action('Zerodha', 'Shortlisted', 'shortlisted you for Digital Marketing Intern.', '2h ago', cta: 'View application', route: '/tabs/browse'),
  _Action('Razorpay', 'Messages', 'sent you a message about Growth Intern.', '5h ago', cta: 'Reply', route: '/messages'),
  _Action('CRED', 'Viewed', 'viewed your profile.', 'Yesterday'),
  _Action('Swiggy', 'Viewed', 'downloaded your resume.', '2 days ago'),
  _Action('MakeMyTrip', 'Viewed', 'viewed your profile.', '4 days ago'),
];

/// What recruiters did with the student's profile: viewed, shortlisted, messaged.
class RecruiterActionsScreen extends StatefulWidget {
  const RecruiterActionsScreen({super.key});

  @override
  State<RecruiterActionsScreen> createState() => _RecruiterActionsScreenState();
}

class _RecruiterActionsScreenState extends State<RecruiterActionsScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final list = _tab == 'All' ? _actions : _actions.where((a) => a.kind == _tab).toList();
    return PageFrame(
      title: 'Recruiter actions',
      backLabel: 'Profile',
      backFallback: '/tabs/profile',
      maxWidth: 720,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextTabs(labels: const ['All', 'Viewed', 'Shortlisted', 'Messages'], selected: _tab, onSelect: (t) => setState(() => _tab = t), padding: EdgeInsets.zero),
        V2List(top: 24, side: 0, gap: 22, children: [
          if (list.isEmpty) Text('Nothing here yet.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          for (final a in list)
            V2Row(
              mark: Mark8(a.company[0]),
              title: '${a.company} ${a.text}',
              subtitle: a.when,
              trailing: a.cta == null ? null : MiniButton(a.cta!, onTap: () => context.push(a.route!)),
            ),
        ]),
      ]),
    );
  }
}
