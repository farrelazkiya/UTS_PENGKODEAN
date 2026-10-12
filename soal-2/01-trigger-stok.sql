-- ============================================================================
-- SOAL 2.1: Database Trigger Otomasi Mutasi Persediaan & Anti-Negative Stock
-- File: Kode SQL/soal-2/01-trigger-stok.sql
-- ============================================================================

-- 1. Struktur Tabel Persediaan Sesuai Naskah UTS
CREATE TABLE IF NOT EXISTS inventory_items (
    item_id VARCHAR(10) PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_qty INT NOT NULL DEFAULT 0,
    unit_cost NUMERIC(15, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
    trx_id SERIAL PRIMARY KEY,
    item_id VARCHAR(10) REFERENCES inventory_items(item_id) ON DELETE RESTRICT,
    trx_type VARCHAR(10) CHECK (trx_type IN ('PURCHASE', 'SALE', 'ADJUSTMENT')),
    qty INT NOT NULL,
    trx_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Trigger Function untuk Pembaruan Stok Otomatis & Cegah Stok Negatif
CREATE OR REPLACE FUNCTION trg_update_stock_and_journal()
RETURNS TRIGGER AS $$
DECLARE
    v_current_stock INT;
    v_new_stock INT;
BEGIN
    -- Mengambil stok saat ini dengan Row-Level Lock (SELECT ... FOR UPDATE)
    SELECT stock_qty INTO v_current_stock 
    FROM inventory_items 
    WHERE item_id = NEW.item_id 
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item ID % tidak ditemukan di master persediaan.', NEW.item_id;
    END IF;

    -- Hitung saldo baru berdasarkan tipe transaksi
    IF NEW.trx_type = 'PURCHASE' THEN
        v_new_stock := v_current_stock + NEW.qty;
    ELSIF NEW.trx_type = 'SALE' THEN
        v_new_stock := v_current_stock - NEW.qty;
    ELSIF NEW.trx_type = 'ADJUSTMENT' THEN
        -- Adjustment dapat bernilai positif atau negatif
        v_new_stock := v_current_stock + NEW.qty;
    END IF;

    -- Poin 2.1b: Proteksi Stok Negatif (Anti-Overselling)
    IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'TRANSAKSI GAGAL: Stok % tidak mencukupi. Sisa stok: %, Diminta: %', 
            NEW.item_id, v_current_stock, NEW.qty;
    END IF;

    -- Poin 2.1a: Pembaruan Otomatis Kolom stock_qty
    UPDATE inventory_items 
    SET stock_qty = v_new_stock 
    WHERE item_id = NEW.item_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Tautkan Trigger ke Tabel Transaksi Persediaan
DROP TRIGGER IF EXISTS trg_inventory_mutasi ON inventory_transactions;
CREATE TRIGGER trg_inventory_mutasi
BEFORE INSERT ON inventory_transactions
FOR EACH ROW
EXECUTE FUNCTION trg_update_stock_and_journal();