import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app/theme/app_theme.dart';
import 'app/router/app_router.dart';
import 'core/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const opts = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(1100, 700),
    center: true,
    title: 'Kasir Siswa',
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });

  // Shortcut global F11: toggle layar penuh (berlaku sejak sebelum login).
  HardwareKeyboard.instance.addHandler((KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      windowManager.isFullScreen().then((fs) => windowManager.setFullScreen(!fs));
      return true;
    }
    return false;
  });

  runApp(const ProviderScope(child: KasirSiswaApp()));
}

class KasirSiswaApp extends ConsumerWidget {
  const KasirSiswaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider); // rebuild saat palet tema diganti
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Kasir Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
