-- QUERY ANGGOTA 2 - MUHAMMAD NAUFAL HADAYA SETIAWAN (5025241181)

-- 1. QUERY SEARCHING (JOIN) #1
-- Slot waktu paling ramai pada tanggal tertentu untuk membantu kantin menyiapkan kapasitas layanan

SELECT
    po.tanggal_ambil,
    k.nama_kantin,
    k.lokasi,
    sw.label AS sesi,
    sw.jam_mulai,
    sw.jam_selesai,
    sw.kapasitas_order,
    COUNT(po.id_pre_order) AS total_order,
    ROUND((COUNT(po.id_pre_order)::DECIMAL / sw.kapasitas_order) * 100, 2) AS persentase_pemakaian_kapasitas
FROM pre_order po
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
WHERE po.status NOT IN ('cancelled')
  AND po.tanggal_ambil = DATE '2026-05-28'
GROUP BY po.tanggal_ambil, k.nama_kantin, k.lokasi, sw.label, sw.jam_mulai, sw.jam_selesai, sw.kapasitas_order
ORDER BY total_order DESC;

-- 2. QUERY SEARCHING (JOIN) #2
-- Revenue per kantin per bulan (pendapatan bulanan)
SELECT 
    k.nama_kantin,
    k.lokasi,
    TO_CHAR(po.tanggal_ambil, 'YYYY-MM') AS bulan,
    COUNT(po.id_pre_order) AS jumlah_order,
    SUM(po.total_harga) AS total_revenue,
    ROUND(AVG(po.total_harga), 2) AS rata_rata_order
FROM Kantin k
JOIN Sesi_Waktu sw ON k.id_kantin = sw.Kantin_id_kantin
JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo
JOIN pembayaran pb ON po.id_pre_order = pb.pre_order_id_pre
WHERE po.status_bayar = 'paid'
GROUP BY k.nama_kantin, k.lokasi, TO_CHAR(po.tanggal_ambil, 'YYYY-MM')
ORDER BY k.nama_kantin, bulan;

-- 3. VIEW #1
-- v_status_pembayaran: Status pembayaran lengkap dengan detail order dan gateway
CREATE OR REPLACE VIEW v_status_pembayaran AS
SELECT 
    pb.id_pembayaran,
    po.kode_order,
    m.nama AS nama_mahasiswa,
    pb.metode,
    pg.nama AS nama_gateway,
    pg.tipe AS tipe_gateway,
    pb.status AS status_pembayaran,
    pb.jumlah,
    pb.kode_unik,
    pb.expired_at,
    pb.paid_at,
    po.status AS status_order,
    po.total_harga
FROM pembayaran pb
JOIN pre_order po ON pb.pre_order_id_pre = po.id_pre_order
JOIN mahasiswa m ON po.mahasiswa_id_us = m.id_user
JOIN Payment_gateway pg ON pb.Payment_gateway = pg.id_metode
ORDER BY pb.expired_at DESC;

-- 4. VIEW #2
-- v_kantin_rating: Kantin dengan rating, jumlah order, dan pemilik

CREATE OR REPLACE VIEW v_kantin_rating AS
SELECT 
    k.id_kantin,
    k.nama_kantin,
    k.lokasi,
    k.rating,
    pk.nama AS nama_pemilik,
    pk.no_hp AS kontak_pemilik,
    k.jam_buka,
    k.jam_tutup,
    COUNT(DISTINCT po.id_pre_order) AS total_order,
    COALESCE(SUM(po.total_harga), 0) AS total_pendapatan
FROM Kantin k
JOIN Pemilik_Kantin pk ON k.Pemilik_Kantin_id_p = pk.id_pemilik
LEFT JOIN Sesi_Waktu sw ON k.id_kantin = sw.Kantin_id_kantin
LEFT JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo AND po.status = 'completed'
GROUP BY k.id_kantin, k.nama_kantin, k.lokasi, k.rating, 
         pk.nama, pk.no_hp, k.jam_buka, k.jam_tutup
ORDER BY k.rating DESC;

-- 5. TRIGGER #1
-- trg_auto_expired_bayar: Set expired_at otomatis 24 jam setelah pembayaran dibuat

CREATE OR REPLACE FUNCTION fn_trg_auto_expired_bayar()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.expired_at IS NULL THEN
        NEW.expired_at := CURRENT_TIMESTAMP + INTERVAL '24 hours';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auto_expired_bayar
BEFORE INSERT ON pembayaran
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auto_expired_bayar();

-- 6. TRIGGER #2
-- trg_log_status_change: Log setiap perubahan status order ke tabel log

CREATE OR REPLACE FUNCTION fn_trg_log_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO log_status_order (id_pre_order, status_lama, status_baru, changed_at)
        VALUES (NEW.id_pre_order, OLD.status, NEW.status, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_log_status_change
AFTER UPDATE OF status ON pre_order
FOR EACH ROW
EXECUTE FUNCTION fn_trg_log_status_change();

-- 7. FUNCTION #1
-- fn_cek_kapasitas_slot: Cek sisa kapasitas slot pada tanggal tertentu

CREATE OR REPLACE FUNCTION fn_cek_kapasitas_slot(
    p_id_slot VARCHAR,
    p_tanggal DATE
)
RETURNS TABLE(
    id_slot VARCHAR,
    label TEXT,
    nama_kantin TEXT,
    kapasitas_total INT,
    terisi INT,
    sisa_kapasitas INT,
    is_tersedia BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sw.id_slot,
        sw.label,
        k.nama_kantin,
        sw.kapasitas_order,
        COALESCE(COUNT(po.id_pre_order)::INT, 0),
        (sw.kapasitas_order - COALESCE(COUNT(po.id_pre_order)::INT, 0)),
        (sw.kapasitas_order - COALESCE(COUNT(po.id_pre_order)::INT, 0)) > 0
    FROM Sesi_Waktu sw
    JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
    LEFT JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo 
        AND po.tanggal_ambil = p_tanggal
        AND po.status NOT IN ('cancelled')
    WHERE sw.id_slot = p_id_slot
      AND sw.is_active = TRUE
    GROUP BY sw.id_slot, sw.label, k.nama_kantin, sw.kapasitas_order;
END;
$$ LANGUAGE plpgsql;

-- Contoh pemanggilan:
-- SELECT * FROM fn_cek_kapasitas_slot('SLT001', '2026-05-15');

-- 8. PROCEDURE #1
-- sp_proses_pembayaran: Procedure memproses pembayaran dan update status order

CREATE OR REPLACE PROCEDURE sp_proses_pembayaran(
    p_id_pembayaran VARCHAR,
    p_status_baru VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_pre_order_id VARCHAR;
    v_jumlah_bayar DECIMAL(13,2);
    v_total_harga DECIMAL(13,2);
BEGIN
    -- Validasi status
    IF p_status_baru NOT IN ('success', 'failed', 'expired') THEN
        RAISE EXCEPTION 'Status pembayaran tidak valid: %. Gunakan: success, failed, expired', p_status_baru;
    END IF;
    
    -- Ambil data pembayaran
    SELECT pre_order_id_pre, jumlah 
    INTO v_pre_order_id, v_jumlah_bayar
    FROM pembayaran
    WHERE id_pembayaran = p_id_pembayaran;
    
    IF v_pre_order_id IS NULL THEN
        RAISE EXCEPTION 'Pembayaran % tidak ditemukan', p_id_pembayaran;
    END IF;
    
    -- Update status pembayaran
    UPDATE pembayaran 
    SET status = p_status_baru,
        paid_at = CASE WHEN p_status_baru = 'success' THEN CURRENT_TIMESTAMP ELSE paid_at END
    WHERE id_pembayaran = p_id_pembayaran;
    
    -- Update status order berdasarkan pembayaran
    IF p_status_baru = 'success' THEN
        UPDATE pre_order 
        SET status_bayar = 'paid',
            status = 'confirmed',
            updated_at = CURRENT_TIMESTAMP
        WHERE id_pre_order = v_pre_order_id;
        
        RAISE NOTICE 'Pembayaran % berhasil. Order % dikonfirmasi.', p_id_pembayaran, v_pre_order_id;
    ELSIF p_status_baru = 'failed' OR p_status_baru = 'expired' THEN
        UPDATE pre_order
        SET status_bayar = p_status_baru,
            updated_at = CURRENT_TIMESTAMP
        WHERE id_pre_order = v_pre_order_id;
        
        RAISE NOTICE 'Pembayaran % gagal/expired. Order % diupdate.', p_id_pembayaran, v_pre_order_id;
    END IF;
END;
$$;

-- Contoh pemanggilan:
-- CALL sp_proses_pembayaran('PBY-PRE001-123', 'success');
