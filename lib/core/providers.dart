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
