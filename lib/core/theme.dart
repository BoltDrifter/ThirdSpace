/// ============================================================
/// ThirdSpace Design System: "The Neon Pulse"
/// ============================================================
/// Sourced from Stitch MCP Design System "Social Gravity"
/// (asset: 5ccf8df39f8a4233a5b9eb91f13380bd)
///
/// Color Hierarchy (Tonal Layering):
///   Level 0 (Map/Base): surfaceContainerLowest #000000
///   Level 1 (Canvas):   surface               #0d0d15
///   Level 2 (Cards):    surfaceContainer       #191922
///   Level 3 (Overlays): surfaceBright          #2b2b38
///
/// Vibe Colors:
///   #SocialBuzz          → primary   #cc97ff / #9c48ea
///   #DeepWork            → secondary #53ddfc
///   #CreativeFlow        → amber     #F59E0B
///   #QuietContemplation  → tertiary  #9bffce
/// ============================================================
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All color tokens from the Stitch MCP design system
class TSColors {
  TSColors._();

  // ── Surface Hierarchy (Tonal Layering) ──
  static const surface = Color(0xFF0d0d15);
  static const surfaceDim = Color(0xFF0d0d15);
  static const surfaceBright = Color(0xFF2b2b38);
  static const surfaceContainer = Color(0xFF191922);
  static const surfaceContainerLow = Color(0xFF13131b);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerHigh = Color(0xFF1f1f29);
  static const surfaceContainerHighest = Color(0xFF252530);
  static const surfaceVariant = Color(0xFF252530);
  static const surfaceTint = Color(0xFFcc97ff);

  // ── Primary (Social Gravity / Electric Purple) ──
  static const primary = Color(0xFFcc97ff);
  static const primaryDim = Color(0xFF9c48ea);
  static const primaryContainer = Color(0xFFc284ff);
  static const onPrimary = Color(0xFF47007c);
  static const onPrimaryContainer = Color(0xFF360061);

  // ── Secondary (Deep Work / Cool Cyan) ──
  static const secondary = Color(0xFF53ddfc);
  static const secondaryDim = Color(0xFF40ceed);
  static const secondaryContainer = Color(0xFF00687a);
  static const onSecondary = Color(0xFF004b58);
  static const onSecondaryContainer = Color(0xFFecfaff);

  // ── Tertiary (Quiet Contemplation / Soft Emerald) ──
  static const tertiary = Color(0xFF9bffce);
  static const tertiaryDim = Color(0xFF58e7ab);
  static const tertiaryContainer = Color(0xFF69f6b8);
  static const onTertiary = Color(0xFF006443);
  static const onTertiaryContainer = Color(0xFF005a3c);

  // ── Creative Flow (Warm Amber) — not in named colors, from designMd ──
  static const creativeAmber = Color(0xFFF59E0B);

  // ── Error ──
  static const error = Color(0xFFff6e84);
  static const errorContainer = Color(0xFFa70138);
  static const onError = Color(0xFF490013);

  // ── On-Surface / Text ──
  static const onSurface = Color(0xFFefecf8);
  static const onSurfaceVariant = Color(0xFFacaab5);
  static const onBackground = Color(0xFFefecf8);

  // ── Outline ──
  static const outline = Color(0xFF76747f);
  static const outlineVariant = Color(0xFF484750);

  // ── Inverse ──
  static const inverseSurface = Color(0xFFfcf8ff);
  static const inversePrimary = Color(0xFF842cd3);
  static const inverseOnSurface = Color(0xFF55545e);

  // ── Vibe-specific semantic colors ──
  static const vibeSocial = primary;
  static const vibeDeepWork = secondary;
  static const vibeCreative = creativeAmber;
  static const vibeQuiet = tertiary;
}

/// The complete ThirdSpace theme built from Stitch MCP tokens
class ThirdSpaceTheme {
  ThirdSpaceTheme._();

  /// Typography follows the "Editorial Tech" system:
  ///   Headlines: Plus Jakarta Sans (bold, tight tracking)
  ///   Body/Label: Inter (regular, clean)
  static TextTheme get _textTheme {
    return TextTheme(
      // Display — Plus Jakarta Sans, tight letter-spacing
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.24,
        color: TSColors.onSurface,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.76,
        color: TSColors.onSurface,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.44,
        color: TSColors.onSurface,
      ),

      // Headline — Plus Jakarta Sans
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.64,
        color: TSColors.onSurface,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.56,
        color: TSColors.onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: TSColors.onSurface,
      ),

      // Title — Plus Jakarta Sans
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: TSColors.onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: TSColors.onSurface,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: TSColors.onSurface,
      ),

      // Body — Inter (utility, high legibility)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: TSColors.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: TSColors.onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: TSColors.onSurfaceVariant,
      ),

      // Label — Inter
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: TSColors.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: TSColors.onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: TSColors.onSurfaceVariant,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      surface: TSColors.surface,
      onSurface: TSColors.onSurface,
      surfaceContainerLowest: TSColors.surfaceContainerLowest,
      surfaceContainerLow: TSColors.surfaceContainerLow,
      surfaceContainer: TSColors.surfaceContainer,
      surfaceContainerHigh: TSColors.surfaceContainerHigh,
      surfaceContainerHighest: TSColors.surfaceContainerHighest,
      primary: TSColors.primary,
      onPrimary: TSColors.onPrimary,
      primaryContainer: TSColors.primaryContainer,
      onPrimaryContainer: TSColors.onPrimaryContainer,
      secondary: TSColors.secondary,
      onSecondary: TSColors.onSecondary,
      secondaryContainer: TSColors.secondaryContainer,
      onSecondaryContainer: TSColors.onSecondaryContainer,
      tertiary: TSColors.tertiary,
      onTertiary: TSColors.onTertiary,
      tertiaryContainer: TSColors.tertiaryContainer,
      onTertiaryContainer: TSColors.onTertiaryContainer,
      error: TSColors.error,
      onError: TSColors.onError,
      errorContainer: TSColors.errorContainer,
      outline: TSColors.outline,
      outlineVariant: TSColors.outlineVariant,
      inverseSurface: TSColors.inverseSurface,
      inversePrimary: TSColors.inversePrimary,
      surfaceTint: TSColors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: TSColors.surface,

      // AppBar: Glassmorphic overlay feel
      appBarTheme: AppBarTheme(
        backgroundColor: TSColors.surface.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: TSColors.onSurface,
        ),
        iconTheme: const IconThemeData(color: TSColors.onSurface),
      ),

      // Cards: "No-Line" Rule — tonal layering only, md/lg rounding
      cardTheme: CardTheme(
        color: TSColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Bottom Nav: Glass panel
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: TSColors.primary,
        unselectedItemColor: TSColors.onSurfaceVariant,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Elevated Buttons: "The Glow" — primary gradient feel
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TSColors.primary,
          foregroundColor: TSColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Outlined Buttons: "The Glass"
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TSColors.primary,
          side: BorderSide(color: TSColors.outlineVariant.withOpacity(0.15)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields: glow on focus, no 2px border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TSColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: TSColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          color: TSColors.onSurfaceVariant.withOpacity(0.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Chips: Pill-shaped Vibe Chips
      chipTheme: ChipThemeData(
        backgroundColor: TSColors.surfaceVariant.withOpacity(0.3),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // FAB: Gradient glow
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: TSColors.primary,
        foregroundColor: TSColors.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Sheet: Glassmorphism
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: TSColors.surfaceContainer.withOpacity(0.92),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Divider: Never use hard dividers per design system
      dividerTheme: DividerThemeData(
        color: TSColors.outlineVariant.withOpacity(0.1),
        thickness: 0.5,
      ),
    );
  }
}