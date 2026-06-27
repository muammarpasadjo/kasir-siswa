import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_colors.dart';

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
    await windowManager.maximize(); // mulai termaksimalkan
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const KasirSiswaApp());
}

class KasirSiswaApp extends StatelessWidget {
  const KasirSiswaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Siswa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const PosShell(),
    );
  }
}

class Product {
  final String name;
  final int price;
  const Product(this.name, this.price);
}

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, [this.qty = 1]);
}

class PosShell extends StatefulWidget {
  const PosShell({super.key});
  @override
  State<PosShell> createState() => _PosShellState();
}

class _PosShellState extends State<PosShell> {
  bool _fullscreen = false;

  final products = const [
    Product('Indomie Goreng', 3500),
    Product('Aqua 600ml', 4000),
    Product('Teh Botol', 5000),
    Product('Chitato', 9500),
    Product('Susu Ultra', 7000),
    Product('Kopi Kapal Api', 2000),
    Product('Roti Tawar', 14000),
    Product('Sabun Lifebuoy', 4500),
    Product('Pepsodent', 12000),
    Product('Beras 1kg', 13000),
    Product('Gula 1kg', 16000),
    Product('Minyak 1L', 18000),
  ];
  final List<CartItem> cart = [];

  Future<void> _toggleFullscreen() async {
    _fullscreen = !_fullscreen;
    await windowManager.setFullScreen(_fullscreen);
    setState(() {});
  }

  void addToCart(Product p) {
    setState(() {
      final found = cart.where((c) => c.product.name == p.name);
      if (found.isNotEmpty) {
        found.first.qty++;
      } else {
        cart.add(CartItem(p));
      }
    });
  }

  int get subtotal => cart.fold(0, (s, c) => s + c.product.price * c.qty);
  int get tax => (subtotal * 0.11).round();
  int get total => subtotal + tax;

  String rp(int v) => 'Rp ' +
      v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _sidebar(),
          Expanded(child: _productArea()),
          _orderPanel(),
        ],
      ),
    );
  }

  Widget _sidebar() => Container(
        width: 250,
        color: AppColors.surface,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 26)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Kasir Siswa',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ]),
            const SizedBox(height: 28),
            _navItem(Icons.dashboard, 'Dashboard', active: true),
            _navItem(Icons.shopping_cart, 'Penjualan'),
            _navItem(Icons.inventory_2, 'Produk'),
            _navItem(Icons.local_shipping, 'Pembelian'),
            _navItem(Icons.people, 'Member'),
            _navItem(Icons.bar_chart, 'Laporan'),
            _navItem(Icons.access_time, 'Shift Kasir'),
            const Spacer(),
            _navItem(Icons.settings, 'Pengaturan'),
            const SizedBox(height: 8),
            // Tombol fullscreen besar.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 56),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _toggleFullscreen,
                icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 26),
                label: Text(_fullscreen ? 'Keluar Layar Penuh' : 'Layar Penuh',
                    style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      );

  Widget _navItem(IconData icon, String label, {bool active = false}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: active ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                Icon(icon, size: 26, color: active ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          color: active ? AppColors.primary : AppColors.textDark,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _productArea() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daftar Produk',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Sentuh produk untuk menambahkan ke keranjang',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => _productCard(products[i]),
              ),
            ),
          ],
        ),
      );

  Widget _productCard(Product p) => Card(
        child: InkWell(
          onTap: () => addToCart(p),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.fastfood, size: 52, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Text(p.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text(rp(p.price),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
          ),
        ),
      );

  Widget _orderPanel() => Container(
        width: 400,
        color: AppColors.surface,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesanan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Transaksi baru',
                style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            const SizedBox(height: 18),
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Text('Keranjang kosong',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 16)))
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, __) => const Divider(height: 22),
                      itemBuilder: (_, i) {
                        final c = cart[i];
                        return Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.product.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(rp(c.product.price),
                                    style: const TextStyle(
                                        color: AppColors.primary, fontSize: 14)),
                              ],
                            ),
                          ),
                          _qtyBtn(Icons.remove, () => setState(() {
                                if (c.qty > 1) {
                                  c.qty--;
                                } else {
                                  cart.removeAt(i);
                                }
                              })),
                          SizedBox(
                              width: 38,
                              child: Text('${c.qty}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold))),
                          _qtyBtn(Icons.add, () => setState(() => c.qty++),
                              primary: true),
                        ]);
                      },
                    ),
            ),
            const Divider(height: 28),
            _row('Subtotal', rp(subtotal)),
            _row('Pajak (11%)', rp(tax)),
            const SizedBox(height: 8),
            _row('Total', rp(total), bold: true),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 68),
                ),
                onPressed: cart.isEmpty ? null : _bayar,
                child: const Text('Bayar & Cetak Struk'),
              ),
            ),
          ],
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool primary = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: primary ? AppColors.primary : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon,
                  size: 24, color: primary ? Colors.white : AppColors.textDark),
            ),
          ),
        ),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  fontSize: bold ? 20 : 16,
                  color: bold ? AppColors.textDark : AppColors.textMuted,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(v,
              style: TextStyle(
                  fontSize: bold ? 22 : 16,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ]),
      );

  void _bayar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transaksi Berhasil'),
        content: Text('Total dibayar: ${rp(total)}',
            style: const TextStyle(fontSize: 18)),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => cart.clear());
              },
              child: const Text('Selesai')),
        ],
      ),
    );
  }
}
