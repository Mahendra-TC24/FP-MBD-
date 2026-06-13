-- =====================================================
-- QUERY ANGGOTA 1 - KAMAL ZAKY ADINATA (5025241153)
-- Final Project K-RUN - Manajemen Basis Data (B)
-- =====================================================

-- =====================================================
-- 1. QUERY SEARCHING (JOIN) #1
-- Total spending per mahasiswa beserta nama kantin yang paling sering dipesan
-- =====================================================

SELECT 
    m.id_user,
    m.nama AS nama_mahasiswa,
    k.nama_kantin,
    COUNT(po.id_pre_order) AS total_order,
    SUM(po.total_harga) AS total_spending
FROM mahasiswa m
JOIN pre_order po ON m.id_user = po.mahasiswa_id_us
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
WHERE po.status = 'completed'
GROUP BY m.id_user, m.nama, k.nama_kantin
ORDER BY total_spending DESC;

-- =====================================================
-- 2. QUERY SEARCHING (JOIN) #2
-- Menu terlaris di setiap kantin berdasarkan jumlah item dipesan
-- =====================================================

SELECT 
    k.nama_kantin,
    k.lokasi,
    mn.nama_menu,
    SUM(pom.jumlah) AS total_dipesan,
    mn.harga
FROM Kantin k
JOIN Kategori_Menu km ON k.id_kantin = km.Kantin_id_kantin
JOIN Menu mn ON km.id_categori = mn.Kategori_Menu
JOIN pre_order_Menu pom ON mn.id_menu = pom.Menu_id_menu
GROUP BY k.nama_kantin, k.lokasi, mn.nama_menu, mn.harga
ORDER BY total_dipesan DESC
LIMIT 20;

-- =====================================================
-- 3. VIEW #1
-- v_ringkasan_order: Ringkasan order lengkap dengan info mahasiswa dan kantin
-- =====================================================

CREATE OR REPLACE VIEW v_ringkasan_order AS
SELECT 
    po.id_pre_order,
    po.kode_order,
    m.nama AS nama_mahasiswa,
    m.email AS email_mahasiswa,
    k.nama_kantin,
    k.lokasi AS lokasi_kantin,
    sw.label AS sesi,
    po.tanggal_ambil,
    po.status,
    po.total_harga,
    po.status_bayar,
    po.metode_bayar,
    po.catatan,
    po.created_at
FROM pre_order po
JOIN mahasiswa m ON po.mahasiswa_id_us = m.id_user
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
ORDER BY po.created_at DESC;

-- =====================================================
-- 4. VIEW #2
-- v_menu_populer: Menu paling populer per kantin dengan total pemesanan
-- =====================================================

CREATE OR REPLACE VIEW v_menu_populer AS
SELECT 
    k.id_kantin,
    k.nama_kantin,
    mn.id_menu,
    mn.nama_menu,
    km.nama_kategori,
    mn.harga,
    COALESCE(SUM(pom.jumlah), 0) AS total_dipesan,
    mn.stok_hari_ini,
    mn.terjual_hari_ini
FROM Kantin k
JOIN Kategori_Menu km ON k.id_kantin = km.Kantin_id_kantin
JOIN Menu mn ON km.id_categori = mn.Kategori_Menu
LEFT JOIN pre_order_Menu pom ON mn.id_menu = pom.Menu_id_menu
GROUP BY k.id_kantin, k.nama_kantin, mn.id_menu, mn.nama_menu, 
         km.nama_kategori, mn.harga, mn.stok_hari_ini, mn.terjual_hari_ini
ORDER BY total_dipesan DESC;

-- =====================================================
-- 5. TRIGGER #1
-- trg_update_stok: Auto kurangi stok_hari_ini saat ada item ditambahkan ke order
-- =====================================================

CREATE OR REPLACE FUNCTION fn_trg_update_stok()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Menu 
    SET stok_hari_ini = stok_hari_ini - NEW.jumlah
    WHERE id_menu = NEW.Menu_id_menu
      AND stok_hari_ini >= NEW.jumlah;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stok menu % tidak mencukupi', NEW.Menu_id_menu;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_update_stok
AFTER INSERT ON pre_order_Menu
FOR EACH ROW
EXECUTE FUNCTION fn_trg_update_stok();

-- =====================================================
-- 6. TRIGGER #2
-- trg_update_terjual: Auto update terjual_hari_ini saat order status jadi 'completed'
-- =====================================================

CREATE OR REPLACE FUNCTION fn_trg_update_terjual()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE Menu 
        SET terjual_hari_ini = terjual_hari_ini + pom.jumlah
        FROM pre_order_Menu pom
        WHERE Menu.id_menu = pom.Menu_id_menu
          AND pom.pre_order_id_pre_ord = NEW.id_pre_order;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_update_terjual
AFTER UPDATE OF status ON pre_order
FOR EACH ROW
WHEN (NEW.status = 'completed')
EXECUTE FUNCTION fn_trg_update_terjual();

-- =====================================================
-- 7. FUNCTION #1
-- fn_hitung_total_order: Menghitung total harga order berdasarkan items yang dipesan
-- =====================================================

CREATE OR REPLACE FUNCTION fn_hitung_total_order(p_id_pre_order VARCHAR)
RETURNS DECIMAL(13,2) AS $$
DECLARE
    v_total DECIMAL(13,2);
BEGIN
    SELECT COALESCE(SUM(pom.jumlah * pom.harga_satuan), 0)
    INTO v_total
    FROM pre_order_Menu pom
    WHERE pom.pre_order_id_pre_ord = p_id_pre_order;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Contoh pemanggilan:
-- SELECT fn_hitung_total_order('PRE001');

-- =====================================================
-- 8. PROCEDURE #1
-- sp_buat_pre_order: Procedure untuk membuat pre-order baru lengkap
-- =====================================================

CREATE OR REPLACE PROCEDURE sp_buat_pre_order(
    p_id_pre_order VARCHAR,
    p_mahasiswa_id VARCHAR,
    p_sesi_waktu_id VARCHAR,
    p_tanggal_ambil DATE,
    p_metode_bayar VARCHAR,
    p_catatan TEXT DEFAULT ''
)
LANGUAGE plpgsql AS $$
DECLARE
    v_kode_order VARCHAR(50);
    v_kapasitas INT;
    v_jumlah_order INT;
BEGIN
    -- Cek kapasitas sesi waktu
    SELECT kapasitas_order INTO v_kapasitas
    FROM Sesi_Waktu 
    WHERE id_slot = p_sesi_waktu_id AND is_active = TRUE;
    
    IF v_kapasitas IS NULL THEN
        RAISE EXCEPTION 'Sesi waktu % tidak ditemukan atau tidak aktif', p_sesi_waktu_id;
    END IF;
    
    -- Hitung jumlah order yang sudah ada di sesi tersebut
    SELECT COUNT(*) INTO v_jumlah_order
    FROM pre_order
    WHERE Sesi_Waktu_id_slo = p_sesi_waktu_id
      AND tanggal_ambil = p_tanggal_ambil
      AND status NOT IN ('cancelled');
    
    IF v_jumlah_order >= v_kapasitas THEN
        RAISE EXCEPTION 'Kapasitas sesi waktu % sudah penuh (%/%)', 
            p_sesi_waktu_id, v_jumlah_order, v_kapasitas;
    END IF;
    
    -- Generate kode order
    v_kode_order := 'KR-' || TO_CHAR(p_tanggal_ambil, 'YYYYMMDD') || '-' || 
                    LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    
    -- Insert pre_order
    INSERT INTO pre_order (
        id_pre_order, kode_order, tanggal_ambil, status, subtotal, 
        total_harga, metode_bayar, status_bayar, url_bukti_bayar, 
        catatan, created_at, updated_at, mahasiswa_id_us, Sesi_Waktu_id_slo
    ) VALUES (
        p_id_pre_order, v_kode_order, p_tanggal_ambil, 'pending', 0.00,
        0.00, p_metode_bayar, 'unpaid', '',
        p_catatan, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, p_mahasiswa_id, p_sesi_waktu_id
    );
    
    RAISE NOTICE 'Pre-order % berhasil dibuat dengan kode %', p_id_pre_order, v_kode_order;
END;
$$;

-- Contoh pemanggilan:
-- CALL sp_buat_pre_order('PRE999', 'USR001', 'SLT001', '2026-07-01', 'e-wallet', 'Tidak pakai sambal');
