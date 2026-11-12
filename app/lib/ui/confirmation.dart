import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../widgets/brand.dart';
import 'components/components.dart';
import 'tokens.dart';

/// The confirmation block shared by every "done" screen (all set, level complete, booking
/// confirmed): a 72px blue circle with a check, a 32px title, one line, an optional info block,
/// then the button(s) directly under it. Content is centred in a column of at most 400px.
class ConfirmationBody extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? extra;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final IconData? primaryIcon;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final double maxWidth;

  const ConfirmationBody({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.icon = Ionicons.checkmark,
    this.extra,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.maxWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final primary = UiButton(primaryLabel, kind: UiButtonKind.primary, expand: true, icon: primaryIcon, iconAfter: true, onTap: onPrimary);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 72, height: 72, alignment: Alignment.center, decoration: const BoxDecoration(color: Ui.blue, shape: BoxShape.circle), child: Icon(icon, size: 32, color: Colors.white)),
        const SizedBox(height: Ui.s28),
        Text(title, textAlign: TextAlign.center, style: Ui.pageTitle),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: Ui.body.copyWith(fontSize: 15, color: Ui.secondary, height: 1.6)),
        if (extra != null) ...[const SizedBox(height: Ui.s24), SizedBox(width: double.infinity, child: extra)],
        const SizedBox(height: 36),
        if (secondaryLabel != null)
          Row(children: [Expanded(child: UiButton(secondaryLabel!, expand: true, onTap: onSecondary)), const SizedBox(width: Ui.s8), Expanded(flex: 2, child: primary)])
        else
          primary,
      ]),
    );
  }
}

/// Standalone full page version: logo pinned top-left, the confirmation centred, the footer line
/// pinned bottom-left. The button sits under the message, not at the window edge.
class ConfirmationPage extends StatelessWidget {
  final ConfirmationBody body;
  final String footer;
  const ConfirmationPage({super.key, required this.body, this.footer = "India's Startup Talent Network"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, box) {
        final side = Ui.sidePad(box.maxWidth);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: side, vertical: Ui.s48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Wordmark(size: 30),
            Expanded(child: Center(child: SingleChildScrollView(child: body))),
            Text(footer, style: Ui.meta),
          ]),
        );
      }),
    );
  }
}
