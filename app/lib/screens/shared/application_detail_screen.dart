import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../mockData/mock_applications.dart';
import '../../models/application.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/relative_time.dart';
import '../../widgets/badges.dart';
import '../../widgets/ds.dart';
import '../../widgets/not_found_view.dart';
import '../../widgets/page_frame.dart';
import '../../widgets/pill_button.dart';

const _terminal = {'Offer', 'Rejected'};

/// One application: the role and its status, the timeline, what the company said (with the
/// interview card), and what to do next.
class ApplicationDetailScreen extends StatelessWidget {
  final String id;
  const ApplicationDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final app = getApplicationById(id);
    if (app == null) return const NotFoundView(title: 'Application not found', message: 'This application may have been removed, or the link you followed is out of date.');
    final wide = AppBreakpoints.isWide(context);
    final o = app.opportunity;
    final when = DateTime.tryParse(app.createdAt);

    final header = Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MarkTile(o.company.isEmpty ? '?' : o.company[0], size: 48),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.title, style: AppTextStyles.h1.copyWith(fontSize: 22)), const SizedBox(height: 4), Text('${o.company} · ${o.type}${when == null ? '' : ' · Applied ${relativeTimeLabel(when)}'}', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))])),
        StatusBadge(status: app.status),
      ]),
    );

    final timeline = _Timeline(app: app);
    final messages = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeading('Messages from ${o.company}', padding: const EdgeInsets.only(top: 28, bottom: 8)),
      const Hairline(),
      if (app.messages.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text("No messages yet. You'll see updates from ${o.company} here.", style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500))),
      for (final m in app.messages) _Message(message: m),
    ]);

    final actions = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PillButton(label: 'Open the role', variant: PillVariant.secondary, onPressed: () => context.push('/opportunity/${app.opportunityId}')),
      const SizedBox(height: 8),
      PillButton(label: 'Message recruiter', variant: PillVariant.secondary, icon: Ionicons.chatbubble_outline, onPressed: () => context.push('/messages')),
      const SizedBox(height: 8),
      PillButton(label: 'Mock interview', variant: PillVariant.secondary, icon: Ionicons.mic_outline, onPressed: () => context.push('/booking?kind=placement')),
    ]);

    return PageFrame(
      title: 'Application',
      backLabel: 'Applications',
      backFallback: '/tabs/browse',
      maxWidth: 1040,
      child: wide
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              header,
              const Hairline(),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Padding(padding: const EdgeInsets.only(top: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Status', style: AppTextStyles.h3), const SizedBox(height: 16), timeline, messages]))),
                const SizedBox(width: 32),
                Container(width: 300, padding: const EdgeInsets.fromLTRB(32, 24, 0, 0), decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('Next steps', style: AppTextStyles.h3), const SizedBox(height: 12), actions])),
              ]),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, const Hairline(), const SizedBox(height: 20), Text('Status', style: AppTextStyles.h3), const SizedBox(height: 16), timeline, messages, const SizedBox(height: 24), actions]),
    );
  }
}

class _Timeline extends StatelessWidget {
  final Application app;
  const _Timeline({required this.app});

  @override
  Widget build(BuildContext context) {
    final events = app.timeline;
    final open = !_terminal.contains(app.status);
    final rejected = app.status == 'Rejected';
    final count = events.length + (open ? 1 : 0);
    return Column(children: [
      for (var i = 0; i < count; i++)
        Builder(builder: (context) {
          final pending = i == events.length;
          final last = i == count - 1;
          final e = pending ? null : events[i];
          final bad = !pending && rejected && i == events.length - 1;
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: pending ? AppColors.white : (bad ? AppColors.gray400 : AppColors.blue), border: Border.all(color: pending ? AppColors.gray200 : Colors.transparent)),
                  child: pending ? null : Icon(bad ? Ionicons.close : Ionicons.checkmark, size: 12, color: AppColors.white),
                ),
                if (!last) Expanded(child: Container(width: 1.5, color: pending ? kLine : AppColors.blue)),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(pending ? 'Awaiting next update' : applicationStatusLabel(e!.status), style: AppTextStyles.bodyLg.copyWith(color: pending ? AppColors.gray400 : AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(pending ? "We'll notify you the moment there's news." : '${e!.title} · ${relativeTimeLabel(e.at)}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                  ]),
                ),
              ),
            ]),
          );
        }),
    ]);
  }
}

class _Message extends StatelessWidget {
  final ApplicationMessage message;
  const _Message({required this.message});

  @override
  Widget build(BuildContext context) {
    final iv = message.interview;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(message.text, style: AppTextStyles.body.copyWith(height: 1.5)),
        const SizedBox(height: 4),
        Text(relativeTimeLabel(message.at), style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
        if (iv != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: kLine))),
            child: Row(children: [
              const Icon(Ionicons.calendar_outline, size: 18, color: AppColors.ink),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${iv.round} · ${iv.dateLabel}, ${iv.timeLabel}', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.ink)), Text('${iv.mode} · ${iv.location}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
            ]),
          ),
      ]),
    );
  }
}
