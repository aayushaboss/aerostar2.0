import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_opportunities.dart';
import '../../models/opportunity.dart';
import '../../models/opportunity_match.dart';
import '../../state/app_state.dart';
import '../../state/network_store.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../widgets/job_row.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/v2.dart';
import '../../data/repositories.dart';

Widget _frame(BuildContext context, {required String fallback, required List<Widget> actions, required List<Widget> children}) {
  return Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      bottom: false,
      child: WebAlign(
        child: ConstrainedBox(
          // Same 1040px column and left edge as the top bar; this content hangs off its left.
          constraints: const BoxConstraints(maxWidth: 1200 + 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(children: [
                  V2Bar(title: '', onBack: () => context.canPop() ? context.pop() : context.go(fallback), actions: actions, leading: Ionicons.chevron_back),
                  Expanded(child: ListView(padding: const EdgeInsets.only(bottom: 40), children: children)),
                ]),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _yellow(String label, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)), child: Text(label, style: AppTextStyles.bodyLg)));
Widget _outline(String label, VoidCallback? onTap) => GestureDetector(onTap: onTap, child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: kLine)), child: Text(label, style: AppTextStyles.bodyLg.copyWith(color: onTap == null ? AppColors.gray500 : AppColors.ink))));

/// Another person: connect or message, about, experience, skills.
class PersonScreen extends StatelessWidget {
  final String id;
  const PersonScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final p = store.people.where((p) => p.id == id).cast<Person?>().firstWhere((_) => true, orElse: () => null);
    if (p == null) return const NotFoundView(title: 'Profile not found', message: 'This profile may have been removed.');
    final parts = p.headline.split(' · ');
    final role = parts.first;
    final connected = p.link == LinkState.connected;
    final requested = p.link == LinkState.requested;
    final company = role.contains(' at ') ? role.split(' at ').last : '';
    final title = role.contains(' at ') ? role.split(' at ').first : role;

    Widget exp(String mark, String t, String s) => Padding(padding: const EdgeInsets.only(bottom: 20), child: V2Row(mark: Mark8(mark), title: t, subtitle: s));
    return _frame(context, fallback: '/tabs/network', actions: const [BarIcon(Ionicons.ellipsis_horizontal)], children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(kPad, 4, kPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(alignment: Alignment.centerLeft, child: Mark8(p.initials, size: 72, round: true)),
          const SizedBox(height: 14),
          Text(p.name, style: AppTextStyles.h1.copyWith(letterSpacing: -0.72)),
          const SizedBox(height: 4),
          Text(role, style: AppTextStyles.body.copyWith(color: AppColors.body)),
          const SizedBox(height: 2),
          Text('${parts.length > 1 ? '${parts.last} · ' : ''}${p.mutual} mutual connections', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: connected ? _outline('Connected', null) : (requested ? _outline('Requested', null) : _yellow('Connect', () => store.connect(p.id)))),
            const SizedBox(width: 8),
            Expanded(
              child: _outline('Message', () {
                if (!connected) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connect first. Chat opens once they accept.')));
                  return;
                }
                context.push('/messages/${store.openChat(p.id)}');
              }),
            ),
          ]),
        ]),
      ),
      const V2Section('About'),
      Padding(padding: const EdgeInsets.fromLTRB(kPad, 10, kPad, 0), child: Text(p.recruiter ? 'Hiring for ${company.isEmpty ? 'growing teams' : company}. Happy to answer questions about roles, the interview process and what we look for.' : 'Working on ${title.toLowerCase()} projects. Into learning in public and helping other students find their first role.', style: AppTextStyles.body.copyWith(color: AppColors.body, height: 1.55))),
      const V2Section('Experience'),
      Padding(padding: const EdgeInsets.fromLTRB(kPad, 16, kPad, 0), child: Column(children: [exp(company.isEmpty ? title[0] : company[0], title, '${company.isEmpty ? 'Independent' : company} · 2026 – present'), exp('S', 'Student Council', '${parts.length > 1 ? parts.last : 'College'} · 2025 – 2026')])),
      const V2Section('Skills', top: 12),
      Padding(padding: const EdgeInsets.fromLTRB(kPad, 12, kPad, 0), child: Wrap(spacing: 8, runSpacing: 8, children: [for (final s in (p.recruiter ? const ['Hiring', 'Interviewing', 'Employer branding'] : const ['Figma', 'Prototyping', 'User research', 'Motion'])) _Chip(s)])),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(6)), child: Text(text, style: AppTextStyles.label.copyWith(color: AppColors.body)));
}

/// A company: follow, and its open roles.
class CompanyScreen extends StatefulWidget {
  final String id;
  const CompanyScreen({super.key, required this.id});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  String _tab = 'Open roles';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final app = context.watch<AppState>();
    final repos = context.read<Repositories>();
    final c = store.companies.where((c) => c.id == widget.id).cast<Company?>().firstWhere((_) => true, orElse: () => null);
    if (c == null) return const NotFoundView(title: 'Company not found', message: 'This company page may have been removed.');
    final roles = mockOpportunities.where((o) => o.company.toLowerCase() == c.name.toLowerCase()).toList();
    final meta = c.line.split(' · ');

    return _frame(context, fallback: '/tabs/network', actions: const [BarIcon(Ionicons.share_outline)], children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(kPad, 4, kPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Align(alignment: Alignment.centerLeft, child: Mark8(c.name[0], size: 56)),
          const SizedBox(height: 14),
          Text(c.name, style: AppTextStyles.h1.copyWith(letterSpacing: -0.72)),
          const SizedBox(height: 4),
          Text('${meta.take(2).join(' · ')} · ${roles.length} open roles', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: c.following ? _outline('Following', () => store.toggleFollow(c.id)) : _yellow('Follow', () => store.toggleFollow(c.id))),
            const SizedBox(width: 8),
            Expanded(child: _outline('Website', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opens the company website.'))))),
          ]),
        ]),
      ),
      TextTabs(labels: const ['About', 'Open roles', 'People'], selected: _tab, counts: {'Open roles': roles.length}, onSelect: (t) => setState(() => _tab = t), padding: const EdgeInsets.fromLTRB(kPad, 24, kPad, 0)),
      if (_tab == 'Open roles')
        V2List(top: 24, children: [
          if (roles.isEmpty) Text('No open roles right now.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
          for (final o in roles)
            V2Row(
              onTap: () => context.push('/opportunity/${o.id}'),
              mark: Mark8(o.company[0]),
              title: o.title,
              subtitle: '${o.type == 'Internship' ? 'Internship' : 'Full-time'} · ${shortPay(o)}',
              trailing: repos.applications.isOpportunityApplied(o.id) ? Text('Applied', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500)) : (o.matchLabelFor(app.user) == null ? null : Text(o.matchLabelFor(app.user)!, style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.blue))),
            ),
        ])
      else if (_tab == 'About')
        Padding(padding: const EdgeInsets.fromLTRB(kPad, 24, kPad, 0), child: Text('${c.name} is a ${meta.first} company in ${meta.length > 1 ? meta[1] : 'India'}. It hires students and early-career talent across marketing, design, operations and product.', style: AppTextStyles.body.copyWith(color: AppColors.body, height: 1.55)))
      else
        V2List(top: 24, children: [
          for (final p in store.people.where((p) => p.headline.contains(c.name)))
            V2Row(onTap: () => context.push('/person/${p.id}'), mark: Mark8(p.initials, size: 44, round: true), title: p.name, subtitle: p.headline),
          if (!store.people.any((p) => p.headline.contains(c.name))) Text('No one from your network works here yet.', style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
        ]),
    ]);
  }
}

/// Unused import guard for Opportunity in this file.
// ignore: unused_element
typedef _Opp = Opportunity;
