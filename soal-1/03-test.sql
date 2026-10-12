-- ============================================================================
-- SOAL 1.3: Data Dummy & Script Pengujian Integritas Jurnal
-- File: Kode SQL/soal-1/03-test.sql
-- ============================================================================

-- 1. Insert Master Akun
INSERT INTO chart_of_accounts (account_code, account_name, normal_balance, report_class) VALUES
('1-1000', 'Kas Utama', 'D', 'NERACA'),
('1-1300', 'Persediaan Barang Dagang', 'D', 'NERACA'),
('5-1100', 'Beban Pokok Pendapatan (HPP)', 'D', 'LABA_RUGI'),
('4-1000', 'Pendapatan Penjualan', 'K', 'LABA_RUGI')
ON CONFLICT (account_code) DO NOTHING;

-- 2. Uji Coba Insert Jurnal Seimbang (Harus Berhasil)
INSERT INTO journal_headers (header_id, ref_no, description, posting_status) VALUES
(100, 'INV-2026-001', 'Penjualan Pizza Tunai', 'POSTED')
ON CONFLICT DO NOTHING;

INSERT INTO journal_lines (header_id, account_id, debit, credit) VALUES
(100, 1, 150000.00, 0.00),   -- Kas Debit 150rb
(100, 4, 0.00, 150000.00)    -- Pendapatan Kredit 150rb
ON CONFLICT DO NOTHING;