# ERD — Kasir Siswa

```
roles 1───* users 1───* sales *───1 members
                 │            │
                 │            *
                 │        sale_items *───1 products *───1 categories
                 │                                  *───1 units
                 *
              shifts 1───* sales

suppliers 1───* purchases 1───* purchase_items *───1 products
users     1───* purchases

products 1───* stock_movements        (mutasi stok: in/out/adjust/opname)
products 1───* promotions
users    1───* audit_logs
settings (key-value)
```

**Relasi utama**
- 1 user (kasir) memiliki banyak sale & shift.
- 1 sale punya banyak sale_items; tiap item merujuk 1 product.
- 1 purchase punya banyak purchase_items.
- Setiap penjualan/pembelian menghasilkan stock_movements untuk audit stok.
- Profit dihitung dari (sale_items.price - sale_items.cost) * qty.
