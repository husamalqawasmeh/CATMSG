import 'package:flutter/material.dart';

class CatTheme {
  // Discord + Cozy Night Cat Cafe Palette
  static const Color serverRailBg = Color(0xFF14121D);
  static const Color channelSidebarBg = Color(0xFF1D1A2B);
  static const Color userPodBg = Color(0xFF171422);
  static const Color chatFeedBg = Color(0xFF252136);
  static const Color chatInputBg = Color(0xFF322C47);
  static const Color memberSidebarBg = Color(0xFF1D1A2B);
  static const Color cardBg = Color(0xFF2D2841);
  static const Color cardHoverBg = Color(0xFF393252);

  // Accents
  static const Color pawPink = Color(0xFFFF7EB6);
  static const Color purrple = Color(0xFF9D7BFF);
  static const Color meowCoinGold = Color(0xFFFFD166);
  static const Color catnipMint = Color(0xFF43D9AD);
  static const Color tunaCoral = Color(0xFFFF6B6B);
  static const Color yarnBlue = Color(0xFF5CE1E6);

  // Presence Status Colors
  static const Color statusPurring = Color(0xFF43B581); // Online
  static const Color statusCatnap = Color(0xFFFAA61A); // Idle / Sleeping
  static const Color statusHissing = Color(0xFFF04747); // Do Not Disturb
  static const Color statusStray = Color(0xFF747F8D); // Offline

  // Text Colors
  static const Color textPrimary = Color(0xFFF4F1FA);
  static const Color textSecondary = Color(0xFFB5AFC7);
  static const Color textMuted = Color(0xFF7C7594);

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: chatFeedBg,
      colorScheme: const ColorScheme.dark(
        primary: pawPink,
        secondary: purrple,
        surface: channelSidebarBg,
        error: tunaCoral,
      ),
      dividerColor: Colors.white.withValues(alpha: 0.07),
      splashColor: pawPink.withValues(alpha: 0.12),
      highlightColor: purrple.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: chatFeedBg,
        elevation: 0,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: channelSidebarBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: chatInputBg,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: pawPink, width: 1.5),
        ),
      ),
    );
  }
}
