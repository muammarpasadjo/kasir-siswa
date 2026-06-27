-- KASIR SISWA — Skema Database (SQLite)
-- Referensi desain. Implementasi nyata via Drift (lib/core/database/).

PRAGMA foreign_keys = ON;

-- ===== Master / Auth =====
CREATE TABLE roles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE              -- admin, kasir, gudang
);

CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  role_id INTEGER NOT NULL REFERENCES roles(id),
  username TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE              -- pcs, box, kg, liter
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sku TEXT UNIQUE,
  barcode TEXT UNIQUE,
  name TEXT NOT NULL,
  category_id INTEGER REFERENCES categories(id),
  unit_id INTEGER REFERENCES units(id),
  cost_price REAL NOT NULL DEFAULT 0,   -- harga beli
  sell_price REAL NOT NULL DEFAULT 0,   -- harga jual
  stock REAL NOT NULL DEFAULT 0,
  min_stock REAL NOT NULL DEFAULT 0,
  image_path TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_name ON products(name);

CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT, address TEXT, note TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  phone TEXT,
  points INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ===== Shift Kasir =====
CREATE TABLE shifts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id),
  opening_cash REAL NOT NULL DEFAULT 0,
  closing_cash REAL,
  expected_cash REAL,
  difference REAL,
  opened_at TEXT NOT NULL DEFAULT (datetime('now')),
  closed_at TEXT,
  status TEXT NOT NULL DEFAULT 'open'   -- open, closed
);

-- ===== Penjualan =====
CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_no TEXT NOT NULL UNIQUE,
  user_id INTEGER NOT NULL REFERENCES users(id),
  member_id INTEGER REFERENCES members(id),
  shift_id INTEGER REFERENCES shifts(id),
  subtotal REAL NOT NULL DEFAULT 0,
  discount REAL NOT NULL DEFAULT 0,
  tax REAL NOT NULL DEFAULT 0,
  total REAL NOT NULL DEFAULT 0,
  paid REAL NOT NULL DEFAULT 0,
  change REAL NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'cash', -- cash, qris, card
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_sales_created ON sales(created_at);

CREATE TABLE sale_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  qty REAL NOT NULL,
  price REAL NOT NULL,           -- harga jual saat transaksi
  cost REAL NOT NULL DEFAULT 0,  -- harga beli (untuk profit)
  discount REAL NOT NULL DEFAULT 0,
  subtotal REAL NOT NULL
);

-- ===== Pembelian =====
CREATE TABLE purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ref_no TEXT NOT NULL UNIQUE,
  supplier_id INTEGER REFERENCES suppliers(id),
  user_id INTEGER NOT NULL REFERENCES users(id),
  total REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'done',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE purchase_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  purchase_id INTEGER NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  qty REAL NOT NULL,
  cost REAL NOT NULL,
  subtotal REAL NOT NULL
);

-- ===== Stok (kartu stok / mutasi) =====
CREATE TABLE stock_movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id),
  type TEXT NOT NULL,            -- in, out, adjust, opname
  qty REAL NOT NULL,             -- + masuk / - keluar
  ref_type TEXT,                 -- sale, purchase, manual
  ref_id INTEGER,
  note TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ===== Promosi =====
CREATE TABLE promotions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,            -- percent, nominal
  value REAL NOT NULL,
  product_id INTEGER REFERENCES products(id),
  start_date TEXT, end_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1
);

-- ===== Pengaturan & Audit =====
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  action TEXT NOT NULL,
  detail TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ===== Seed awal =====
INSERT INTO roles(name) VALUES ('admin'),('kasir'),('gudang');
INSERT INTO units(name) VALUES ('pcs'),('box'),('kg'),('liter');
INSERT INTO settings(key,value) VALUES
  ('store_name','Kasir Siswa'),
  ('tax_percent','11'),
  ('currency','Rp'),
  ('theme','light');
-- user admin default (hash di-generate di aplikasi): admin / admin123
