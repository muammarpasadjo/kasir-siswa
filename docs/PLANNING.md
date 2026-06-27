# KASIR SISWA — POS Desktop Modern
Dokumen Perencanaan & Arsitektur (STEP 1–10)

> Aplikasi Point of Sale (POS) Desktop setara Indomaret/Alfamart.
> Stack: **Flutter Desktop (Windows)** + **Drift (SQLite)** + **Riverpod** + **GoRouter**.
> Mode: **Offline-first**, single-machine, multi-user (role-based).

---

## STEP 1 — Analisis Kebutuhan

### 1.1 Tujuan Produk
Aplikasi kasir desktop yang cepat, stabil, modular, dan mudah dikembangkan untuk
minimarket, toko kelontong, apotek, toko bangunan, toko elektronik, dan retail umum.

### 1.2 Aktor / Role
| Role | Hak Akses |
|------|-----------|
| **Owner / Admin** | Semua modul, laporan, pengaturan, backup, audit log, manajemen user |
| **Kasir** | Transaksi penjualan, buka/tutup shift, lihat produk, cetak struk |
| **Gudang / Staff** | Produk, stok, pembelian, supplier (tanpa laporan keuangan) |

### 1.3 Kebutuhan Fungsional (Modul)
1. Autentikasi & Manajemen User (role-based)
2. Dashboard (ringkasan penjualan, stok menipis, grafik)
3. Master Produk (kategori, satuan, barcode, harga jual/beli, stok)
4. Master Supplier
5. Master Member / Pelanggan (poin, member)
6. Transaksi Penjualan (POS / kasir, scan barcode, diskon, pajak, multi-bayar)
7. Transaksi Pembelian (restock dari supplier)
8. Manajemen Stok (kartu stok, stok opname, penyesuaian)
9. Promosi & Diskon
10. Laporan (penjualan, pembelian, profit, kas, produk, supplier, kasir, member) + Export PDF/Excel/Print
11. Shift Kasir (buka shift, modal awal, tutup shift, selisih kas)
12. Backup & Restore Database (manual + otomatis terjadwal)
13. Audit Log (jejak aktivitas pengguna)
14. Pengaturan (identitas toko, pajak, printer, tema)
15. Cetak Struk (thermal/standard)

### 1.4 Kebutuhan Non-Fungsional
- **Performa**: pencarian produk & scan barcode < 100ms (index DB).
- **Stabilitas**: zero-crash, transaksi atomik (DB transaction).
- **Offline-first**: tidak butuh internet.
- **Keamanan**: password hashing (bcrypt/argon2), role-based access, audit log.
- **Skalabilitas**: arsitektur modular (clean architecture) agar mudah ditambah modul.
- **UX**: keyboard-first (kasir cepat), shortcut, dark/light mode.

---

## STEP 2 — Pemilihan Teknologi (dengan Alasan)

| Area | Pilihan | Alasan |
|------|---------|--------|
| Framework | **Flutter Desktop** | Satu codebase, UI modern & cepat, native desktop Windows |
| State Mgmt | **Riverpod** | Type-safe, testable, tanpa BuildContext, cocok skala besar |
| Database | **Drift (SQLite)** | ORM reaktif, query type-safe, migrasi terkelola, offline-first |
| Routing | **GoRouter** | Deklaratif, mendukung guard (role-based redirect) |
| DI | Riverpod Providers | Konsisten dengan state mgmt |
| PDF | **pdf + printing** | Generate & cetak struk/laporan |
| Excel | **excel / syncfusion_xlsio** | Export laporan |
| Chart | **fl_chart** | Grafik dashboard |
| Hashing | **bcrypt** | Keamanan password |
| Window | **window_manager** | Kontrol ukuran/fullscreen desktop |

---

## STEP 3 — Arsitektur Aplikasi (Clean Architecture + Feature-first)

```
lib/
├── main.dart
├── app/                  # App root, theme, router, konstanta
│   ├── app.dart
│   ├── router/
│   ├── theme/
│   └── constants/
├── core/                 # Util lintas fitur
│   ├── database/         # Drift database, DAO, tabel
│   ├── error/
│   ├── utils/            # formatter (rupiah, tanggal), validator
│   ├── services/         # printer, backup, pdf, excel
│   └── widgets/          # widget reusable (button, card, dialog)
└── features/             # Per modul (data / domain / presentation)
    ├── auth/
    ├── dashboard/
    ├── products/
    ├── suppliers/
    ├── members/
    ├── sales/            # POS / kasir
    ├── purchases/
    ├── stock/
    ├── promotions/
    ├── reports/
    ├── shift/
    ├── backup/
    ├── audit/
    └── settings/
```

Tiap feature: `data/` (repository, mapper) · `domain/` (entity, usecase) · `presentation/` (screen, widget, provider).

---

## STEP 4 — Alur Pengguna Utama (User Flow)

1. **Login** → pilih role → redirect sesuai hak akses.
2. **Buka Shift** (kasir) → input modal awal → mulai transaksi.
3. **Penjualan**: scan/cari produk → tambah ke keranjang → diskon/pajak → pilih pembayaran (tunai/qris/kartu) → simpan → cetak struk → stok berkurang otomatis.
4. **Pembelian**: pilih supplier → input produk masuk → stok bertambah → catat hutang/kas.
5. **Tutup Shift** → hitung kas fisik → sistem hitung selisih → simpan laporan shift.
6. **Laporan**: filter periode → tampil → export PDF/Excel/Print.
7. **Backup** otomatis harian + manual.

---

## STEP 5 — Desain Database (Skema Relasional)

Lihat file lengkap: `docs/DATABASE_SCHEMA.sql` dan `docs/ERD.md`.

Tabel inti:
`users, roles, categories, units, products, suppliers, members,
sales, sale_items, purchases, purchase_items, stock_movements,
promotions, shifts, payments, settings, audit_logs`.

---

## STEP 6 — Strategi Migrasi & Seed
- Drift schema versioning (`schemaVersion`), migrasi bertahap (`onUpgrade`).
- Seed awal: role default, user admin (admin/admin123 — wajib ganti), satuan dasar (pcs, box, kg), pengaturan toko default.

---

## STEP 7 — Design System / UI (mengacu screenshot referensi)

- **Layout 3 kolom** (seperti referensi Foodyoow):
  - Sidebar kiri: navigasi modul + toggle Dark/Light.
  - Konten tengah: grid produk (kartu gambar + nama + harga).
  - Panel kanan: keranjang/"My Order" (item, qty, subtotal, pajak, total, tombol bayar/cetak).
- **Warna**: primary merah/coral (`#F4512C`/`#EF4444`) sesuai referensi, netral abu-abu, putih bersih.
- **Komponen**: kartu rounded-xl, shadow lembut, tipografi jelas, ikon konsisten.
- **Responsif desktop**: minimal 1280×800, grid adaptif.
- **Mode gelap/terang** penuh.

---

## STEP 8 — Keamanan
- Password di-hash (bcrypt) + salt.
- Role-based route guard (GoRouter redirect).
- Audit log untuk aksi kritikal (hapus, ubah harga, void transaksi).
- Backup terenkripsi opsional.

---

## STEP 9 — Testing & QA
- Unit test: util (formatter, kalkulasi total/pajak/diskon), repository.
- Widget test: form login, keranjang.
- Integration test: alur penjualan end-to-end.
- Manual QA checklist per modul.

---

## STEP 10 — DevOps & Distribusi
- Git + GitHub (repo: kasir-siswa).
- Branching: `main` (stabil) + `dev`.
- Build rilis: `flutter build windows` → installer via MSIX (`msix` package).
- CI opsional (GitHub Actions: analyze + test).

---

## STEP 11 — Roadmap Implementasi Bertahap (per Modul)
> Dikerjakan satu per satu, dipastikan jalan & bebas error sebelum lanjut.

1. Setup project + database core + theme + router  ✅ (fondasi)
2. Modul Auth + seed admin + login screen
3. Layout utama (shell 3 kolom) + dashboard
4. Master Produk + Kategori + Satuan
5. Master Supplier + Member
6. Modul Penjualan (POS) — inti aplikasi
7. Modul Pembelian + Stok
8. Shift Kasir + Pembayaran
9. Promosi & Diskon
10. Laporan + Export PDF/Excel/Print
11. Backup/Restore + Audit Log + Settings + Cetak Struk
12. Polish UI, testing, build rilis (MSIX)

---
*Dokumen ini adalah acuan pengembangan. Setiap keputusan mengutamakan UX, performa, dan kemudahan pengembangan jangka panjang.*
