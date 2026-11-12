import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../ui/confirmation.dart';

/// "You're all set": the shared confirmation page (logo top-left, confirmation centred with the
/// button directly under the message, footer bottom-left).
class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppState>().user?.name?.trim();
    final firstName = (name != null && name.isNotEmpty) ? name.split(' ').first : null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ConfirmationPage(
        body: ConfirmationBody(
          title: firstName != null ? "You're all set, $firstName!" : "You're all set!",
          message: "Your profile is ready.\nLet's find your next opportunity.",
          primaryLabel: "Let's go",
          primaryIcon: Ionicons.arrow_forward,
          onPrimary: () {
            context.read<AppState>().markJustOnboarded();
            context.go('/tabs');
          },
        ),
      ),
    );
  }
}
