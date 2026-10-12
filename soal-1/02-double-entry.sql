-- ============================================================================
-- SOAL 1.2: Trigger Penegakan Asas Berpasangan (Double-Entry Constraint)
-- File: Kode SQL/soal-1/02-double-entry.sql
-- ============================================================================

-- Fungsi Trigger untuk memastikan jurnal berstatus 'POSTED' seimbang (Debit = Kredit)
CREATE OR REPLACE FUNCTION assert_posted_journal_balanced()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE 
    h_id INT; 
    st VARCHAR(20); 
    n INT; 
    d NUMERIC(15,2); 
    c NUMERIC(15,2);
BEGIN
    -- Tentukan ID Header berdasarkan tabel pemicu
    IF TG_TABLE_NAME = 'journal_headers' THEN 
        h_id := COALESCE(NEW.header_id, OLD.header_id);
    ELSE 
        h_id := COALESCE(NEW.header_id, OLD.header_id); 
    END IF;

    -- Ambil status posting dari header jurnal
    SELECT posting_status INTO st FROM journal_headers WHERE header_id = h_id;
    IF NOT FOUND THEN 
        RETURN NULL; 
    END IF;

    -- Validasi hanya dijalankan jika status jurnal adalah 'POSTED'
    IF st = 'POSTED' THEN
        SELECT COUNT(*), COALESCE(SUM(debit), 0), COALESCE(SUM(credit), 0)
        INTO n, d, c 
        FROM journal_lines 
        WHERE header_id = h_id;

        -- Syarat 1: Harus ada minimal 2 baris jurnal (1 Debit & 1 Kredit)
        IF n < 2 THEN 
            RAISE EXCEPTION 'Jurnal ID % gagal diposting: Minimal harus terdiri dari 2 baris transaksi.', h_id; 
        END IF;

        -- Syarat 2: Total Debit harus sama persis dengan Total Kredit
        IF d <> c THEN 
            RAISE EXCEPTION 'Jurnal ID % tidak seimbang: Total Debit (Rp %) tidak sama dengan Total Kredit (Rp %).', h_id, d, c; 
        END IF;
    END IF;

    RETURN NULL;
END $$;

-- Tautkan Deferred Constraint Trigger ke tabel journal_headers
DROP TRIGGER IF EXISTS ct_journal_header_balance ON journal_headers;
CREATE CONSTRAINT TRIGGER ct_journal_header_balance 
AFTER INSERT OR UPDATE ON journal_headers
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION assert_posted_journal_balanced();

-- Tautkan Deferred Constraint Trigger ke tabel journal_lines
DROP TRIGGER IF EXISTS ct_journal_line_balance ON journal_lines;
CREATE CONSTRAINT TRIGGER ct_journal_line_balance 
AFTER INSERT OR UPDATE OR DELETE ON journal_lines
DEFERRABLE INITIALLY DEFERRED 
FOR EACH ROW EXECUTE FUNCTION assert_posted_journal_balanced();