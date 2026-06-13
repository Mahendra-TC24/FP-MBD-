-- QUERY ANGGOTA 4 - RADITYA ZHAFRAN PRANUJA (5025241120)
-- Final Project K-RUN - Manajemen Basis Data (B)



-- 1. QUERY SEARCHING (JOIN) #1
-- Detail pembayaran dengan nama mahasiswa, nama kantin, dan metode bayar


SELECT 
    pb.id_pembayaran,
    po.kode_order,
    m.nama AS nama_mahasiswa,
    k.nama_kantin,
    pb.metode AS metode_pembayaran,
    pg.nama AS payment_gateway,
    pb.jumlah,
    pb.status,
    pb.paid_at
FROM pembayaran pb
JOIN pre_order po ON pb.pre_order_id_pre = po.id_pre_order
JOIN mahasiswa m ON po.mahasiswa_id_us = m.id_user
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
JOIN Payment_gateway pg ON pb.Payment_gateway = pg.id_metode
ORDER BY pb.paid_at DESC NULLS LAST;


-- 2. QUERY SEARCHING (JOIN) #2
-- Menu yang belum pernah dipesan sama sekali


SELECT 
    mn.id_menu,
    mn.nama_menu,
    km.nama_kategori,
    k.nama_kantin,
    mn.harga,
    mn.stok_hari_ini
FROM Menu mn
JOIN Kategori_Menu km ON mn.Kategori_Menu = km.id_categori
JOIN Kantin k ON km.Kantin_id_kantin = k.id_kantin
LEFT JOIN pre_order_Menu pom ON mn.id_menu = pom.Menu_id_menu
WHERE pom.pre_order_id_pre_ord IS NULL
ORDER BY k.nama_kantin, mn.nama_menu;


-- 3. VIEW #1
-- v_sesi_aktif: Sesi waktu yang aktif beserta info kantin dan sisa kapasitas


CREATE OR REPLACE VIEW v_sesi_aktif AS
SELECT 
    sw.id_slot,
    sw.label AS sesi,
    sw.jam_mulai,
    sw.jam_selesai,
    k.nama_kantin,
    k.lokasi,
    sw.kapasitas_order,
    COALESCE(COUNT(po.id_pre_order), 0) AS total_order_masuk,
    sw.kapasitas_order - COALESCE(COUNT(po.id_pre_order), 0) AS sisa_kapasitas
FROM Sesi_Waktu sw
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
LEFT JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo 
    AND po.tanggal_ambil = CURRENT_DATE 
    AND po.status NOT IN ('cancelled')
WHERE sw.is_active = TRUE
GROUP BY sw.id_slot, sw.label, sw.jam_mulai, sw.jam_selesai, 
         k.nama_kantin, k.lokasi, sw.kapasitas_order
ORDER BY k.nama_kantin, sw.jam_mulai;


-- 4. VIEW #2
-- v_order_harian: Rekap order per hari per kantin


CREATE OR REPLACE VIEW v_order_harian AS
SELECT 
    po.tanggal_ambil AS tanggal,
    k.nama_kantin,
    COUNT(po.id_pre_order) AS jumlah_order,
    SUM(CASE WHEN po.status = 'completed' THEN 1 ELSE 0 END) AS order_selesai,
    SUM(CASE WHEN po.status = 'cancelled' THEN 1 ELSE 0 END) AS order_batal,
    COALESCE(SUM(CASE WHEN po.status = 'completed' THEN po.total_harga ELSE 0 END), 0) AS pendapatan
FROM pre_order po
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
GROUP BY po.tanggal_ambil, k.nama_kantin
ORDER BY po.tanggal_ambil DESC, k.nama_kantin;


-- 5. TRIGGER #1
-- trg_prevent_order_inactive_menu: Cegah pesanan untuk menu yang is_available = FALSE


CREATE OR REPLACE FUNCTION fn_trg_prevent_order_inactive_menu()
RETURNS TRIGGER AS $$
DECLARE
    v_is_available BOOLEAN;
    v_nama_menu VARCHAR;
BEGIN
    SELECT is_available, nama_menu INTO v_is_available, v_nama_menu
    FROM Menu
    WHERE id_menu = NEW.Menu_id_menu;
    
    IF v_is_available = FALSE THEN
        RAISE EXCEPTION 'Menu "%" sedang tidak tersedia', v_nama_menu;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_prevent_order_inactive_menu
BEFORE INSERT ON pre_order_Menu
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_order_inactive_menu();


-- 6. TRIGGER #2
-- trg_auto_update_rating: Auto update rating kantin berdasarkan jumlah order selesai


CREATE OR REPLACE FUNCTION fn_trg_auto_update_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_kantin_id VARCHAR;
    v_total_completed INT;
    v_new_rating DECIMAL;
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Dapatkan ID Kantin
        SELECT Kantin_id_kantin INTO v_kantin_id
        FROM Sesi_Waktu
        WHERE id_slot = NEW.Sesi_Waktu_id_slo;
        
        -- Hitung total order selesai untuk kantin ini
        SELECT COUNT(*) INTO v_total_completed
        FROM pre_order po
        JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
        WHERE sw.Kantin_id_kantin = v_kantin_id AND po.status = 'completed';
        
        -- Simulasi update rating sederhana: 
        -- Rating bertambah 0.1 untuk setiap 10 order selesai (max 5.0)
        v_new_rating := LEAST(5.0, 3.5 + (v_total_completed / 10.0) * 0.1);
        
        -- Update Kantin
        UPDATE Kantin
        SET rating = v_new_rating
        WHERE id_kantin = v_kantin_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auto_update_rating
AFTER UPDATE OF status ON pre_order
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auto_update_rating();


-- 7. FUNCTION #1
-- fn_format_kode_order: Generate kode order unik dengan format KRN-YYYYMMDD-XXXX


CREATE OR REPLACE FUNCTION fn_format_kode_order(p_tanggal DATE)
RETURNS VARCHAR AS $$
DECLARE
    v_kode VARCHAR;
    v_random_str VARCHAR;
BEGIN
    -- Generate 4 random alphanumeric characters
    v_random_str := SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 4);
    
    -- Format: KRN-YYYYMMDD-XXXX
    v_kode := 'KRN-' || TO_CHAR(p_tanggal, 'YYYYMMDD') || '-' || UPPER(v_random_str);
    
    RETURN v_kode;
END;
$$ LANGUAGE plpgsql;

-- Contoh pemanggilan:
-- SELECT fn_format_kode_order('2026-06-15');


-- 8. PROCEDURE #1
-- sp_batalkan_order: Procedure untuk membatalkan order dengan alasan


CREATE OR REPLACE PROCEDURE sp_batalkan_order(
    p_id_pre_order VARCHAR,
    p_alasan TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_status_sekarang VARCHAR;
BEGIN
    -- Dapatkan status sekarang
    SELECT status INTO v_status_sekarang
    FROM pre_order
    WHERE id_pre_order = p_id_pre_order;
    
    IF v_status_sekarang IS NULL THEN
        RAISE EXCEPTION 'Order % tidak ditemukan', p_id_pre_order;
    END IF;
    
    IF v_status_sekarang IN ('completed', 'cancelled') THEN
        RAISE EXCEPTION 'Order % tidak bisa dibatalkan karena status sudah %', 
            p_id_pre_order, v_status_sekarang;
    END IF;
    
    -- Update status order
    UPDATE pre_order
    SET status = 'cancelled',
        catatan = CONCAT(catatan, ' | Dibatalkan: ', p_alasan),
        updated_at = CURRENT_TIMESTAMP
    WHERE id_pre_order = p_id_pre_order;
    
    -- Kembalikan stok menu
    UPDATE Menu mn
    SET stok_hari_ini = mn.stok_hari_ini + pom.jumlah
    FROM pre_order_Menu pom
    WHERE mn.id_menu = pom.Menu_id_menu
      AND pom.pre_order_id_pre_ord = p_id_pre_order;
      
    RAISE NOTICE 'Order % berhasil dibatalkan. Stok menu dikembalikan.', p_id_pre_order;
END;
$$;

-- Contoh pemanggilan:
-- CALL sp_batalkan_order('PRE001', 'Pembeli tidak jadi memesan');
