import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/database/database.dart';

class PosShell extends ConsumerStatefulWidget {
  const PosShell({super.key});
  @override
  ConsumerState<PosShell> createState() => _PosShellState();
}

class CartItem {
  final Product product;
  int qty;
  CartItem(this.product, [this.qty = 1]);
}

class _PosShellState extends ConsumerState<PosShell> {
  bool _fullscreen = false;
  final List<CartItem> cart = [];

  Future<void> _toggleFullscreen() async {
    _fullscreen = !_fullscreen;
    await windowManager.setFullScreen(_fullscreen);
    setState(() {});
  }

  void addToCart(Product p) {
    setState(() {
      final found = cart.where((c) => c.product.id == p.id);
      if (found.isNotEmpty) {
        found.first.qty++;
      } else {
        cart.add(CartItem(p));
      }
    });
  }

  double get subtotal =>
      cart.fold(0, (s, c) => s + c.product.sellPrice * c.qty);
  double get tax => subtotal * 0.11;
  double get total => subtotal + tax;

  String rp(num v) => 'Rp ' +
      v.round().toString().replaceAllMapped(
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

  Widget _sidebar() {
    final session = ref.watch(authProvider);
    return Container(
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
          if (session != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                const Icon(Icons.account_circle, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.user.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(session.role,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ]),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 52),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _toggleFullscreen,
              icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen, size: 24),
              label: Text(_fullscreen ? 'Keluar Layar Penuh' : 'Layar Penuh',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 52),
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 24),
              label: const Text('Keluar', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _productArea() {
    final productsAsync = ref.watch(productsProvider);
    return Padding(
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
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat produk: $e')),
              data: (items) => GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _productCard(items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                Text(rp(p.sellPrice),
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
                                Text(rp(c.product.sellPrice),
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
                          _qtyBtn(Icons.add, () => setState(() => c.qty++), primary: true),
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
              child: Icon(icon, size: 24, color: primary ? Colors.white : AppColors.textDark),
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
        content: Text('Total dibayar: ${rp(total)}', style: const TextStyle(fontSize: 18)),
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
