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
import '../../widgets/app_chip.dart';
import '../../widgets/ds.dart';
import '../../widgets/v2.dart';
import '../../ui/components/components.dart';
import '../../ui/page_shell.dart';
import '../../ui/tokens.dart';

/// Network tab: find people and companies, answer invitations. Chat opens once a request is
/// accepted. Replaces the Courses tab of the Pitchvilla app (courses live in the university app).
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NetworkStore>();
    final wide = AppBreakpoints.isExpanded(context);
    if (!wide) return _buildCompact(store);
    return _buildWeb(store);
    final pad = wide ? 24.0 : 20.0;

    var people = store.suggestions;
    if (_filter == 'Recruiters') people = people.where((p) => p.recruiter).toList();
    if (_filter == 'Students') people = people.where((p) => !p.recruiter).toList();

    final invitations = _Invitations(store: store);
    final main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!wide) ...[
          Row(children: [for (final f in ['All', 'Recruiters', 'Students']) Padding(padding: const EdgeInsets.only(right: 6), child: AppChip(label: f, selected: _filter == f, onPressed: () => setState(() => _filter = f)))]),
          if (store.invited.isNotEmpty) invitations,
        ],
        if (wide) _Tabs(count: store.connectionCount, filter: _filter, onFilter: (f) => setState(() => _filter = f)),
        SectionHeading('People you may know', link: wide ? null : 'View all', padding: EdgeInsets.only(top: wide ? 16 : 24, bottom: 4)),
        const Hairline(),
        for (final p in people) _PersonRow(person: p, store: store, wide: wide),
        SectionHeading('Companies', count: store.companies.length, padding: const EdgeInsets.only(top: 28, bottom: 4)),
        const Hairline(),
        for (final c in store.companies) _CompanyRow(company: c, store: store),
        const SizedBox(height: 32),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: WebAlign(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200 + 48),
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
              children: [
                _Header(wide: wide),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: main),
                      const SizedBox(width: 32),
                      Container(width: 300, padding: const EdgeInsets.only(left: 32), decoration: const BoxDecoration(border: Border(left: BorderSide(color: kLine))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [invitations, const _GrowCard()])),
                    ],
                  )
                else
                  main,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _NetworkCompact on _NetworkScreenState {
  /// Minimal v2 phone layout: title with search + messages, text tabs, an invitation card, then
  /// "People you may know" and "Companies" as spaced rows with outlined actions.
  Widget _buildCompact(NetworkStore store) {
    var people = store.suggestions;
    if (_filter == 'Recruiters') people = people.where((p) => p.recruiter).toList();
    if (_filter == 'Students') people = people.where((p) => !p.recruiter).toList();
    final invited = store.invited;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(kPad, 12, 12, 0),
            child: Row(children: [
              Expanded(child: Text('Network', style: AppTextStyles.h1.copyWith(fontSize: 28, letterSpacing: -1.12))),
              const BarIcon(Ionicons.search_outline),
              BarIcon(Ionicons.chatbubble_outline, dot: store.hasUnreadMessages, onTap: () => context.push('/messages')),
            ]),
          ),
          TextTabs(labels: const ['All', 'Recruiters', 'Students'], selected: _filter, onSelect: (f) => setState(() => _filter = f)),
          if (invited.isNotEmpty)
            FillCard(
              margin: const EdgeInsets.fromLTRB(kPad, 24, kPad, 0),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(invited.length == 1 ? '1 invitation' : '${invited.length} invitations', style: AppTextStyles.label.copyWith(color: AppColors.gray500, letterSpacing: 0.24)),
                const SizedBox(height: 14),
                V2Row(mark: Mark8(invited.first.initials, size: 44, round: true, outlined: true), title: invited.first.name, subtitle: invited.first.headline.split(' · ').first),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        store.accept(invited.first.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected with ${invited.first.name}. You can message them now.')));
                      },
                      child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(6)), child: Text('Accept', style: AppTextStyles.bodyLg)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => store.ignore(invited.first.id),
                      child: Container(height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(6)), child: Text('Ignore', style: AppTextStyles.bodyLg.copyWith(color: AppColors.body))),
                    ),
                  ),
                ]),
              ]),
            ),
          V2Section('People you may know', link: 'View all'),
          V2List(children: [
            for (final p in people.take(3))
              V2Row(
                onTap: () => context.push('/person/${p.id}'),
                mark: Mark8(p.initials, size: 44, round: true),
                title: p.name,
                subtitle: p.headline,
                extra: Text('${p.mutual} mutual connections', style: AppTextStyles.caption.copyWith(color: const Color(0xFF8A8A8A))),
                trailing: p.link == LinkState.requested ? const MiniButton('Requested', onTap: null) : MiniButton('Connect', onTap: () => store.connect(p.id)),
              ),
          ], gap: 22),
          V2Section('Companies', link: 'View all'),
          V2List(children: [
            for (final c in store.companies)
              V2Row(
                onTap: () => context.push('/company/${c.id}'),
                mark: Mark8(c.name[0], size: 44),
                title: c.name,
                subtitle: c.line,
                trailing: MiniButton(c.following ? 'Following' : 'Follow', active: !c.following, onTap: () => store.toggleFollow(c.id)),
              ),
          ], gap: 22),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool wide;
  const _Header({required this.wide});

  @override
  Widget build(BuildContext context) {
    final search = FieldWell(
      height: wide ? 40 : 40,
      child: Row(children: [const Icon(Ionicons.search_outline, size: 16, color: AppColors.placeholder), const SizedBox(width: 8), Text(wide ? 'Search people and companies' : 'Search', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.placeholder))]),
    );
    if (wide) {
      return Padding(
        padding: const EdgeInsets.only(top: 32, bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Network', style: AppTextStyles.display), const SizedBox(height: 6), Text('Find people and companies. Chat opens once a request is accepted.', style: AppTextStyles.body.copyWith(color: AppColors.body))])),
          SizedBox(width: 360, child: search),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 48,
          child: Row(children: [
            Expanded(child: Text('Network', style: AppTextStyles.h1)),
            _IconBtn(icon: Ionicons.chatbubble_outline, dot: context.watch<NetworkStore>().hasUnreadMessages, onTap: () => context.push('/messages')),
          ]),
        ),
        const SizedBox(height: 4),
        search,
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool dot;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(alignment: Alignment.center, children: [
            Icon(icon, size: 20, color: AppColors.ink),
            if (dot) const Positioned(top: 8, right: 9, child: CircleAvatar(radius: 3, backgroundColor: AppColors.error)),
          ]),
        ),
      );
}

class _Tabs extends StatelessWidget {
  final int count;
  final String filter;
  final ValueChanged<String> onFilter;
  const _Tabs({required this.count, required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    Widget tab(String n, String l, bool on, bool first) => Container(
          width: 170,
          padding: const EdgeInsets.fromLTRB(16, 12, 0, 14),
          decoration: BoxDecoration(border: Border(left: first ? BorderSide.none : const BorderSide(color: kLine), bottom: BorderSide(color: on ? AppColors.blue : Colors.transparent, width: 2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n, style: AppTextStyles.h1.copyWith(fontSize: on ? 22 : 28, fontFeatures: const [FontFeature.tabularFigures()])),
            Text(l, style: AppTextStyles.label.copyWith(fontSize: 13, color: on ? AppColors.blue : AppColors.gray500)),
          ]),
        );
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kLine))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        tab('$count', 'Connections', false, true),
        tab('36', 'Following', false, false),
        tab('People', 'Discover', true, false),
        const Spacer(),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [for (final f in ['All', 'Recruiters', 'Students']) Padding(padding: const EdgeInsets.only(left: 6), child: AppChip(label: f, selected: filter == f, onPressed: () => onFilter(f)))])),
      ]),
    );
  }
}

class _Invitations extends StatelessWidget {
  final NetworkStore store;
  const _Invitations({required this.store});

  @override
  Widget build(BuildContext context) {
    final list = store.invited;
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeading('Invitations', count: list.length, padding: const EdgeInsets.only(top: 24, bottom: 4)),
      const Hairline(),
      for (final p in list)
        HairlineRow(
          minHeight: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              MarkTile(p.initials, size: 40, round: true),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: AppTextStyles.bodyLg), Text(p.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
              const SizedBox(width: 8),
              LinkText('Accept', onTap: () {
                store.accept(p.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected with ${p.name}. You can message them now.')));
              }),
              const SizedBox(width: 16),
              LinkText('Ignore', color: AppColors.gray500, onTap: () => store.ignore(p.id)),
            ]),
          ),
        ),
    ]);
  }
}

class _GrowCard extends StatelessWidget {
  const _GrowCard();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grow your network', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Connect with recruiters at companies you applied to. Students with 50+ connections get 2× more profile views.', style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, height: 1.45)),
        ]),
      );
}

class _PersonRow extends StatelessWidget {
  final Person person;
  final NetworkStore store;
  final bool wide;
  const _PersonRow({required this.person, required this.store, required this.wide});

  @override
  Widget build(BuildContext context) {
    final requested = person.link == LinkState.requested;
    return HairlineRow(
      minHeight: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          MarkTile(person.initials, size: 40, round: true),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(person.name, style: AppTextStyles.bodyLg), Text(person.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500)), if (!wide) Text('${person.mutual} mutual', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
          if (wide) SizedBox(width: 110, child: Text('${person.mutual} mutual', textAlign: TextAlign.left, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.body, fontFeatures: const [FontFeature.tabularFigures()]))),
          const SizedBox(width: 8),
          SizedBox(
            width: wide ? 100 : null,
            child: Align(
              alignment: Alignment.centerRight,
              widthFactor: wide ? null : 1,
              child: requested
                  ? Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Ionicons.checkmark, size: 14, color: AppColors.gray500), const SizedBox(width: 4), Text('Requested', style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.gray500))])
                  : LinkText('Connect', onTap: () => store.connect(person.id)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  final Company company;
  final NetworkStore store;
  const _CompanyRow({required this.company, required this.store});

  @override
  Widget build(BuildContext context) => HairlineRow(
        minHeight: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            MarkTile(company.name[0], size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(company.name, style: AppTextStyles.bodyLg), Text(company.line, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption.copyWith(color: AppColors.gray500))])),
            LinkText(company.following ? 'Following' : 'Follow', color: company.following ? AppColors.gray500 : AppColors.blue, onTap: () => store.toggleFollow(company.id)),
          ]),
        ),
      );
}

extension _NetworkWeb on _NetworkScreenState {
  /// Desktop (B2 directory): plain stats row, plain-text tabs, people as a 4-column card grid,
  /// companies as a 3-column grid. Invitations live in the rail with wrapped text and the actions
  /// on a line below.
  Widget _buildWeb(NetworkStore store) {
    var people = store.suggestions;
    if (_filter == 'Recruiters') people = people.where((p) => p.recruiter).toList();
    if (_filter == 'Students') people = people.where((p) => !p.recruiter).toList();

    Widget stat(String n, String l) => Padding(
          padding: const EdgeInsets.only(right: Ui.s48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n, style: Ui.innerTitle.copyWith(fontFeatures: const [FontFeature.tabularFigures()])), const SizedBox(height: 2), Text(l, style: Ui.meta)]),
        );

    Widget grid(int cols, List<Widget> items) => LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - Ui.gridGap * (cols - 1)) / cols;
          return Wrap(spacing: Ui.gridGap, runSpacing: Ui.gridGap, children: [for (final i in items) SizedBox(width: w, child: i)]);
        });

    final peopleCards = [
      for (final p in people)
        UiCard(
          onTap: () => context.push('/person/${p.id}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Avatar(p.initials, round: true, size: 48),
            const SizedBox(height: Ui.s12),
            Text(p.name, style: Ui.rowTitle),
            const SizedBox(height: 2),
            Text(p.headline, style: Ui.meta),
            const SizedBox(height: Ui.s4),
            Text('${p.mutual} mutual connections', style: Ui.label.copyWith(color: Ui.tertiary)),
            const SizedBox(height: Ui.s16),
            p.link == LinkState.requested ? Text('Requested', style: Ui.meta) : UiButton('Connect', compact: true, onTap: () => store.connect(p.id)),
          ]),
        ),
    ];
    final companyCards = [
      for (final c in store.companies)
        UiCard(
          onTap: () => context.push('/company/${c.id}'),
          child: Row(children: [
            Expanded(child: ListRow(mark: c.name[0], title: c.name, meta: c.line, wrap: true)),
            const SizedBox(width: Ui.s12),
            UiButton(c.following ? 'Following' : 'Follow', compact: true, kind: c.following ? UiButtonKind.tertiary : UiButtonKind.secondary, onTap: () => store.toggleFollow(c.id)),
          ]),
        ),
    ];

    final invited = store.invited;
    final rail = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(invited.isEmpty ? 'No invitations' : (invited.length == 1 ? '1 invitation' : '${invited.length} invitations'), style: Ui.sectionHeading),
      const SizedBox(height: Ui.headingToContent),
      for (final p in invited)
        Padding(
          padding: const EdgeInsets.only(bottom: Ui.betweenRows),
          child: ListRow(
            wrap: true,
            round: true,
            mark: p.initials,
            title: p.name,
            meta: p.headline,
            action: Row(children: [
              UiButton('Accept', kind: UiButtonKind.primary, compact: true, onTap: () {
                store.accept(p.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected with ${p.name}. You can message them now.')));
              }),
              const SizedBox(width: Ui.s8),
              UiButton('Ignore', kind: UiButtonKind.tertiary, compact: true, onTap: () => store.ignore(p.id)),
            ]),
          ),
        ),
      const SizedBox(height: Ui.s16),
      const Text('Grow your network', style: Ui.rowTitle),
      const SizedBox(height: Ui.s8),
      const Text('Connect with recruiters at companies you applied to. Students with 50+ connections get 2x more profile views.', style: Ui.meta),
    ]);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageShell(
        rail: rail,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const PageHeader(title: 'Network', subtitle: 'Find people and companies. Chat opens once a request is accepted.'),
          Row(children: [stat('${store.connectionCount}', 'Connections'), stat('36', 'Following'), stat('${store.people.where((p) => p.link == LinkState.requested).length}', 'Requested')]),
          const SizedBox(height: Ui.s28),
          UiTabs(labels: const ['All', 'Recruiters', 'Students'], selected: _filter, onSelect: (f) => setState(() => _filter = f)),
          const SectionHeader('People you may know', top: Ui.s28),
          grid(4, peopleCards),
          const SectionHeader('Companies'),
          grid(3, companyCards),
        ]),
      ),
    );
  }
}
