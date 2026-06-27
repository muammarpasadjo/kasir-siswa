import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_colors.dart';
import '../core/providers.dart';

/// Logo aplikasi. Menampilkan: file pilihan admin > asset bawaan > ikon.
class AppLogo extends ConsumerWidget {
  const AppLogo({super.key, this.size = 48, this.radius = 12});
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoPath = ref.watch(logoProvider);
    Widget img;
    if (logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync()) {
      img = Image.file(File(logoPath), width: size, height: size, fit: BoxFit.cover);
    } else {
      img = Image.asset('assets/images/logo.png',
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: AppColors.primary,
                child: Icon(Icons.point_of_sale,
                    color: Colors.white, size: size * 0.55),
              ));
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
  }
}
