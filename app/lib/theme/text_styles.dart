import 'package:flutter/material.dart';

/// Sole UI typeface — no other font is used anywhere in this app.
const String kFontFamily = 'Inter';

/// ₹ and a few symbols fall back to Poppins if a glyph is ever missing.
const List<String> kFontFallback = ['Poppins'];

/// Mirrors frontend/src/theme.ts `font` (numeric weights used with Poppins).
class AppFontWeight {
  AppFontWeight._();

  static const black = FontWeight.w500;
  static const extrabold = FontWeight.w500;
  // Capped at w600 to match a live audit of Internshala's mobile site
  // (internshala.com at a 375px viewport, computed styles read directly):
  // their heaviest weight anywhere — job-card titles, detail-page hero
  // titles, section headings, primary buttons — is 600. Nothing goes to
  // 700+. Hierarchy there comes from SIZE (14 card title / 16 section
  // heading / 18 detail hero) plus color (dark ink vs. gray), not from an
  // extra weight step, so collapsing bold onto semibold here doesn't lose
  // hierarchy — the size scale below already carries it.
  static const bold = FontWeight.w500;
  static const semibold = FontWeight.w500;
  /// The single key number on a screen (stipend, score) is the only 600.
  static const number = FontWeight.w600;
  static const medium = FontWeight.w500;
  static const regular = FontWeight.w400;
}

/// Mirrors frontend/src/theme.ts `type` scale.
/// Sizes and weights re-audited directly against Internshala's mobile site
/// (computed styles at a 375px viewport): job-card title 14px/600 ink,
/// company name 13px/500 gray (rounded to our 12px floor), meta text
/// 14px/500 gray, section heading 16px/600, detail-page hero title
/// 18px/600, primary button label 14px/600. Nothing on their site goes
/// past 18px or past weight 600 — hierarchy is carried by a narrow size
/// ladder (14 → 16 → 18) plus color (dark ink vs. gray), not by dramatic
/// size jumps or heavier weights.
class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 32,
    fontWeight: AppFontWeight.medium,
    letterSpacing: -1.2,
    height: 1.1,
  );
  static const h1 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 24,
    fontWeight: AppFontWeight.medium,
    letterSpacing: -0.9,
    height: 1.15,
  );
  static const h2 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 20,
    fontWeight: AppFontWeight.medium,
    letterSpacing: -0.6,
    height: 1.25,
  );
  static const h3 = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 15,
    fontWeight: AppFontWeight.medium,
  );
  static const bodyLg = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: AppFontWeight.medium,
  );
  static const body = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 14,
    fontWeight: AppFontWeight.regular,
  );
  static const label = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: AppFontWeight.medium,
  );
  static const caption = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12,
    fontWeight: AppFontWeight.regular,
  );
}
