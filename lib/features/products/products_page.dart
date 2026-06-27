import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/database/database.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  String rp(num v) =>
      'Rp ${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Master Produk',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(56, 52),
              ),
              onPressed: () => _openForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada produk'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.inventory_2, color: AppColors.primary),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17)),
                      subtitle: Text(
                          'Stok: ${p.stock.toStringAsFixed(0)}  •  Modal: ${rp(p.costPrice)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(rp(p.sellPrice),
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.textMuted),
                            onPressed: () => _openForm(context, ref, product: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.danger),
                            onPressed: () => _confirmDelete(context, ref, p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin menghapus "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(databaseProvider).deleteProductById(p.id);
      ref.invalidate(productsProvider);
    }
  }

  void _openForm(BuildContext context, WidgetRef ref, {Product? product}) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(product: product),
    );
  }
}

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.product});
  final Product? product;
  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _barcode;
  late final TextEditingController _cost;
  late final TextEditingController _sell;
  late final TextEditingController _stock;
  late final TextEditingController _minStock;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _cost = TextEditingController(text: p?.costPrice.toStringAsFixed(0) ?? '');
    _sell = TextEditingController(text: p?.sellPrice.toStringAsFixed(0) ?? '');
    _stock = TextEditingController(text: p?.stock.toStringAsFixed(0) ?? '0');
    _minStock = TextEditingController(text: p?.minStock.toStringAsFixed(0) ?? '0');
  }

  @override
  void dispose() {
    for (final c in [_name, _barcode, _cost, _sell, _stock, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Nama produk wajib diisi');
      return;
    }
    final db = ref.read(databaseProvider);
    final companion = ProductsCompanion(
      id: widget.product == null ? const Value.absent() : Value(widget.product!.id),
      name: Value(_name.text.trim()),
      barcode: Value(_barcode.text.trim().isEmpty ? null : _barcode.text.trim()),
      costPrice: Value(double.tryParse(_cost.text) ?? 0),
      sellPrice: Value(double.tryParse(_sell.text) ?? 0),
      stock: Value(double.tryParse(_stock.text) ?? 0),
      minStock: Value(double.tryParse(_minStock.text) ?? 0),
      categoryId: widget.product == null ? const Value(1) : Value(widget.product!.categoryId),
      unitId: widget.product == null ? const Value(1) : Value(widget.product!.unitId),
    );
    await db.upsertProduct(companion);
    ref.invalidate(productsProvider);
    if (mounted) Navigator.pop(context);
  }

  Widget _field(String label, TextEditingController c,
          {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Nama Produk', _name),
              _field('Barcode (opsional)', _barcode),
              Row(children: [
                Expanded(child: _field('Harga Modal', _cost, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Harga Jual', _sell, number: true)),
              ]),
              Row(children: [
                Expanded(child: _field('Stok', _stock, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Stok Minimum', _minStock, number: true)),
              ]),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}