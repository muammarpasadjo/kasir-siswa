import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers.dart';
import '../../core/database/database.dart';

String rp(num v) => 'Rp ${v.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

// ============ RIWAYAT PENJUALAN ============
class SalesHistoryPage extends ConsumerWidget {
  const SalesHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Riwayat Penjualan'), backgroundColor: AppColors.surface),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada transaksi'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = items[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.receipt_long, color: AppColors.primary),
                      ),
                      title: Text(s.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year} ${s.createdAt.hour.toString().padLeft(2,'0')}:${s.createdAt.minute.toString().padLeft(2,'0')}'),
                      trailing: Text(rp(s.total), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ============ LAPORAN ============
class ReportPage extends ConsumerWidget {
  const ReportPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaySummaryProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Laporan'), backgroundColor: AppColors.surface),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: today.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (sum) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stat('Transaksi Hari Ini', '${sum.count}', Icons.receipt),
              const SizedBox(width: 18),
              _stat('Pendapatan Hari Ini', rp(sum.total), Icons.payments),
            ],
          ),
        ),
      ),
    );
  }
  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: AppColors.primary, size: 32),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

// ============ MEMBER ============
class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Member'),
        backgroundColor: AppColors.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
              onPressed: () => _form(context, ref),
              child: const Text('Tambah Member'),
            ),
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada member'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final m = items[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.person, color: AppColors.primary)),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${m.phone ?? '-'}  •  Poin: ${m.points}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () async {
                          await ref.read(databaseProvider).deleteMemberById(m.id);
                          ref.invalidate(membersProvider);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
  void _form(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final phone = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Member'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. HP', border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await ref.read(databaseProvider).upsertMember(MembersCompanion(
                name: Value(name.text.trim()),
                phone: Value(phone.text.trim().isEmpty ? null : phone.text.trim()),
              ));
              ref.invalidate(membersProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ============ PLACEHOLDER ============
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.surface),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 18),
          Text('Modul "$title"', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Sedang dalam pengembangan (tahap berikutnya).', style: TextStyle(color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}
