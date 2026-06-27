import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Skema dasar dengan komponen besar agar nyaman untuk layar sentuh.
  static ThemeData _build(Brightness b) {
    final base = b == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: b == Brightness.light ? AppColors.bg : null,
      colorScheme: base.colorScheme.copyWith(primary: AppColors.primary),
      textTheme: base.textTheme.apply(fontFamily: 'Roboto').copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      // Target sentuh lebih besar.
      visualDensity: VisualDensity.comfortable,
      cardTheme: CardThemeData(
        elevation: 0,
        color: b == Brightness.light ? AppColors.surface : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: b == Brightness.light ? AppColors.border : Colors.white12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 60), // tinggi tombol besar
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52), // area sentuh ikon
          iconSize: 28,
        ),
      ),
    );
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);
}