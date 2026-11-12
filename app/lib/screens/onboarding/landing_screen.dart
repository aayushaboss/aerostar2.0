import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nav.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/brand.dart';
import '../../ui/onboarding_split.dart';
import '../../ui/tokens.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/responsive_body.dart';

const _heroImage = 'assets/images/landing-hero.png';

/// Single landing + auth screen: one hero, a 2-line headline, Google / phone sign-in and a link
/// for returning users. The photo bleeds edge to edge and fades into the Aerostar blue panel
/// below it. On a desktop window the photo takes the left half and the sign-in panel the right.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _googleLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final appState = context.read<AppState>();
      final user = await appState.mockGoogleSignIn();
      if (!mounted) return;
      context.go(routeForUser(user));
    } catch (_) {
      // mockGoogleSignIn is assumed to always succeed today; once real auth lands this is where a
      // genuine failure (network, cancelled consent) has to surface instead of silently resetting.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("That didn't go through — let's try again."),
          action: SnackBarAction(label: 'Retry', textColor: AppColors.yellow, onPressed: _continueWithGoogle),
          duration: const Duration(seconds: 4),
          // See sessions_screen.dart's own note on `persist`.
          persist: false,
        ),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  // No `mode` query param: LoginScreen's own default is the phone field.
  void _continueWithPhone() {
    // Without this, tapping Phone right after Google (before the mock sign-in resolves) let the
    // delayed Google callback navigate away from whatever the user is now doing on the login screen.
    if (_googleLoading) return;
    context.push('/auth/login');
  }

  void _goToReturningLogin() => context.push('/auth/login?returning=1');

  Widget _actions({required bool onBlue}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            label: 'Continue with Google',
            // Google's "G" has its own yellow segment, which vanishes against the yellow CTA, so a
            // white badge behind it keeps the mark legible.
            iconWidget: Container(
              decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: SvgPicture.asset('assets/icons/google.svg'),
            ),
            loading: _googleLoading,
            onPressed: _continueWithGoogle,
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PillButton(
              label: 'Continue with phone number',
              variant: onBlue ? PillVariant.outlineWhite : PillVariant.secondary,
              icon: Ionicons.call_outline,
              disabled: _googleLoading,
              onPressed: _continueWithPhone,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: _goToReturningLogin,
              // The padding lives inside the tap target: the one other action on the screen would
              // otherwise be sized to its own text line, next to two full 44px pill buttons.
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
                child: Text(
                  noOrphan('Already have an account? Log in'),
                  style: AppTextStyles.body.copyWith(color: onBlue ? AppColors.white : AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _headline({double size = 32, required bool onBlue}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('For students, graduates and employers across India', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your future job\nis looking for you too.',
            style: AppTextStyles.display.copyWith(color: AppColors.ink, fontSize: size, letterSpacing: -size * 0.04, height: 1.05),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md - 4),
            child: Text(
              noOrphan('Apply to internships and jobs, build an ATS-ready resume with AI, and network with people and companies.'),
              style: AppTextStyles.body.copyWith(color: AppColors.body, fontSize: size > 32 ? 16 : 14, height: 1.45),
            ),
          ),
        ],
      );

  /// The photo, inset with 6px corners on a white page (no full-bleed, no gradient).
  Widget _hero() => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.asset(_heroImage, fit: BoxFit.cover, width: double.infinity, height: double.infinity));

  /// Desktop and tablet: the shared two-column onboarding frame. Left: eyebrow, headline,
  /// subtitle, buttons, login link. Right: the photo, filling the panel.
  Widget _desktop() {
    return OnboardingSplit(
      footer: '© 2026 Aerostar Edge',
      content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('For students, graduates and employers across India', style: Ui.meta),
        const SizedBox(height: Ui.s12),
        Text('Your future job is looking for you too.', style: Ui.pageTitle.copyWith(fontSize: 48, height: 1.05, letterSpacing: -1.92)),
        const SizedBox(height: Ui.s16),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Text('Apply to internships and jobs, build an ATS-ready resume with AI, and network with people and companies.', style: Ui.body.copyWith(fontSize: 16, color: const Color(0xFF3F3F46), height: 1.5))),
        const SizedBox(height: Ui.s32),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PillButton(
              label: 'Continue with Google',
              height: 48,
              iconWidget: Container(decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle), padding: const EdgeInsets.all(AppSpacing.xs), child: SvgPicture.asset('assets/icons/google.svg')),
              loading: _googleLoading,
              onPressed: _continueWithGoogle,
            ),
            const SizedBox(height: Ui.s12),
            PillButton(label: 'Continue with phone number', height: 48, variant: PillVariant.secondary, icon: Ionicons.call_outline, disabled: _googleLoading, onPressed: _continueWithPhone),
          ]),
        ),
        const SizedBox(height: Ui.s16),
        GestureDetector(
          onTap: _goToReturningLogin,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(cursor: SystemMouseCursors.click, child: Text('Already have an account? Log in', style: Ui.body.copyWith(color: Ui.blue, fontWeight: FontWeight.w500, height: 1.2))),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 600) {
      return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: Scaffold(backgroundColor: AppColors.white, body: _desktop()));
    }
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final expanded = AppBreakpoints.isExpanded(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: expanded
            ? SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(64, 32, 32, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Wordmark(size: 26),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 520),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _headline(size: 52, onBlue: false),
                                      const SizedBox(height: AppSpacing.xl),
                                      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: _actions(onBlue: false)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(padding: const EdgeInsets.only(top: 16), width: double.infinity, decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))), child: Text('© 2026 Aerostar Edge', style: AppTextStyles.caption.copyWith(color: AppColors.gray500))),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 5, child: Padding(padding: const EdgeInsets.fromLTRB(0, 24, 24, 24), child: _hero())),
                  ],
                ),
              )
            : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 640 : AppBreakpoints.maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottomInset > 0 ? 0 : AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Wordmark(size: 20),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(height: screenHeight * 0.34, width: double.infinity, child: _hero()),
                          const SizedBox(height: AppSpacing.lg),
                          _headline(onBlue: false),
                          const Spacer(),
                          _actions(onBlue: false),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
