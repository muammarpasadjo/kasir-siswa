import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../widgets/app_logo.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteIdx = ref.watch(themeProvider);
    final taxOn = ref.watch(taxEnabledProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _card('Logo Aplikasi', [
            Row(children: [
              const AppLogo(size: 72, radius: 16),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48)),
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(
                      type: FileType.image, withData: false);
                  if (res != null && res.files.single.path != null) {
                    await ref.read(logoProvider.notifier)
                        .setLogo(res.files.single.path!);
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text('Ganti Logo'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => ref.read(logoProvider.notifier).setLogo(null),
                child: const Text('Reset'),
              ),
            ]),
          ]),
          _card('Pajak / PPN (11%)', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text('Aktifkan pajak pada transaksi (default)'),
              subtitle: const Text(
                  'Jika mati, pajak bersifat opsional dan dapat dinyalakan per transaksi.'),
              value: taxOn,
              onChanged: (v) =>
                  ref.read(taxEnabledProvider.notifier).setEnabled(v),
            ),
          ]),
          _card('Tema Warna', [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (int i = 0; i < appPalettes.length; i++)
                  InkWell(
                    onTap: () =>
                        ref.read(themeProvider.notifier).setPalette(i),
                    child: Container(
                      width: 78,
                      padding: const EdgeInsets.all(6),
                      child: Column(children: [
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: appPalettes[i].primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: i == paletteIdx
                                    ? AppColors.textDark
                                    : Colors.transparent,
                                width: 3),
                          ),
                          child: i == paletteIdx
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(appPalettes[i].name,
                            style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ),
              ],
            ),
          ]),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      );
}

// ignore: unused_element
File _f(String p) => File(p);