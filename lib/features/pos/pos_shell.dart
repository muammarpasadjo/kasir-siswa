import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/database/database.dart';
import '../../widgets/app_logo.dart';
import '../products/products_page.dart' hide rp;
import '../settings/settings_page.dart';
import '../misc/pages.dart';

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
  String _query = '';
  bool? _taxLocal; // null = ikut default pengaturan
  final _searchCtrl = TextEditingController();
  final List<CartItem> cart = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  bool get taxOn => _taxLocal ?? ref.read(taxEnabledProvider);
  double get subtotal => cart.fold(0, (s, c) => s + c.product.sellPrice * c.qty);
  double get tax => taxOn ? subtotal * 0.11 : 0;
  double get total => subtotal + tax;

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

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
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
          const Row(children: [
            AppLogo(size: 46, radius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Text('Kasir Siswa',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19)),
            ),
          ]),
          const SizedBox(height: 28),
          _navItem(Icons.dashboard, 'Dashboard', active: true),
          _navItem(Icons.shopping_cart, 'Penjualan',
              onTap: () => _open(const SalesHistoryPage())),
          _navItem(Icons.inventory_2, 'Produk',
              onTap: () => _open(const ProductsPage())),
          _navItem(Icons.local_shipping, 'Pembelian',
              onTap: () => _open(const ComingSoonPage(
                  title: 'Pembelian', icon: Icons.local_shipping))),
          _navItem(Icons.people, 'Member',
              onTap: () => _open(const MembersPage())),
          _navItem(Icons.bar_chart, 'Laporan',
              onTap: () => _open(const ReportPage())),
          _navItem(Icons.access_time, 'Shift Kasir',
              onTap: () => _open(const ComingSoonPage(
                  title: 'Shift Kasir', icon: Icons.access_time))),
          _navItem(Icons.settings, 'Pengaturan',
              onTap: () => _open(const SettingsPage())),
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
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(session.role,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ]),
            ),
          // Catatan kecil shortcut layar penuh
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Tekan F11 untuk layar penuh / keluar',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 50),
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, size: 22),
              label: const Text('Keluar', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
          {bool active = false, VoidCallback? onTap}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: active ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap ?? () {},
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(icon,
                    size: 24,
                    color: active ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          color: active ? AppColors.primary : AppColors.textDark,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400)),
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
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 16),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari barang (nama / barcode)...',
              prefixIcon: const Icon(Icons.search, size: 24),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      }),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal memuat produk: $e')),
              data: (all) {
                final items = _query.isEmpty
                    ? all
                    : all
                        .where((p) =>
                            p.name.toLowerCase().contains(_query) ||
                            (p.barcode ?? '').toLowerCase().contains(_query))
                        .toList();
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Barang tidak ditemukan',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16)));
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _productCard(items[i]),
                );
              },
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
                    clipBehavior: Clip.antiAlias,
                    child: (p.imagePath != null && p.imagePath!.isNotEmpty)
                        ? _ProductImage(path: p.imagePath!)
                        : const Icon(Icons.fastfood,
                            size: 50, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                Text(p.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 15)),
                const SizedBox(height: 6),
                Text(rp(p.sellPrice),
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const Text('Transaksi baru',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 18),
            Expanded(
              child: cart.isEmpty
                  ? const Center(
                      child: Text('Keranjang kosong',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 16)))
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
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(rp(c.product.sellPrice),
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13)),
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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600))),
                          _qtyBtn(Icons.add, () => setState(() => c.qty++),
                              primary: true),
                        ]);
                      },
                    ),
            ),
            const Divider(height: 24),
            _row('Subtotal', rp(subtotal)),
            // Toggle pajak opsional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Text('Pajak (11%)',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: taxOn,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _taxLocal = v),
                    ),
                  ),
                ]),
                Text(rp(tax),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 4),
            _row('Total', rp(total), bold: true),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(64, 64),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
                onPressed: cart.isEmpty ? null : _bayar,
                child: const Text('Bayar & Cetak Struk'),
              ),
            ),
          ],
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool primary = false}) =>
      Padding(
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
                  size: 22,
                  color: primary ? Colors.white : AppColors.textDark),
            ),
          ),
        ),
      );

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l,
                  style: TextStyle(
                      fontSize: bold ? 19 : 15,
                      color: bold ? AppColors.textDark : AppColors.textMuted,
                      fontWeight:
                          bold ? FontWeight.w600 : FontWeight.w400)),
              Text(v,
                  style: TextStyle(
                      fontSize: bold ? 20 : 15,
                      fontWeight:
                          bold ? FontWeight.w600 : FontWeight.w500)),
            ]),
      );

  // ====== PEMBAYARAN + KEMBALIAN + SIMPAN TRANSAKSI ======
  void _bayar() {
    final cashCtrl = TextEditingController();
    double change = 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final paid = double.tryParse(cashCtrl.text) ?? 0;
          change = paid - total;
          return AlertDialog(
            title: const Text('Pembayaran'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _payRow('Total Belanja', rp(total), big: true),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cashCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600),
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Uang Diterima dari Pembeli',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    ),
                  ),
                  // tombol nominal cepat
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final n in [total, 5000, 10000, 20000, 50000, 100000])
                        OutlinedButton(
                          onPressed: () => setLocal(() =>
                              cashCtrl.text = n.round().toString()),
                          child: Text(n == total ? 'Uang Pas' : rp(n)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: change >= 0
                          ? AppColors.primaryLight
                          : const Color(0xFFFDE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        Text(change >= 0 ? rp(change) : 'Kurang ${rp(-change)}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: change >= 0
                                    ? AppColors.primary
                                    : AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50)),
                onPressed: change < 0
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _simpanTransaksi(paid: paid, change: change);
                      },
                child: const Text('Bayar & Cetak Struk'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _payRow(String l, String v, {bool big = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(fontSize: big ? 17 : 15)),
          Text(v,
              style: TextStyle(
                  fontSize: big ? 22 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ],
      );

  Future<void> _simpanTransaksi(
      {required double paid, required double change}) async {
    final db = ref.read(databaseProvider);
    final session = ref.read(authProvider);
    final invoiceNo = await db.nextInvoiceNo();
    final items = cart
        .map((c) => (
              productId: c.product.id,
              qty: c.qty.toDouble(),
              price: c.product.sellPrice,
              cost: c.product.costPrice,
            ))
        .toList();
    await db.createSale(
      userId: session?.user.id ?? 1,
      invoiceNo: invoiceNo,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paid: paid,
      change: change,
      items: items,
    );
    ref.invalidate(productsProvider);
    ref.invalidate(salesProvider);
    ref.invalidate(todaySummaryProvider);
    if (!mounted) return;
    final totalStr = rp(total);
    final paidStr = rp(paid);
    final changeStr = rp(change);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(Icons.check_circle, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text('Transaksi Berhasil'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No. Invoice: $invoiceNo'),
            const SizedBox(height: 8),
            Text('Total: $totalStr'),
            Text('Dibayar: $paidStr'),
            Text('Kembalian: $changeStr',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                cart.clear();
                _taxLocal = null;
              });
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return const Icon(Icons.fastfood, size: 50, color: AppColors.textMuted);
    }
    return Image.file(file,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.fastfood, size: 50, color: AppColors.textMuted));
  }
}