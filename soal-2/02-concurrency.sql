-- ============================================================================
-- SOAL 2.2: Penanganan Concurrency (Race Condition / Phantom Stock)
-- File: Kode SQL/soal-2/02-concurrency.sql
-- ============================================================================

/*
  DOKUMENTASI SOLUSI CONCURRENCY:
  Masalah: Dua kasir memproses penjualan item yang sama secara bersamaan ketika stok tinggal 1 unit.
  Tanpa kuncian, keduanya membaca stok = 1, sehingga kedua transaksi lolos (stok menjadi -1 / overselling).

  Solusi Utama: Pessimistic Locking (SELECT ... FOR UPDATE)
  Dengan klausa FOR UPDATE, transaksi pertama mengunci baris barang. 
  Transaksi kedua dipaksa menunggu (WAIT) sampai transaksi pertama COMMIT/ROLLBACK.
  Setelah Transaksi 1 selesai (stok menjadi 0), Transaksi 2 membaca stok terbaru (0) 
  dan langsung digagalkan oleh trigger dengan RAISE EXCEPTION.
*/

-- SOLUSI 1: Simulasi Transaksi Kasir A (Pessimistic Locking via SELECT ... FOR UPDATE)
BEGIN;
SELECT stock_qty FROM inventory_items WHERE item_id = 'PZ-001' FOR UPDATE;
INSERT INTO inventory_transactions (item_id, trx_type, qty) VALUES ('PZ-001', 'SALE', 1);
COMMIT;

-- SOLUSI 2: Alternatif Menggunakan Transaction Isolation Level SERIALIZABLE
-- (Database membatalkan salah satu transaksi jika terjadi bentrokan)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO inventory_transactions (item_id, trx_type, qty) VALUES ('PZ-001', 'SALE', 1);
COMMIT;

-- SOLUSI 3: Pertahanan Terakhir di Level Tabel (Database Hard-Constraint)
ALTER TABLE inventory_items 
DROP CONSTRAINT IF EXISTS chk_stock_non_negative;

ALTER TABLE inventory_items 
ADD CONSTRAINT chk_stock_non_negative CHECK (stock_qty >= 0);