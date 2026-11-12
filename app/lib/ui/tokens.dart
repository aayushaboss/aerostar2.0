import 'package:flutter/material.dart';

/// Single source of layout, spacing, type and colour values for every desktop screen.
/// Screens must use these; hard-coded padding, widths, colours or font sizes are not allowed.
class Ui {
  Ui._();

  // ---- container ----
  static const double containerMax = 1200;
  static const double railWidth = 360;
  static const double railGap = 48;
  static const double railStackBelow = 1100;
  static const double filterColumn = 220;
  static const double actionCard = 320;

  /// Responsive side padding: 24 below 1024, 48 from 1024 to 1440, 64 above.
  static double sidePad(double width) => width < 1024 ? 24 : (width <= 1440 ? 48 : 64);

  /// Width of the content container at a window width.
  static double contentWidth(double width) => (width - 2 * sidePad(width)).clamp(0.0, containerMax);

  /// X position of the container's left edge (logo, page title and first content share it).
  static double leftEdge(double width) => (width - contentWidth(width)) / 2;

  // ---- spacing scale: 4 8 12 16 20 24 28 32 40 48 64 ----
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s20 = 20, s24 = 24, s28 = 28, s32 = 32, s40 = 40, s48 = 48, s64 = 64;
  static const double topBarToHeader = 32;
  static const double titleToSubtitle = 6;
  static const double headerToContent = 28;
  static const double betweenSections = 40;
  static const double headingToContent = 16;
  static const double betweenRows = 24;
  static const double gridGap = 16;
  static const double cardPad = 20;
  static const double featuredPad = 24;

  // ---- colour ----
  static const Color ink = Color(0xFF111111);
  static const Color secondary = Color(0xFF737373);
  static const Color tertiary = Color(0xFF8A8A8A);
  static const Color line = Color(0xFFEFEFED);
  static const Color inputBorder = Color(0xFFE8E8E6);
  static const Color surface = Color(0xFFF6F6F4);
  static const Color blue = Color(0xFF0A2FFF);
  static const Color yellow = Color(0xFFFFC72C);
  static const Color highlightBg = Color(0xFFF6F8FF);
  static const Color highlightLine = Color(0xFFE4E9FF);
  static const Color placeholder = Color(0xFFA3A3A3);
  static const Color statusInterview = Color(0xFF0A2FFF);
  static const Color statusReview = Color(0xFFB25900);
  static const Color statusApplied = Color(0xFF737373);
  static const Color statusSuccess = Color(0xFF1A7F37);

  // ---- radius ----
  static const double rField = 6, rAvatar = 8, rCard = 10, rPanel = 12;

  // ---- type (Inter) ----
  static const TextStyle pageTitle = TextStyle(fontSize: 32, fontWeight: FontWeight.w500, letterSpacing: -1.28, color: ink, height: 1.15);
  static const TextStyle innerTitle = TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.5, color: ink, height: 1.2);
  static const TextStyle sectionHeading = TextStyle(fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: -0.17, color: ink);
  static const TextStyle rowTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ink, height: 1.3);
  static const TextStyle body = TextStyle(fontSize: 14, color: ink, height: 1.6);
  static const TextStyle meta = TextStyle(fontSize: 13, color: secondary, height: 1.4);
  static const TextStyle label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary);
  static const TextStyle link = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: blue);
}

/// How wide the content column of a page is. Narrower content stays left-aligned to the
/// container edge, never re-centred, except [tight] (confirmations).
enum ContentWidth {
  full(1200),
  wide(880),
  medium(760),
  narrow(640),
  tight(480);

  final double max;
  const ContentWidth(this.max);
}
