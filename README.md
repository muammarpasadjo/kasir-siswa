# Kasir Siswa — POS Desktop Modern

Aplikasi **Point of Sale (POS)** desktop (Windows) setara minimarket, dibuat dengan
**Flutter Desktop + Drift (SQLite) + Riverpod + GoRouter**. Offline-first, modular, role-based.

## Fitur (15 Modul)
Auth & User · Dashboard · Produk · Supplier · Member · Penjualan (POS) ·
Pembelian · Stok · Promosi · Laporan (PDF/Excel/Print) · Shift Kasir ·
Backup/Restore · Audit Log · Pengaturan · Cetak Struk.

## Dokumentasi
- `docs/PLANNING.md` — analisis & arsitektur (STEP 1–10)
- `docs/DATABASE_SCHEMA.sql` — skema database
- `docs/ERD.md` — diagram relasi

## Menjalankan (Prasyarat: Flutter SDK + Visual Studio C++ untuk Windows desktop)
```bash
# 1. Generate runner platform Windows (sekali saja)
flutter create . --platforms=windows

# 2. Install dependency
flutter pub get

# 3. Generate kode Drift
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan
flutter run -d windows
```

## Build Rilis
```bash
flutter build windows
```

## Login Default
- Username: `admin` · Password: `admin123` (wajib diganti setelah login)

## Status
🚧 Dalam pengembangan bertahap (lihat STEP 11 di PLANNING.md).
