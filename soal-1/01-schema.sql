-- ============================================================================
-- SOAL 1.1 & 1.2: DDL Schema Tabel General Ledger (Buku Besar)
-- File: Kode SQL/soal-1/01-schema.sql
-- ============================================================================

-- 1. Tabel Chart of Accounts (Bagan Akun Master)
CREATE TABLE IF NOT EXISTS chart_of_accounts (
    account_id SERIAL PRIMARY KEY,
    account_code VARCHAR(20) NOT NULL UNIQUE,
    account_name VARCHAR(150) NOT NULL,
    normal_balance VARCHAR(1) NOT NULL CHECK (normal_balance IN ('D', 'K')),
    report_class VARCHAR(50) NOT NULL CHECK (report_class IN ('NERACA', 'LABA_RUGI'))
);

-- 2. Tabel Journal Headers (Kepala Jurnal Transaksi)
CREATE TABLE IF NOT EXISTS journal_headers (
    header_id SERIAL PRIMARY KEY,
    trx_date DATE NOT NULL DEFAULT CURRENT_DATE,
    ref_no VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    posting_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' 
        CHECK (posting_status IN ('DRAFT', 'POSTED', 'REVERSED'))
);

-- 3. Tabel Journal Lines (Rincian Debit / Kredit)
CREATE TABLE IF NOT EXISTS journal_lines (
    line_id SERIAL PRIMARY KEY,
    header_id INT NOT NULL,
    account_id INT NOT NULL,
    debit NUMERIC(15, 2) NOT NULL DEFAULT 0.00,
    credit NUMERIC(15, 2) NOT NULL DEFAULT 0.00,

    -- Foreign Key Constraint (ON DELETE RESTRICT untuk keamanan audit)
    CONSTRAINT fk_lines_header FOREIGN KEY (header_id) 
        REFERENCES journal_headers(header_id) ON DELETE RESTRICT,
    CONSTRAINT fk_lines_account FOREIGN KEY (account_id) 
        REFERENCES chart_of_accounts(account_id) ON DELETE RESTRICT,

    -- Constraint Integritas Akuntansi dasar
    CONSTRAINT chk_debit_nonneg CHECK (debit >= 0),
    CONSTRAINT chk_credit_nonneg CHECK (credit >= 0),
    CONSTRAINT chk_not_both_zero CHECK (debit > 0 OR credit > 0)
);

-- Indexing untuk mempercepat query saldo
CREATE INDEX IF NOT EXISTS idx_lines_header ON journal_lines(header_id);
CREATE INDEX IF NOT EXISTS idx_lines_account ON journal_lines(account_id);