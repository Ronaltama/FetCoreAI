import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color cardBg;
  final Color surfaceBg;
  final Color textPrimary;
  final Color textSecondary;

  final Color primaryGreen;
  final Color accentBlue;
  final Color accentPurple;
  final Color dangerRed;
  final Color onlineGreen;
  final Color offlineGrey;
  final Color warningOrange;
  final Color borderStroke;

  const AppColors({
    required this.bg,
    required this.cardBg,
    required this.surfaceBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryGreen,
    required this.accentBlue,
    required this.accentPurple,
    required this.dangerRed,
    required this.onlineGreen,
    required this.offlineGrey,
    required this.warningOrange,
    required this.borderStroke,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? bg,
    Color? cardBg,
    Color? surfaceBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? primaryGreen,
    Color? accentBlue,
    Color? accentPurple,
    Color? dangerRed,
    Color? onlineGreen,
    Color? offlineGrey,
    Color? warningOrange,
    Color? borderStroke,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      cardBg: cardBg ?? this.cardBg,
      surfaceBg: surfaceBg ?? this.surfaceBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primaryGreen: primaryGreen ?? this.primaryGreen,
      accentBlue: accentBlue ?? this.accentBlue,
      accentPurple: accentPurple ?? this.accentPurple,
      dangerRed: dangerRed ?? this.dangerRed,
      onlineGreen: onlineGreen ?? this.onlineGreen,
      offlineGrey: offlineGrey ?? this.offlineGrey,
      warningOrange: warningOrange ?? this.warningOrange,
      borderStroke: borderStroke ?? this.borderStroke,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      surfaceBg: Color.lerp(surfaceBg, other.surfaceBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primaryGreen: Color.lerp(primaryGreen, other.primaryGreen, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      dangerRed: Color.lerp(dangerRed, other.dangerRed, t)!,
      onlineGreen: Color.lerp(onlineGreen, other.onlineGreen, t)!,
      offlineGrey: Color.lerp(offlineGrey, other.offlineGrey, t)!,
      warningOrange: Color.lerp(warningOrange, other.warningOrange, t)!,
      borderStroke: Color.lerp(borderStroke, other.borderStroke, t)!,
    );
  }
}

extension AppThemeExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

class AppTheme {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final AppColors _darkColors = AppColors(
    bg: const Color(0xFF0F172A),
    cardBg: const Color(0xFF1E293B),
    surfaceBg: const Color(0xFF334155),
    textPrimary: const Color(0xFFF8FAFC),
    textSecondary: const Color(0xFF94A3B8),
    primaryGreen: const Color(0xFF10B981),
    accentBlue: const Color(0xFF3B82F6),
    accentPurple: const Color(0xFF8B5CF6),
    dangerRed: const Color(0xFFEF4444),
    onlineGreen: const Color(0xFF22C55E),
    offlineGrey: const Color(0xFF64748B),
    warningOrange: const Color(0xFFF59E0B),
    borderStroke: Colors.white.withValues(alpha: 0.05),
  );

  static final AppColors _lightColors = AppColors(
    bg: const Color(0xFFF8FAFC),
    cardBg: const Color(0xFFFFFFFF),
    surfaceBg: const Color(0xFFF1F5F9),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF64748B),
    primaryGreen: const Color(0xFF10B981),
    accentBlue: const Color(0xFF3B82F6),
    accentPurple: const Color(0xFF8B5CF6),
    dangerRed: const Color(0xFFEF4444),
    onlineGreen: const Color(0xFF22C55E),
    offlineGrey: const Color(0xFF94A3B8),
    warningOrange: const Color(0xFFF59E0B),
    borderStroke: Colors.black.withValues(alpha: 0.05),
  );

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: _darkColors.textPrimary,
      displayColor: _darkColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _darkColors.primaryGreen,
      scaffoldBackgroundColor: _darkColors.bg,
      textTheme: textTheme,
      extensions: [_darkColors],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkColors.primaryGreen),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _darkColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkColors.cardBg,
        selectedItemColor: _darkColors.primaryGreen,
        unselectedItemColor: _darkColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: _darkColors.primaryGreen.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkColors.surfaceBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _darkColors.primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: _darkColors.textSecondary),
        hintStyle: TextStyle(
          color: _darkColors.textSecondary.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: _lightColors.textPrimary,
      displayColor: _lightColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _lightColors.primaryGreen,
      scaffoldBackgroundColor: _lightColors.bg,
      textTheme: textTheme,
      extensions: [_lightColors],
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColors.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: _lightColors.primaryGreen),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _lightColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightColors.cardBg,
        selectedItemColor: _lightColors.primaryGreen,
        unselectedItemColor: _lightColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          elevation: 4,
          shadowColor: _lightColors.primaryGreen.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightColors.surfaceBg.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _lightColors.primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: _lightColors.textSecondary),
        hintStyle: TextStyle(
          color: _lightColors.textSecondary.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
