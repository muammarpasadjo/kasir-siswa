import 'package:flutter/material.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_colors.dart';

void main() => runApp(const KasirSiswaApp());

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

/// Model produk sementara (akan diganti dengan data dari database).
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

  String rp(int v) => 'Rp ' + v.toString().replaceAllMapped(
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
        width: 230,
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: AppColors.primary,
                  child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Text('Kasir Siswa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          ],
        ),
      );

  Widget _navItem(IconData icon, String label, {bool active = false}) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: active ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textDark,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      );

  Widget _productArea() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daftar Produk',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Pilih produk untuk ditambahkan ke keranjang',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => _productCard(products[i]),
              ),
            ),
          ],
        ),
      );

  Widget _productCard(Product p) => InkWell(
        onTap: () => addToCart(p),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood, size: 40, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 8),
                Text(p.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(rp(p.price),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  Widget _orderPanel() => Container(
        width: 320,
        color: AppColors.surface,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Transaksi baru', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Text('Keranjang kosong',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      itemCount: cart.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final c = cart[i];
                        return Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(rp(c.product.price),
                                    style: const TextStyle(
                                        color: AppColors.primary, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                              onPressed: () => setState(() {
                                    if (c.qty > 1) {
                                      c.qty--;
                                    } else {
                                      cart.removeAt(i);
                                    }
                                  }),
                              icon: const Icon(Icons.remove_circle_outline, size: 20)),
                          Text('${c.qty}'),
                          IconButton(
                              onPressed: () => setState(() => c.qty++),
                              icon: const Icon(Icons.add_circle, size: 20, color: AppColors.primary)),
                        ]);
                      },
                    ),
            ),
            const Divider(),
            _row('Subtotal', rp(subtotal)),
            _row('Pajak (11%)', rp(tax)),
            const SizedBox(height: 6),
            _row('Total', rp(total), bold: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: cart.isEmpty ? null : () => _bayar(),
                child: const Text('Bayar & Cetak Struk',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l,
              style: TextStyle(
                  color: bold ? AppColors.textDark : AppColors.textMuted,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(v,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ]),
      );

  void _bayar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transaksi Berhasil'),
        content: Text('Total dibayar: ${rp(total)}'),
        actions: [
          TextButton(
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
