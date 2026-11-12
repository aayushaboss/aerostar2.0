import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../mockData/career_dna/career_dna_level_meta.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../ui/components/components.dart';
import '../../../ui/page_shell.dart';
import '../../../ui/confirmation.dart';
import '../../../ui/tokens.dart';
import '../../../widgets/pill_button.dart';

/// Level complete (B8 confirmation): a blue check, the title, one line, then Back to levels
/// (1 part) and See your report (2 parts, the one yellow button). Sits under the top bar on web.
class CareerDnaSuccessScreen extends StatefulWidget {
  final int level;
  const CareerDnaSuccessScreen({super.key, required this.level});

  @override
  State<CareerDnaSuccessScreen> createState() => _CareerDnaSuccessScreenState();
}

class _CareerDnaSuccessScreenState extends State<CareerDnaSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _checkScale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CareerDnaLevelMeta get _meta => careerDnaLevelMeta.firstWhere((m) => m.level == widget.level);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final last = widget.level == 5;
    final wide = AppBreakpoints.isWide(context);

    final content = ConfirmationBody(
      icon: last ? Ionicons.trophy : Ionicons.checkmark,
      title: 'Level ${meta.level} complete!',
      message: last ? "You've finished the whole Career Quiz journey." : 'Nicely done — your ${meta.title} results are ready.',
      secondaryLabel: last ? 'Back to quiz' : 'Back to levels',
      onSecondary: () => context.go('/tabs/career-dna'),
      primaryLabel: 'See your report',
      onPrimary: () => context.go(last ? '/college/career-dna/final-report' : '/college/career-dna/level/${widget.level}/report'),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: wide
          ? PageShell(contentWidth: ContentWidth.tight, child: Padding(padding: const EdgeInsets.only(top: 88), child: content))
          : SafeArea(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: content)))),
    );
  }
}

// Kept so older imports of the phone button style still resolve.
// ignore: unused_element
typedef _Legacy = PillButton;
