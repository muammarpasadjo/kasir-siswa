import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_siswa/main.dart';

void main() {
  testWidgets('App renders POS shell', (tester) async {
    // App ditujukan untuk desktop lebar.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KasirSiswaApp());
    expect(find.text('Daftar Produk'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);

    // Tap produk pertama -> masuk keranjang.
    await tester.tap(find.text('Indomie Goreng').first);
    await tester.pump();
    expect(find.text('Bayar & Cetak Struk'), findsOneWidget);
  });
}
