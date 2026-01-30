import 'package:flutter/material.dart';

/// Минималистичная тёмная тема: чёрный фон, белые/серые элементы.
class AppTheme {
  AppTheme._();

  static const Color surfaceBlack = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF0D0D0D);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color surfaceInput = Color(0xFF262626);
  static const Color borderLight = Color(0xFF333333);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF737373);
  static const Color accent = Color(0xFFE5E5E5);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surfaceBlack,
        colorScheme: ColorScheme.dark(
          surface: surfaceBlack,
          onSurface: textPrimary,
          primary: textPrimary,
          onPrimary: surfaceBlack,
          secondary: textSecondary,
          onSecondary: surfaceBlack,
          error: const Color(0xFFCF6679),
          onError: surfaceBlack,
          outline: borderLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceBlack,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceInput,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: textSecondary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCF6679)),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: textPrimary,
          foregroundColor: surfaceBlack,
          elevation: 2,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surfaceDark,
          indicatorColor: surfaceCard,
          elevation: 0,
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500);
            }
            return const TextStyle(color: textMuted, fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: textPrimary, size: 24);
            }
            return const IconThemeData(color: textMuted, size: 24);
          }),
        ),
        dividerColor: borderLight,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceCard,
          contentTextStyle: const TextStyle(color: textPrimary),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: textPrimary,
          linearTrackColor: surfaceInput,
          circularTrackColor: surfaceInput,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: textPrimary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: textPrimary,
            foregroundColor: surfaceBlack,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: borderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surfaceInput,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderLight),
            ),
          ),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(surfaceCard),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      );
}
