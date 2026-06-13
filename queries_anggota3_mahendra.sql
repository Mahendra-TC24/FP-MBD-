-- QUERY ANGGOTA 3 - MAHENDRA AGUNG D (5025241032)
-- Final Project K-RUN - Manajemen Basis Data (B)


-- 1. QUERY SEARCHING (JOIN) #1
-- Kantin dengan menu terbanyak beserta detail kategori dan pemilik


SELECT 
    k.nama_kantin,
    k.lokasi,
    pk.nama AS nama_pemilik,
    km.nama_kategori,
    COUNT(mn.id_menu) AS jumlah_menu,
    ROUND(AVG(mn.harga), 2) AS rata_rata_harga
FROM Kantin k
JOIN Pemilik_Kantin pk ON k.Pemilik_Kantin_id_p = pk.id_pemilik
JOIN Kategori_Menu km ON k.id_kantin = km.Kantin_id_kantin
JOIN Menu mn ON km.id_categori = mn.Kategori_Menu
WHERE mn.is_available = TRUE
GROUP BY k.nama_kantin, k.lokasi, pk.nama, km.nama_kategori
ORDER BY jumlah_menu DESC, k.nama_kantin;


-- 2. QUERY SEARCHING (JOIN) #2
-- Mahasiswa yang order lebih dari 1x dengan detail kantin favorit


SELECT 
    m.id_user,
    m.nama AS nama_mahasiswa,
    m.email,
    k.nama_kantin AS kantin_favorit,
    COUNT(po.id_pre_order) AS total_order,
    SUM(po.total_harga) AS total_belanja,
    MAX(po.tanggal_ambil) AS terakhir_order
FROM mahasiswa m
JOIN pre_order po ON m.id_user = po.mahasiswa_id_us
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
GROUP BY m.id_user, m.nama, m.email, k.nama_kantin
HAVING COUNT(po.id_pre_order) > 1
ORDER BY total_order DESC;


-- 3. VIEW #1
-- v_stok_menu_harian: Status stok menu harian per kantin


CREATE OR REPLACE VIEW v_stok_menu_harian AS
SELECT 
    k.nama_kantin,
    k.lokasi,
    km.nama_kategori,
    mn.id_menu,
    mn.nama_menu,
    mn.harga,
    mn.stok_hari_ini,
    mn.terjual_hari_ini,
    (mn.stok_hari_ini + mn.terjual_hari_ini) AS stok_awal,
    mn.is_available,
    CASE 
        WHEN mn.stok_hari_ini = 0 THEN 'HABIS'
        WHEN mn.stok_hari_ini <= 5 THEN 'HAMPIR HABIS'
        ELSE 'TERSEDIA'
    END AS status_stok
FROM Menu mn
JOIN Kategori_Menu km ON mn.Kategori_Menu = km.id_categori
JOIN Kantin k ON km.Kantin_id_kantin = k.id_kantin
ORDER BY k.nama_kantin, mn.stok_hari_ini ASC;

-- cara menjalankan: 
SELECT * FROM v_stok_menu_harian;



-- 4. VIEW #2
-- v_pendapatan_kantin: Rekapitulasi pendapatan per kantin


CREATE OR REPLACE VIEW v_pendapatan_kantin AS
SELECT 
    k.id_kantin,
    k.nama_kantin,
    k.lokasi,
    pk.nama AS nama_pemilik,
    COUNT(DISTINCT po.id_pre_order) AS total_order_selesai,
    COALESCE(SUM(po.total_harga), 0) AS total_pendapatan,
    COALESCE(ROUND(AVG(po.total_harga), 2), 0) AS rata_rata_per_order,
    MIN(po.tanggal_ambil) AS order_pertama,
    MAX(po.tanggal_ambil) AS order_terakhir
FROM Kantin k
JOIN Pemilik_Kantin pk ON k.Pemilik_Kantin_id_p = pk.id_pemilik
LEFT JOIN Sesi_Waktu sw ON k.id_kantin = sw.Kantin_id_kantin
LEFT JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo 
    AND po.status = 'completed' AND po.status_bayar = 'paid'
GROUP BY k.id_kantin, k.nama_kantin, k.lokasi, pk.nama
ORDER BY total_pendapatan DESC;

-- cara menjalankan:
SELECT * FROM v_pendapatan_kantin;


-- 5. TRIGGER #1
-- trg_set_default_rating: Set default rating 0.0 saat kantin baru dibuat


CREATE OR REPLACE FUNCTION fn_trg_set_default_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.rating IS NULL OR NEW.rating < 0 OR NEW.rating > 5 THEN
        NEW.rating := 0.0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_set_default_rating
BEFORE INSERT ON Kantin
FOR EACH ROW
EXECUTE FUNCTION fn_trg_set_default_rating();

-- Cara mengetes
INSERT INTO Kantin (id_kantin, nama_kantin, lokasi, Pemilik_Kantin_id_p) 
VALUES ('KNT999', 'Kantin Coba', 'Lokasi Coba', 'PMK001');

-- cara mengecek
SELECT id_kantin, nama_kantin, rating FROM Kantin WHERE id_kantin = 'KNT999';


-- 6. TRIGGER #2
-- trg_validasi_jam_order: Validasi bahwa sesi waktu masih aktif saat order dibuat


CREATE OR REPLACE FUNCTION fn_trg_validasi_jam_order()
RETURNS TRIGGER AS $$
DECLARE
    v_is_active BOOLEAN;
    v_label TEXT;
BEGIN
    SELECT is_active, label INTO v_is_active, v_label
    FROM Sesi_Waktu
    WHERE id_slot = NEW.Sesi_Waktu_id_slo;
    
    IF v_is_active = FALSE THEN
        RAISE EXCEPTION 'Sesi waktu "%" (%) sedang tidak aktif. Silakan pilih sesi lain.', 
            v_label, NEW.Sesi_Waktu_id_slo;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validasi_jam_order
BEFORE INSERT ON pre_order
FOR EACH ROW
EXECUTE FUNCTION fn_trg_validasi_jam_order();

-- cara mengetes 
UPDATE Sesi_Waktu SET is_active = FALSE WHERE id_slot = 'SLT001';

INSERT INTO pre_order (id_pre_order, kode_order, tanggal_ambil, mahasiswa_id_us, Sesi_Waktu_id_slo) 
VALUES ('PRE999', 'KR-TEST-123', '2026-05-01', 'USR001', 'SLT001');



-- 7. FUNCTION #1
-- fn_get_kantin_terlaris: Return kantin dengan order terbanyak dalam periode tertentu


CREATE OR REPLACE FUNCTION fn_get_kantin_terlaris(
    p_tanggal_mulai DATE DEFAULT '2026-01-01',
    p_tanggal_akhir DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    nama_kantin TEXT,
    lokasi TEXT,
    total_order BIGINT,
    total_pendapatan DECIMAL,
    rata_rata_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        k.nama_kantin,
        k.lokasi,
        COUNT(po.id_pre_order) AS total_order,
        SUM(po.total_harga) AS total_pendapatan,
        ROUND(k.rating::DECIMAL, 1) AS rata_rata_rating
    FROM Kantin k
    JOIN Sesi_Waktu sw ON k.id_kantin = sw.Kantin_id_kantin
    JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo
    WHERE po.tanggal_ambil BETWEEN p_tanggal_mulai AND p_tanggal_akhir
      AND po.status = 'completed'
    GROUP BY k.nama_kantin, k.lokasi, k.rating
    ORDER BY total_order DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Contoh pemanggilan:
SELECT * FROM fn_get_kantin_terlaris('2026-04-01', '2026-06-30');


-- 8. PROCEDURE #1
-- sp_reset_stok_harian: Procedure reset stok harian semua menu

CREATE OR REPLACE PROCEDURE sp_reset_stok_harian(
    p_id_kantin VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_affected INT;
BEGIN
    IF p_id_kantin IS NOT NULL THEN
        -- Reset stok untuk kantin tertentu
        UPDATE Menu mn
        SET stok_hari_ini = stok_hari_ini + terjual_hari_ini,
            terjual_hari_ini = 0,
            is_available = TRUE
        FROM Kategori_Menu km
        WHERE mn.Kategori_Menu = km.id_categori
          AND km.Kantin_id_kantin = p_id_kantin;
        
        GET DIAGNOSTICS v_affected = ROW_COUNT;
        RAISE NOTICE 'Reset stok harian untuk kantin %: % menu diperbarui', p_id_kantin, v_affected;
    ELSE
        -- Reset stok untuk semua kantin
        UPDATE Menu
        SET stok_hari_ini = stok_hari_ini + terjual_hari_ini,
            terjual_hari_ini = 0,
            is_available = TRUE;
        
        GET DIAGNOSTICS v_affected = ROW_COUNT;
        RAISE NOTICE 'Reset stok harian untuk semua kantin: % menu diperbarui', v_affected;
    END IF;
END;
$$;

-- Contoh pemanggilan:
CALL sp_reset_stok_harian();              -- Reset semua
CALL sp_reset_stok_harian('KNT001');      -- Reset kantin tertentu
