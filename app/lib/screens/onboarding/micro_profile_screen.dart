import 'package:flutter/material.dart';
import '../../ui/onboarding_split.dart';
import '../../ui/tokens.dart';
import '../../ui/components/components.dart' show UiProgress;
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../mockData/mock_profile_options.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/desktop_field_row.dart';
import '../../widgets/field_label.dart';
import '../../widgets/onboarding_progress.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/onboarding_frame.dart';

const _maxPhoneDigits = 15;

const _qualificationOptions = ['Below 10th', '10th pass', '12th pass', 'Diploma', 'Graduate', 'Postgraduate'];

/// (segment, title, one-line description, icon) for the "which best describes you" cards.
const _segmentOptions = [
  (Segment.ug, 'Undergraduate', "Diploma or bachelor's", Ionicons.book_outline),
  (Segment.pg, 'Postgraduate', "Master's degree", Ionicons.ribbon_outline),
  (Segment.working, 'Working professional', 'Already employed', Ionicons.briefcase_outline),
];

/// One screen instead of a per-question quiz: whatever the mocked Google
/// sign-in already handed back (name, city) shows up pre-filled at the top
/// — with a progress bar proving it — and only the handful of things
/// Google could never know (segment, and — for Working — a qualification
/// chip) need actual typing. The "Continue with Email" path lands here too,
/// just without anything pre-filled, using the exact same fields.
///
/// Deliberately minimal: this screen only hard-gates what's needed to
/// personalize the very first feed — name, city, segment, and Working's
/// qualification. Everything else (class/board, college/course/semester,
/// work history) is asked later via the Profile tab's "Basic info"
/// checklist item (profile_readiness.dart), not here.
class MicroProfileScreen extends StatefulWidget {
  const MicroProfileScreen({super.key});

  @override
  State<MicroProfileScreen> createState() => _MicroProfileScreenState();
}

class _MicroProfileScreenState extends State<MicroProfileScreen> {
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  String? _signInMethod;
  // Captured alongside _signInMethod in _hydrateFromUser — the exact
  // signal (already used the same way in otp_screen.dart/booking_screen.
  // dart) for whether this account still needs a phone number asked: a
  // phone sign-up's identifier never contains '@', a Google or email
  // sign-up's always does.
  String _identifier = '';
  String _city = '';
  Segment? _segment;
  String _highestQualification = '';
  bool _loading = false;
  bool _hydrated = false;

  // Anchors for the two questions that sit below the fold, so the screen can
  // scroll itself to them instead of making the student hunt for the next step.
  final _stageKey = GlobalKey();
  final _qualificationKey = GlobalKey();
  bool _stageRevealed = false;

  bool get _isSchool => _segment == Segment.school;
  bool get _isWorking => _segment == Segment.working;

  /// Phone sign-up's identifier already is a phone number (auto-filled in
  /// AppState._makeNewUser) — only Google/email sign-ups still need to be
  /// asked here.
  bool get _needsPhone => _identifier.contains('@');

  /// Same 10-15-digit bound already established in login_screen.dart's own
  /// `_valid` getter, reused here rather than inventing a new one.
  bool get _isValidPhone {
    final digits = _phoneController.text.trim();
    return digits.length >= 10 && digits.length <= _maxPhoneDigits;
  }

  // City is free-text (AutocompleteField), unlike the chip-selected fields
  // below it — trimming before every emptiness check on it (matching how
  // Name already does) stops a whitespace-only entry from counting as
  // "filled" and slipping into the saved profile.
  List<bool> get _filled {
    final base = [
      _nameController.text.trim().isNotEmpty,
      _city.trim().isNotEmpty,
      if (_needsPhone) _isValidPhone,
      _segment != null,
    ];
    if (_isWorking) return [...base, _highestQualification.isNotEmpty];
    return base;
  }

  double get _progress => _filled.where((f) => f).length / _filled.length;

  /// What is still needed while Continue is off, so the button never just sits there greyed out.
  String? get _missingHint {
    if (_canContinue) return null;
    if (_nameController.text.trim().isEmpty) return 'Enter your name to continue';
    if (_city.trim().isEmpty) return 'Add your city to continue';
    if (_needsPhone && !_isValidPhone) return 'Enter a valid 10-digit phone number to continue';
    if (_segment == null) return 'Choose which best describes you to continue';
    if (_isWorking && _highestQualification.isEmpty) return 'Choose your highest level completed to continue';
    return null;
  }

  bool get _canContinue {
    if (_nameController.text.trim().isEmpty || _city.trim().isEmpty || _segment == null) return false;
    if (_needsPhone && !_isValidPhone) return false;
    if (_isWorking) return _highestQualification.isNotEmpty;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  // Runs once real BuildContext/Provider access is available — can't read
  // the just-signed-in user's prefilled name/city from initState.
  void _hydrateFromUser(User? user) {
    if (_hydrated || user == null) return;
    _hydrated = true;
    _nameController.text = user.name ?? '';
    _city = user.city ?? '';
    _phoneController.text = user.phone ?? '';
    _signInMethod = user.signInMethod;
    _identifier = user.identifier;
    // Only restored on a genuine re-visit (segment already set) — treats
    // "Goals has nothing to pop, falls back to context.go('/onboarding/
    // profile')" as resuming an edit, not starting fresh.
    if (user.segment != null) {
      _segment = user.segment;
      _highestQualification = user.highestQualification ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Smoothly brings a question into view once it has been laid out.
  void _scrollTo(GlobalKey key, {double alignment = 0.04}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(ctx, alignment: alignment, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    });
  }

  /// Once the name/city/phone above are done, take the student to "which best
  /// describes you?" (once, so it never fights a manual scroll).
  void _revealStageIfReady() {
    if (_stageRevealed || _segment != null) return;
    if (_city.trim().isEmpty || (_needsPhone && !_isValidPhone)) return;
    _stageRevealed = true;
    _scrollTo(_stageKey);
  }

  void _selectSegment(Segment s) {
    HapticFeedback.selectionClick();
    setState(() {
      // Switching away from Working leaves the qualification chip selected
      // but hidden — clear it so a change of mind doesn't silently carry a
      // stale value into the submitted profile.
      if (s != Segment.working) _highestQualification = '';
      _segment = s;
    });
    // Working reveals the follow-up question below the cards: scroll to it.
    if (s == Segment.working) _scrollTo(_qualificationKey, alignment: 0.1);
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
  }

  Future<void> _submit() async {
    if (!_canContinue) return;
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final isSchool = _isSchool;
      await appState.updateProfile((current) => current.copyWith(
            name: _nameController.text.trim(),
            city: _city.trim(),
            phone: _needsPhone ? _phoneController.text.trim() : null,
            segment: _segment,
            highestQualification: _isWorking ? _highestQualification : null,
            // School's required profile is complete right here — aptitude is optional after this.
            onboardingComplete: isSchool ? true : null,
            aptitudeSkipped: isSchool ? true : null,
          ));
      if (!mounted) return;
      // School's required profile is now the final onboarding step, so it
      // gets the same completion acknowledgment college/UG/PG/working get
      // after Goals — see onboarding_complete_screen.dart.
      context.go(isSchool ? '/onboarding/complete' : '/college/goals');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// A field's existing FieldLabel + input, unchanged, just grouped so it
  /// can be handed to DesktopFieldRow's left/right slots as one unit.
  Widget _fieldGroup(Widget label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [label, field],
    );
  }

  @override
  Widget build(BuildContext context) {
    _hydrateFromUser(context.read<AppState>().user);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    if (MediaQuery.sizeOf(context).width >= OnboardingSplit.stackBelow) {
      return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.dark, child: Scaffold(backgroundColor: AppColors.white, body: OnboardingSplit(footer: "India's Startup Talent Network", contentMaxWidth: 560, content: _desktopForm())));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: OnboardingFrame(maxWidth: 640, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(onTap: _back, child: const Icon(Ionicons.chevron_back, size: 26, color: AppColors.ink)),
                  Expanded(
                    child: Text(
                      'Complete your profile',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
            // Whole-flow progress, shared with the Goals step: school students finish here
            // (1 of 1), everyone else still has Goals to go (1 of 2), so this never says
            // 100% while a step remains.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: OnboardingProgress(step: 1, totalSteps: _isSchool ? 1 : 2, stepFill: _progress),
            ),
            Expanded(
              child: SingleChildScrollView(
                // Generous bottom padding — not just cosmetic. Whenever this
                // screen's content is shorter than the viewport (common,
                // since it's only 3-5 fields), the scroll view has nothing
                // to scroll *to*, so the fixed Continue bar right below reads
                // as glued to the last field with only the old xl (20px) gap.
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tied to signInMethod, not just "is some field
                    // non-empty" — the old check couldn't tell an actually
                    // Google-prefilled field apart from one that happened
                    // to be non-empty for an unrelated reason, so it could
                    // claim a Google pull that never happened. Email/phone
                    // sign-in never gets a city (nothing to derive it
                    // from), so that variant only ever talks about the name.
                    if (_signInMethod == 'google')
                      _AutofillBanner(text: 'Pulled from your Google account — edit anytime.')
                    else if (_signInMethod == 'otp' && _nameController.text.trim().isNotEmpty)
                      _AutofillBanner(text: "We've filled in your name from your email — edit anytime."),
                    if (isTablet)
                      DesktopFieldRow(
                        left: _fieldGroup(
                          const FieldLabel('Full name', tight: true),
                          PillInput(controller: _nameController, placeholder: 'Your name', icon: Ionicons.person_outline, maxLength: 60, onChanged: (_) => setState(() {})),
                        ),
                        right: _fieldGroup(
                          const FieldLabel('City', tight: true),
                          AutocompleteField(
                            value: _city,
                            placeholder: 'e.g. Mumbai',
                            icon: Ionicons.location_outline,
                            options: mockCities,
                            onChanged: (v) => setState(() => _city = v),
                            // Only onSubmitted (never onSelected): AutocompleteField treats onSelected as
                            // "commit and clear", which wiped the city the moment it was picked.
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              _revealStageIfReady();
                            },
                          ),
                        ),
                      )
                    else ...[
                      const FieldLabel('Full name', tight: true),
                      PillInput(controller: _nameController, placeholder: 'Your name', icon: Ionicons.person_outline, maxLength: 60, onChanged: (_) => setState(() {})),
                      const FieldLabel('City'),
                      AutocompleteField(
                        value: _city,
                        placeholder: 'e.g. Mumbai',
                        icon: Ionicons.location_outline,
                        options: mockCities,
                        onChanged: (v) => setState(() => _city = v),
                        // Only onSubmitted (never onSelected): AutocompleteField treats onSelected as
                        // "commit and clear", which wiped the city the moment it was picked.
                        onSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                          _revealStageIfReady();
                        },
                      ),
                    ],
                    // Only Google/email sign-ups reach here — phone sign-up's
                    // identifier already is the phone number (see
                    // AppState._makeNewUser), so asking again here would be
                    // redundant.
                    if (_needsPhone) ...[
                      const FieldLabel('Phone number'),
                      PillInput(
                        controller: _phoneController,
                        placeholder: '9876543210',
                        icon: Ionicons.call_outline,
                        keyboardType: TextInputType.phone,
                        // Stops at 15 digits (the longest number accepted); it used to take any
                        // length, and a too-long number silently kept Continue switched off.
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_maxPhoneDigits)],
                        error: _phoneController.text.isNotEmpty && !_isValidPhone ? 'Enter a valid phone number (10 digits)' : null,
                        onChanged: (_) {
                          setState(() {});
                          if (_isValidPhone) _revealStageIfReady();
                        },
                      ),
                    ],
                    Padding(
                      key: _stageKey,
                      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.lg),
                      child: Text(
                        'Which best describes you?',
                        style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold),
                      ),
                    ),
                    // Two by two on a tablet, one per row on a phone.
                    LayoutBuilder(
                      builder: (context, box) {
                        final cardWidth = isTablet ? (box.maxWidth - AppSpacing.md) / 2 : box.maxWidth;
                        return Wrap(
                          spacing: AppSpacing.md - 4,
                          runSpacing: AppSpacing.md - 4,
                          children: [
                            for (final s in _segmentOptions)
                              SizedBox(
                                width: cardWidth,
                                child: _StageCard(
                                  title: s.$2,
                                  description: s.$3,
                                  icon: s.$4,
                                  selected: _segment == s.$1,
                                  onTap: () => _selectSegment(s.$1),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    // The one and only follow-up question — everything else
                    // (class/board, college/course/semester, work history)
                    // is asked later via Profile's "Basic info" checklist,
                    // not here. See this class's own doc comment.
                    if (_isWorking) ...[
                      KeyedSubtree(key: _qualificationKey, child: const FieldLabel("What's the highest level you've completed?")),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _qualificationOptions
                            .map((o) => AppChip(
                                  label: o,
                                  selected: _highestQualification == o,
                                  onPressed: () => setState(() => _highestQualification = o),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_missingHint != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        _missingHint!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                      ),
                    ),
                  PillButton(label: 'Continue', onPressed: _canContinue ? _submit : null, loading: _loading, disabled: !_canContinue),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

/// One answer to "which best describes you": icon badge, title, a one-line
/// description and a check when chosen. Same selection language as the Goals
/// tiles and AppChip (neutral fill, white + 2px yellow stroke when selected),
/// so yellow only marks the chosen answer.
/// One answer to "which best describes you": 72px tall, 1px outline and 8px radius, a plain 20px
/// icon, title and one-line description. Selected: 1.5px blue border, pale blue fill, blue icon.
class _StageCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _StageCard({required this.title, required this.description, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $description',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF6F8FF) : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? AppColors.blue : const Color(0xFFE8E8E6), width: selected ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: selected ? AppColors.blue : const Color(0xFF3F3F46)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyLg.copyWith(fontSize: 15, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.gray500)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AutofillBanner extends StatelessWidget {
  final String text;
  const _AutofillBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          const Icon(Ionicons.checkmark_circle, size: 18, color: AppColors.blue),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              noOrphan(text),
              style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
            ),
          ),
        ],
      ),
    );
  }
}

extension _MicroProfileDesktop on _MicroProfileScreenState {
  /// Desktop form (960px and up): header row, progress bar, Google notice, two-column fields,
  /// two-column options, and a footer with helper text and Continue, all inside the right panel.
  Widget _desktopForm() {
    final total = _isSchool ? 1 : 2;
    Widget label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12)));
    final nameField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('Full name'),
      PillInput(controller: _nameController, placeholder: 'Your name', icon: Ionicons.person_outline, maxLength: 60, height: 48, onChanged: (_) => setState(() {})),
    ]);
    final cityField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('City'),
      AutocompleteField(
        value: _city,
        placeholder: 'e.g. Mumbai',
        icon: Ionicons.location_outline,
        options: mockCities,
        inputHeight: 48,
        onChanged: (v) => setState(() => _city = v),
        onSubmitted: (_) {
          FocusScope.of(context).unfocus();
          _revealStageIfReady();
        },
      ),
    ]);
    final phoneField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      label('Phone number'),
      PillInput(
        controller: _phoneController,
        placeholder: '9876543210',
        icon: Ionicons.call_outline,
        keyboardType: TextInputType.phone,
        height: 48,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_maxPhoneDigits)],
        error: _phoneController.text.isNotEmpty && !_isValidPhone ? 'Enter a valid phone number (10 digits)' : null,
        onChanged: (_) {
          setState(() {});
          if (_isValidPhone) _revealStageIfReady();
        },
      ),
    ]);
    final notice = _signInMethod == 'google'
        ? 'Pulled from your Google account — edit anytime.'
        : (_signInMethod == 'otp' && _nameController.text.trim().isNotEmpty ? "We've filled in your name from your email — edit anytime." : null);

    return Padding(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            GestureDetector(onTap: _back, behavior: HitTestBehavior.opaque, child: const SizedBox(width: 32, height: 32, child: Icon(Ionicons.chevron_back, size: 22, color: Ui.ink))),
            const SizedBox(width: Ui.s8),
            const Expanded(child: Text('Complete your profile', style: Ui.sectionHeading)),
            Text('Step 1 of $total', style: Ui.meta),
          ]),
          const SizedBox(height: Ui.s12),
          UiProgress(((0) + _progress.clamp(0.0, 1.0)) / total < 0.04 ? 0.04 : (0 + _progress.clamp(0.0, 1.0)) / total),
          if (notice != null) ...[
            const SizedBox(height: Ui.s24),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: Ui.s12),
              decoration: BoxDecoration(color: Ui.highlightBg, borderRadius: BorderRadius.circular(Ui.rField)),
              child: Row(children: [const Icon(Ionicons.checkmark_circle, size: 16, color: Ui.blue), const SizedBox(width: Ui.s8), Expanded(child: Text(notice, style: Ui.meta.copyWith(color: Ui.blue)))]),
            ),
          ],
          const SizedBox(height: Ui.s28),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: nameField), const SizedBox(width: Ui.s16), Expanded(child: cityField)]),
          if (_needsPhone) ...[const SizedBox(height: Ui.s20), phoneField],
          Padding(key: _stageKey, padding: const EdgeInsets.only(top: Ui.s32, bottom: Ui.s12), child: const Text('Which best describes you?', style: Ui.rowTitle)),
          LayoutBuilder(builder: (context, box) {
            final w = (box.maxWidth - Ui.s12) / 2;
            return Wrap(spacing: Ui.s12, runSpacing: Ui.s12, children: [
              for (final s in _segmentOptions) SizedBox(width: w, child: _StageCard(title: s.$2, description: s.$3, icon: s.$4, selected: _segment == s.$1, onTap: () => _selectSegment(s.$1))),
            ]);
          }),
          if (_isWorking) ...[
            Padding(key: _qualificationKey, padding: const EdgeInsets.only(top: Ui.s24, bottom: Ui.s12), child: const Text("What's the highest level you've completed?", style: Ui.rowTitle)),
            Wrap(spacing: Ui.s8, runSpacing: Ui.s8, children: [for (final o in _qualificationOptions) AppChip(label: o, selected: _highestQualification == o, onPressed: () => setState(() => _highestQualification = o))]),
          ],
          const SizedBox(height: Ui.s32),
          if (_missingHint != null) Padding(padding: const EdgeInsets.only(bottom: Ui.s8), child: Text(_missingHint!, style: Ui.meta)),
          PillButton(label: 'Continue', height: 48, onPressed: _canContinue ? _submit : null, loading: _loading, disabled: !_canContinue),
        ]),
      ),
    );
  }
}
