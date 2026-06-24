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



-- 9. add atribut total_point pada mahasiswa. Kemudian buat trigger add point 10% dari tanggal created_at yang memesan menu dari kantin mengandung kata warung menggunakan hak akses kantin_manager

-- Menambah kolom total_point pada tabel mahasiswa
ALTER TABLE mahasiswa ADD COLUMN IF NOT EXISTS total_point DECIMAL(10,2) DEFAULT 0;


-- Memberikan hak akses UPDATE kolom total_point kepada kantin_manager
GRANT UPDATE (total_point) ON mahasiswa TO kantin_manager;


-- Membuat fungsi trigger untuk menambahkan poin reward secara otomatis ke akun mahasiswa ketika mereka memesan menu dari kantin yang namanya mengandung kata “warung”
CREATE OR REPLACE FUNCTION fn_trg_add_point_warung()
RETURNS TRIGGER AS $$
DECLARE
    v_nama_kantin TEXT;
    v_created_at TIMESTAMP;
    v_mahasiswa_id VARCHAR(9);
    v_tanggal INT;
    v_point DECIMAL(10,2);
BEGIN
    SELECT po.created_at, po.mahasiswa_id_us
    INTO v_created_at, v_mahasiswa_id
    FROM pre_order po
    WHERE po.id_pre_order = NEW.pre_order_id_pre_ord;

    SELECT k.nama_kantin
    INTO v_nama_kantin
    FROM Menu mn
    JOIN Kategori_Menu km ON mn.Kategori_Menu = km.id_categori
    JOIN Kantin k ON km.Kantin_id_kantin = k.id_kantin
    WHERE mn.id_menu = NEW.Menu_id_menu;


    IF v_nama_kantin ILIKE '%warung%' THEN
        v_tanggal := EXTRACT(DAY FROM v_created_at);
        v_point := v_tanggal * 0.10;
        UPDATE mahasiswa
        SET total_point = COALESCE(total_point, 0) + v_point
        WHERE id_user = v_mahasiswa_id;

        RAISE NOTICE 'Point +% ditambahkan untuk mahasiswa % (kantin: %, tanggal: %)',
            v_point, v_mahasiswa_id, v_nama_kantin, v_tanggal;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- Set owner fungsi ke kantin_manager agar trigger berjalan dengan hak akses kantin_manager
ALTER FUNCTION fn_trg_add_point_warung() OWNER TO kantin_manager;


-- Membuat trigger pada tabel pre_order_Menu (after insert)
CREATE OR REPLACE TRIGGER trg_add_point_warung
AFTER INSERT ON pre_order_Menu
FOR EACH ROW
EXECUTE FUNCTION fn_trg_add_point_warung();


-- CARA Mengetes 

-- langkah 1: Cek kantin yang mengandung kata "warung"
SELECT id_kantin, nama_kantin FROM Kantin WHERE nama_kantin ILIKE '%warung%';

-- langkah 2: Cek menu yang berasal dari kantin "warung"
SELECT mn.id_menu, mn.nama_menu, km.nama_kategori, k.nama_kantin
FROM Menu mn
JOIN Kategori_Menu km ON mn.Kategori_Menu = km.id_categori
JOIN Kantin k ON km.Kantin_id_kantin = k.id_kantin
WHERE k.nama_kantin ILIKE '%warung%';

--langkah 3: Cek total_point mahasiswa sebelum insert (USR001 = Prasetyo Setiawan)
SELECT id_user, nama, total_point FROM mahasiswa WHERE id_user = 'USR001';
-- Hasil yang diharapkan: total_point = 0 

-- langkah 4: Buat pre_order baru untuk testing
-- created_at = 2026-06-23 -> tanggal = 23 -> point = 23 * 10% = 2.30
INSERT INTO pre_order (id_pre_order, kode_order, tanggal_ambil, status, mahasiswa_id_us, Sesi_Waktu_id_slo, created_at)
VALUES ('PRE997', 'KR-TEST-POINT-001', '2026-06-25', 'pending', 'USR001', 'SLT002', '2026-06-23 14:30:00');

-- langkah 5: Insert menu dari kantin "warung" maka trigger akan aktif
INSERT INTO pre_order_Menu (pre_order_id_pre_ord, Menu_id_menu, jumlah, harga_satuan)
VALUES ('PRE997', 'MNU036', 1, 14000.00);
-- Trigger akan mendeteksi KNT001 mengandung "warung" lalu menambah point 2.30

-- langkah 6: Cek total_point mahasiswa sesudah trigger
SELECT id_user, nama, total_point FROM mahasiswa WHERE id_user = 'USR001';
-- Hasil yang diharapkan: total_point = 2.30

-- langkah 7: Test tambah menu lagi dari kantin warung (point bertambah kumulatif)
INSERT INTO pre_order_Menu (pre_order_id_pre_ord, Menu_id_menu, jumlah, harga_satuan)
VALUES ('PRE997', 'MNU037', 1, 13000.00);
-- Point bertambah lagi 2.30

-- langkah 8: Cek total_point setelah 2x trigger
SELECT id_user, nama, total_point FROM mahasiswa WHERE id_user = 'USR001';
-- Hasil yang diharapkan: total_point = 4.60 (2.30 + 2.30)

-- langkah 9: Test dengan kantin BUKAN warung (point tidak akan bertambah)
INSERT INTO pre_order (id_pre_order, kode_order, tanggal_ambil, status, mahasiswa_id_us, Sesi_Waktu_id_slo, created_at)
VALUES ('PRE998', 'KR-TEST-POINT-002', '2026-06-25', 'pending', 'USR001', 'SLT003', '2026-06-15 10:00:00');

INSERT INTO pre_order_Menu (pre_order_id_pre_ord, Menu_id_menu, jumlah, harga_satuan)
VALUES ('PRE998', 'MNU057', 1, 12000.00);
-- Trigger tidak menambah point

-- lankgah 10: Verifikasi point tidak bertambah
SELECT id_user, nama, total_point FROM mahasiswa WHERE id_user = 'USR001';
-- Hasil yang diharapkan: total_point tetap 4.60 (tidak bertambah)
