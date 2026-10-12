-- ============================================================================
-- SOAL 3.2: Mekanisme Jejak Audit (Audit Trail, Immutability & Hash Checksum)
-- File: Kode SQL/soal-3/01-audit-trail.sql
-- ============================================================================

-- 1. Penambahan Kolom Metadata Audit pada Header Jurnal
ALTER TABLE journal_headers ADD COLUMN IF NOT EXISTS created_by VARCHAR(100) DEFAULT current_user;
ALTER TABLE journal_headers ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE journal_headers ADD COLUMN IF NOT EXISTS hash_checksum VARCHAR(64);

-- 2. Fungsi Trigger Immutability (Mencegah UPDATE/DELETE pada Jurnal yang sudah POSTED)
CREATE OR REPLACE FUNCTION prevent_posted_journal_modification()
RETURNS TRIGGER AS $$
BEGIN
    -- Jika status lama (OLD) sudah 'POSTED', tolak total segala bentuk perubahan atau penghapusan
    IF OLD.posting_status = 'POSTED' THEN
        RAISE EXCEPTION 'AUDIT VIOLATION: Jurnal dengan ID % sudah berstatus POSTED dan bersifat IMMUTABLE. Perubahan atau penghapusan dilarang keras. Gunakan Jurnal Pembalik (Storno).', OLD.header_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tautkan Trigger ke tabel journal_headers
DROP TRIGGER IF EXISTS trg_immutable_posted_journal ON journal_headers;
CREATE TRIGGER trg_immutable_posted_journal
BEFORE UPDATE OR DELETE ON journal_headers
FOR EACH ROW
EXECUTE FUNCTION prevent_posted_journal_modification();