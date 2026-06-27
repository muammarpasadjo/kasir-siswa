import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bcrypt/bcrypt.dart';

part 'database.g.dart';

// ===== Tabel =====
class Roles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roleId => integer().references(Roles, #id)();
  TextColumn get username => text().unique()();
  TextColumn get fullName => text()();
  TextColumn get passwordHash => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get unitId => integer().nullable().references(Units, #id)();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0))();
  RealColumn get stock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
}

class Members extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNo => text().unique()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get memberId => integer().nullable().references(Members, #id)();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  RealColumn get paid => real().withDefault(const Constant(0))();
  RealColumn get change => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get qty => real()();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  @override
  Set<Column> get primaryKey => {key};
}

// ===== Database =====
@DriftDatabase(tables: [
  Roles, Users, Categories, Units, Products,
  Suppliers, Members, Sales, SaleItems, AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seed() async {
    final adminRole = await into(roles).insert(RolesCompanion.insert(name: 'admin'));
    await into(roles).insert(RolesCompanion.insert(name: 'kasir'));
    await into(roles).insert(RolesCompanion.insert(name: 'gudang'));

    for (final u in ['pcs', 'box', 'kg', 'liter']) {
      await into(units).insert(UnitsCompanion.insert(name: u));
    }
    final catId = await into(categories).insert(CategoriesCompanion.insert(name: 'Umum'));

    final hash = BCrypt.hashpw('admin123', BCrypt.gensalt());
    await into(users).insert(UsersCompanion.insert(
      roleId: adminRole,
      username: 'admin',
      fullName: 'Administrator',
      passwordHash: hash,
    ));

    final defaults = {
      'store_name': 'Kasir Siswa',
      'tax_percent': '11',
      'currency': 'Rp',
      'theme': 'light',
    };
    for (final e in defaults.entries) {
      await into(appSettings)
          .insert(AppSettingsCompanion.insert(key: e.key, value: Value(e.value)));
    }

    // Produk contoh
    final samples = <List<dynamic>>[
      ['Indomie Goreng', 2500, 3500],
      ['Aqua 600ml', 2800, 4000],
      ['Teh Botol', 3500, 5000],
      ['Chitato', 7000, 9500],
      ['Susu Ultra', 5500, 7000],
      ['Kopi Kapal Api', 1200, 2000],
      ['Roti Tawar', 11000, 14000],
      ['Sabun Lifebuoy', 3000, 4500],
      ['Pepsodent', 9000, 12000],
      ['Beras 1kg', 11000, 13000],
      ['Gula 1kg', 13500, 16000],
      ['Minyak 1L', 15500, 18000],
    ];
    for (final s in samples) {
      await into(products).insert(ProductsCompanion.insert(
        name: s[0] as String,
        categoryId: Value(catId),
        unitId: const Value(1),
        costPrice: Value((s[1] as int).toDouble()),
        sellPrice: Value((s[2] as int).toDouble()),
        stock: const Value(100),
        minStock: const Value(10),
      ));
    }
  }

  // ===== Query =====
  Future<User?> findUserByUsername(String username) =>
      (select(users)..where((u) => u.username.equals(username))).getSingleOrNull();

  Future<String?> roleName(int roleId) async {
    final r = await (select(roles)..where((x) => x.id.equals(roleId))).getSingleOrNull();
    return r?.name;
  }

  Future<List<Product>> getActiveProducts() =>
      (select(products)..where((p) => p.isActive.equals(true))).get();
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'kasir_siswa.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
