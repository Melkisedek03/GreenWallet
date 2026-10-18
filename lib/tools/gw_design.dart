import 'package:flutter/material.dart';

import 'app_themes.dart';

/// GreenWallet dashboard design system (Fase A UI redesign).
///
/// Visual language extracted from the dashboard mockup, built on the
/// Emerald Deep palette defined in [DarkColors]:
/// primary #0A5C42, dark background #062A20, mint accent #2FBF8F,
/// light text #EAF4EF.
abstract class GwDesign {
  // ------------------------------------------------------------------
  // Colors
  // ------------------------------------------------------------------

  /// Page background: deep emerald, slightly darker than [DarkColors.black]
  /// to match the mockup.
  static Color get background => const Color(0xFF052018);

  /// Hero balance card gradient (top-left light to bottom-right dark).
  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF127A57),
      Color(0xFF0A5C42),
      Color(0xFF06382A),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Subtle border used on cards and pills.
  static Color get cardBorder => const Color(0xFF1E6B4F);

  /// Circular quick-action button fill.
  static Color get actionButtonFill => const Color(0xFF0A3A2C);

  /// Circular quick-action button border.
  static Color get actionButtonBorder => const Color(0xFF2FBF8F);

  /// Quick-action icon color.
  static Color get actionIcon => const Color(0xFF2FBF8F);

  /// Disabled quick-action (Buy/Swap) icon and border color.
  static Color get actionDisabled => const Color(0xFF5A7A6E);

  /// Bottom navigation bar background.
  static Color get bottomNavBackground => const Color(0xFF04170F);

  /// Bottom nav inactive item color.
  static Color get bottomNavInactive => const Color(0xFF8AA39A);

  /// Transaction divider color.
  static Color get divider => const Color(0xFF0F3D2E);

  /// Positive (received) amount color.
  static Color get positive => const Color(0xFF2FBF8F);

  /// "Coming soon" / info pill background.
  static Color get pillBackground => const Color(0xFF0E4A36);

  // ------------------------------------------------------------------
  // Radii
  // ------------------------------------------------------------------

  static const double radiusCard = 24.0;
  static const double radiusPill = 28.0;
  static const double radiusActionButton = 40.0; // circular, 80px diameter
  static const double radiusBottomNav = 28.0;
  static const double radiusBottomNavItem = 20.0;

  // ------------------------------------------------------------------
  // Spacing
  // ------------------------------------------------------------------

  static const double spacingPage = 20.0;
  static const double spacingSection = 24.0;
  static const double spacingCard = 16.0;

  // ------------------------------------------------------------------
  // Text styles
  // ------------------------------------------------------------------

  static TextStyle get greeting => const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: Color(0xFFEAF4EF),
        height: 1.15,
      );

  static TextStyle get walletPillLabel => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2FBF8F),
      );

  static TextStyle get heroLabel => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFFEAF4EF),
      );

  static TextStyle get heroBalance => const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      );

  static TextStyle get heroBalanceUnit => const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get heroFiat => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8AA39A),
      );

  static TextStyle get actionLabel => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFEAF4EF),
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get seeAll => const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2FBF8F),
      );

  static TextStyle get txTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get txSubtitle => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFF8AA39A),
      );

  static TextStyle get txAmountPositive => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2FBF8F),
      );

  static TextStyle get txAmountNegative => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get txTime => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFF8AA39A),
      );

  static TextStyle get emptyState => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF8AA39A),
      );

  static TextStyle get bottomNavLabel => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  // ------------------------------------------------------------------
  // Fase B: Send / Receive screens (from the send mockup)
  // ------------------------------------------------------------------

  /// Section labels on the send screen ("Recipient", "Amount", ...).
  static TextStyle get sendSectionLabel => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2FBF8F),
      );

  /// Large amount input text on the send screen.
  static TextStyle get sendAmountBig => const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      );

  /// "NUX" unit next to the big amount.
  static TextStyle get sendAmountUnit => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2FBF8F),
      );

  /// Secondary hint text under the amount ("Available: ...").
  static TextStyle get sendHint => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF8AA39A),
      );

  /// Input field fill on the send screen.
  static Color get sendInputFill => const Color(0xFF0A3A2C);

  /// Input field border on the send screen.
  static Color get sendInputBorder => const Color(0xFF1E6B4F);

  /// Inactive fee pill fill.
  static Color get feePillInactiveFill => const Color(0xFF2A2F2D);

  /// Inactive fee pill text.
  static Color get feePillInactiveText => const Color(0xFF8AA39A);

  /// Active fee pill fill (mint).
  static Color get feePillActiveFill => const Color(0xFF2FBF8F);

  /// Active fee pill text (dark).
  static Color get feePillActiveText => const Color(0xFF062A20);

  /// Summary card background on the send screen.
  static Color get sendSummaryFill => const Color(0xFF0A3A2C);

  /// "Total" value color in the summary card.
  static Color get sendTotalValue => const Color(0xFF2FBF8F);

  /// Gradient for the primary send button (mint, like the mockup).
  static const LinearGradient sendButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF0E7A55),
      Color(0xFF2FBF8F),
    ],
  );

  /// Receive screen: address card fill.
  static Color get receiveCardFill => const Color(0xFF0A3A2C);

  /// Receive screen: address card border.
  static Color get receiveCardBorder => const Color(0xFF2FBF8F);

  /// Fee tier targets for blockchain.estimatefee, in blocks.
  /// Slow = cheap (more blocks), Normal = default, Fast = expensive.
  static const int feeBlocksSlow = 24;
  static const int feeBlocksNormal = 6;
  static const int feeBlocksFast = 2;

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  /// Formats a satoshi-denominated [balance] using the coin's decimal
  /// places, e.g. 124892000000 -> "1,248.92".
  static String formatBalance(int balance, int fractions) {
    final divisor = BigInt.from(10).pow(fractions).toInt();
    final whole = balance ~/ divisor;
    final frac = (balance % divisor).toString().padLeft(fractions, '0');
    // Trim to 2 visible decimals for the hero card, like the mockup.
    final frac2 = frac.substring(0, 2);
    final wholeStr = _thousands(whole);
    return '$wholeStr.$frac2';
  }

  static String _thousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Shortens an address like the mockup ("0x4a2...9f1c").
  static String shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 5)}...${address.substring(address.length - 4)}';
  }

  /// Human-friendly relative time label ("Today • 10:42 AM").
  static String txTimeLabel(BuildContext context, int timestampSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(day).inDays;

    final time = TimeOfDay.fromDateTime(dt);
    final timeStr = time.format(context);

    if (diffDays == 0) return 'Today • $timeStr';
    if (diffDays == 1) return 'Yesterday • $timeStr';
    return '${_monthName(dt.month)} ${dt.day} • $timeStr';
  }

  static String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m];
  }
}
