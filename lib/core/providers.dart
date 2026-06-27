import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_colors.dart';
import 'database/database.dart';

/// Instance database tunggal.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Pengguna yang sedang login + nama role.
class SessionUser {
  final User user;
  final String role;
  const SessionUser(this.user, this.role);
}

class AuthController extends StateNotifier<SessionUser?> {
  AuthController(this._db) : super(null);
  final AppDatabase _db;

  /// Mengembalikan null jika sukses, atau pesan error jika gagal.
  Future<String?> login(String username, String password) async {
    final u = await _db.findUserByUsername(username.trim());
    if (u == null || !u.isActive) return 'Pengguna tidak ditemukan';
    if (!BCrypt.checkpw(password, u.passwordHash)) return 'Password salah';
    final role = await _db.roleName(u.roleId) ?? '-';
    state = SessionUser(u, role);
    return null;
  }

  void logout() => state = null;
}

final authProvider =
    StateNotifierProvider<AuthController, SessionUser?>((ref) {
  return AuthController(ref.watch(databaseProvider));
});

/// Daftar produk aktif dari database.
final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(databaseProvider).getActiveProducts();
});


/// Pengaturan tema warna (indeks palet). Disimpan di tabel settings.
class ThemeController extends StateNotifier<int> {
  ThemeController(this._db) : super(0) {
    _load();
  }
  final AppDatabase _db;

  Future<void> _load() async {
    final v = await _db.getSetting('palette');
    final i = int.tryParse(v ?? '0') ?? 0;
    final idx = (i >= 0 && i < appPalettes.length) ? i : 0;
    _apply(idx);
    state = idx;
  }

  void _apply(int i) {
    AppColors.primary = appPalettes[i].primary;
    AppColors.primaryLight = appPalettes[i].primaryLight;
  }

  Future<void> setPalette(int i) async {
    if (i < 0 || i >= appPalettes.length) return;
    _apply(i);
    state = i;
    await _db.setSetting('palette', '$i');
  }
}

final themeProvider =
    StateNotifierProvider<ThemeController, int>((ref) {
  return ThemeController(ref.watch(databaseProvider));
});

/// Daftar kategori.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).getCategories();
});
/// Path logo aplikasi (file) — bisa diganti admin. null = pakai default.
class LogoController extends StateNotifier<String?> {
  LogoController(this._db) : super(null) {
    _load();
  }
  final AppDatabase _db;
  Future<void> _load() async {
    state = await _db.getSetting('logo_path');
  }
  Future<void> setLogo(String? path) async {
    state = path;
    await _db.setSetting('logo_path', path ?? '');
  }
}

final logoProvider =
    StateNotifierProvider<LogoController, String?>((ref) {
  return LogoController(ref.watch(databaseProvider));
});

/// Apakah pajak diaktifkan secara default (admin bisa atur). Default: mati.
class TaxController extends StateNotifier<bool> {
  TaxController(this._db) : super(false) {
    _load();
  }
  final AppDatabase _db;
  Future<void> _load() async {
    state = (await _db.getSetting('tax_enabled')) == '1';
  }
  Future<void> setEnabled(bool v) async {
    state = v;
    await _db.setSetting('tax_enabled', v ? '1' : '0');
  }
}

final taxEnabledProvider =
    StateNotifierProvider<TaxController, bool>((ref) {
  return TaxController(ref.watch(databaseProvider));
});

/// Riwayat penjualan.
final salesProvider = FutureProvider<List<Sale>>((ref) {
  return ref.watch(databaseProvider).getSales();
});

/// Daftar member.
final membersProvider = FutureProvider<List<Member>>((ref) {
  return ref.watch(databaseProvider).getMembers();
});

/// Ringkasan penjualan hari ini.
final todaySummaryProvider =
    FutureProvider<({int count, double total})>((ref) {
  return ref.watch(databaseProvider).todaySummary();
});
