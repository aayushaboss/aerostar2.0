import 'package:flutter/material.dart';
import '../../widgets/web_align.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/network_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/ds.dart';
import '../../ui/tokens.dart';
import '../../widgets/pill_button.dart';

/// Messages: conversation list, plus the open thread. On a wide window both sit side by side; on
/// a phone the list and the thread are separate pages (`/messages` and `/messages/:id`).
class MessagesScreen extends StatelessWidget {
  final String? conversationId;
  const MessagesScreen({super.key, this.conversationId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final wide = AppBreakpoints.isWide(context);
    final selected = conversationId ?? (wide && store.conversations.isNotEmpty ? store.conversations.first.id : null);

    if (!wide) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: selected == null ? _ConversationList(selected: null, wide: false) : _Thread(id: selected, wide: false)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.white,
      body: WebAlign(inset: 0, 
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Ui.s32),
            child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(border: Border.all(color: Ui.line), borderRadius: BorderRadius.circular(Ui.rPanel)),
            child: Row(children: [
              Container(width: 340, decoration: const BoxDecoration(border: Border(right: BorderSide(color: kLine))), child: _ConversationList(selected: selected, wide: true)),
              Expanded(child: selected == null ? const SizedBox() : _Thread(id: selected, wide: true)),
            ]),
          )),
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final String? selected;
  final bool wide;
  const _ConversationList({required this.selected, required this.wide});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    return Column(children: [
      Container(
        height: 64,
        padding: EdgeInsets.only(left: wide ? 20 : 4, right: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          if (!wide) IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/tabs/network'), icon: const Icon(Ionicons.chevron_back, size: 20, color: AppColors.ink)),
          Expanded(child: Text('Messages', style: AppTextStyles.h2)),
          const Icon(Ionicons.create_outline, size: 18, color: AppColors.ink),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FieldWell(height: 36, child: Row(children: [const Icon(Ionicons.search_outline, size: 16, color: AppColors.placeholder), const SizedBox(width: 8), Text('Search messages', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder))])),
      ),
      const Hairline(),
      Expanded(
        child: ListView(children: [
          for (final c in store.conversations)
            HairlineRow(
              minHeight: 68,
              onTap: () => wide ? context.go('/messages/${c.id}') : context.push('/messages/${c.id}'),
              child: Container(
                color: wide && c.id == selected ? AppColors.offWhite : null,
                padding: EdgeInsets.symmetric(horizontal: wide ? 20 : 16, vertical: 10),
                child: Row(children: [
                  MarkTile(store.person(c.personId).initials, size: 36, round: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.person(c.personId).name, style: AppTextStyles.bodyLg.copyWith(fontWeight: c.unread ? AppFontWeight.medium : AppFontWeight.regular)),
                      Text(c.request ? 'Message request · ${c.last.text}' : c.last.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(c.last.time, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.gray500)),
                    const SizedBox(height: 4),
                    if (c.unread) const CircleAvatar(radius: 3, backgroundColor: AppColors.blue) else const SizedBox(height: 6),
                  ]),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }
}

class _Thread extends StatefulWidget {
  final String id;
  final bool wide;
  const _Thread({required this.id, required this.wide});

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NetworkStore>().markRead(widget.id));
  }

  @override
  void didUpdateWidget(covariant _Thread old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NetworkStore>().markRead(widget.id));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(NetworkStore store) {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    store.send(widget.id, t);
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 80, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final c = store.conversation(widget.id);
    final p = store.person(c.personId);
    return Column(children: [
      Container(
        height: 64,
        padding: EdgeInsets.only(left: widget.wide ? 24 : 4, right: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
        child: Row(children: [
          if (!widget.wide) IconButton(onPressed: () => context.canPop() ? context.pop() : context.go('/messages'), icon: const Icon(Ionicons.chevron_back, size: 20, color: AppColors.ink)),
          MarkTile(p.initials, size: 36, round: true),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: AppTextStyles.bodyLg), Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
          const Icon(Ionicons.ellipsis_vertical, size: 18, color: AppColors.ink),
        ]),
      ),
      Expanded(
        child: ListView(controller: _scroll, padding: EdgeInsets.symmetric(horizontal: widget.wide ? 24 : 16, vertical: 20), children: [
          if (!c.request)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                const Icon(Ionicons.checkmark, size: 14, color: AppColors.gray500),
                const SizedBox(width: 8),
                Expanded(child: Text(c.about == null ? 'Connected' : 'Connected · About: ${c.about}', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))),
              ]),
            ),
          if (!c.request) const Hairline(),
          const SizedBox(height: 14),
          for (final m in c.messages) _Bubble(m),
          if (c.id == 'c1') const _InterviewRow(),
        ]),
      ),
      if (c.request)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kLine))),
          child: Row(children: [
            Expanded(child: PillButton(label: 'Accept and reply', onPressed: () => store.acceptRequest(c.id))),
            const SizedBox(width: 8),
            PillButton(label: 'Ignore', variant: PillVariant.secondary, full: false, onPressed: () => context.canPop() ? context.pop() : context.go('/messages')),
          ]),
        )
      else
        Container(
          padding: EdgeInsets.fromLTRB(widget.wide ? 24 : 16, 12, widget.wide ? 24 : 16, widget.wide ? 16 : 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: kLine))),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(store),
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'Write a message', hintStyle: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder), isCollapsed: false, contentPadding: const EdgeInsets.symmetric(vertical: 11)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(onTap: () => _send(store), child: const Icon(Ionicons.send_outline, size: 20, color: AppColors.blue)),
          ]),
        ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  const _Bubble(this.m);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: m.mine ? AppColors.blue : AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(m.text, style: AppTextStyles.body.copyWith(height: 1.45, color: m.mine ? AppColors.white : AppColors.ink)),
          ),
          const SizedBox(height: 3),
          Text(m.time, style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.gray500)),
        ]),
      );
}

class _InterviewRow extends StatelessWidget {
  const _InterviewRow();

  @override
  Widget build(BuildContext context) => Container(
        height: 60,
        decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: kLine))),
        child: Row(children: [
          const Icon(Ionicons.calendar_outline, size: 18, color: AppColors.ink),
          const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Interview · Thu 12 Nov, 4:00 pm', style: AppTextStyles.label.copyWith(fontSize: 13)), Text('Video call · Zerodha', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
          LinkText('Details', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Interview details open here.')))),
        ]),
      );
}
