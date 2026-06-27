import 'package:flutter/material.dart';

/// Warna aplikasi. `primary` & `primaryLight` dapat diganti admin (tema).
class AppColors {
  static Color primary = const Color(0xFFF4512C);
  static Color primaryLight = const Color(0xFFFDE7E1);
  static const danger = Color(0xFFEF4444);
  static const bg = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1F2430);
  static const textMuted = Color(0xFF8A91A0);
  static const border = Color(0xFFEDEFF3);
}

/// Palet tema yang bisa dipilih admin.
class AppPalette {
  final String name;
  final Color primary;
  final Color primaryLight;
  const AppPalette(this.name, this.primary, this.primaryLight);
}

const appPalettes = <AppPalette>[
  AppPalette('Coral', Color(0xFFF4512C), Color(0xFFFDE7E1)),
  AppPalette('Biru', Color(0xFF2563EB), Color(0xFFE0EAFF)),
  AppPalette('Hijau', Color(0xFF16A34A), Color(0xFFDCFCE7)),
  AppPalette('Ungu', Color(0xFF7C3AED), Color(0xFFEDE9FE)),
  AppPalette('Oranye', Color(0xFFEA580C), Color(0xFFFFEDD5)),
  AppPalette('Teal', Color(0xFF0D9488), Color(0xFFCCFBF1)),
  AppPalette('Merah', Color(0xFFDC2626), Color(0xFFFEE2E2)),
  AppPalette('Indigo', Color(0xFF4F46E5), Color(0xFFE0E7FF)),
];
