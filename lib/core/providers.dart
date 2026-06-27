import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
