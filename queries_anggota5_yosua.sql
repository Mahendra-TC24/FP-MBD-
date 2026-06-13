-- QUERY ANGGOTA 5 - YOSUA HARES (5025221270)
-- Final Project K-RUN - Manajemen Basis Data (B)

-- 1. QUERY SEARCHING (JOIN) #1
-- Histori order mahasiswa lengkap dengan daftar menu dan total harga

SELECT 
    m.nama AS nama_mahasiswa,
    po.kode_order,
    po.tanggal_ambil,
    k.nama_kantin,
    STRING_AGG(mn.nama_menu || ' (x' || pom.jumlah || ')', ', ') AS daftar_pesanan,
    po.total_harga,
    po.status
FROM mahasiswa m
JOIN pre_order po ON m.id_user = po.mahasiswa_id_us
JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
JOIN Kantin k ON sw.Kantin_id_kantin = k.id_kantin
JOIN pre_order_Menu pom ON po.id_pre_order = pom.pre_order_id_pre_ord
JOIN Menu mn ON pom.Menu_id_menu = mn.id_menu
GROUP BY m.nama, po.kode_order, po.tanggal_ambil, k.nama_kantin, po.total_harga, po.status
ORDER BY po.tanggal_ambil DESC, m.nama;

-- 2. QUERY SEARCHING (JOIN) #2
-- Kantin dengan jumlah pembayaran yang berstatus failed/expired terbanyak

SELECT 
    k.nama_kantin,
    k.lokasi,
    pk.nama AS pemilik,
    COUNT(pb.id_pembayaran) AS jumlah_gagal,
    SUM(pb.jumlah) AS potensi_kerugian
FROM Kantin k
JOIN Pemilik_Kantin pk ON k.Pemilik_Kantin_id_p = pk.id_pemilik
JOIN Sesi_Waktu sw ON k.id_kantin = sw.Kantin_id_kantin
JOIN pre_order po ON sw.id_slot = po.Sesi_Waktu_id_slo
JOIN pembayaran pb ON po.id_pre_order = pb.pre_order_id_pre
WHERE pb.status IN ('failed', 'expired')
GROUP BY k.nama_kantin, k.lokasi, pk.nama
ORDER BY jumlah_gagal DESC;

-- 3. VIEW #1
-- v_mahasiswa_aktif: Mahasiswa dengan total belanja dan status keaktifan

CREATE OR REPLACE VIEW v_mahasiswa_aktif AS
SELECT 
    m.id_user,
    m.nama,
    m.email,
    m.no_hp,
    COUNT(po.id_pre_order) AS jumlah_order,
    COALESCE(SUM(CASE WHEN po.status = 'completed' THEN po.total_harga ELSE 0 END), 0) AS total_spending,
    MAX(po.tanggal_ambil) AS order_terakhir,
    CASE 
        WHEN MAX(po.tanggal_ambil) >= CURRENT_DATE - INTERVAL '30 days' THEN 'Aktif'
        WHEN MAX(po.tanggal_ambil) IS NULL THEN 'Belum Pernah Order'
        ELSE 'Pasif'
    END AS status_keaktifan
FROM mahasiswa m
LEFT JOIN pre_order po ON m.id_user = po.mahasiswa_id_us
GROUP BY m.id_user, m.nama, m.email, m.no_hp
ORDER BY total_spending DESC;

-- 4. VIEW #2
-- v_payment_gateway_usage: Statistik penggunaan payment gateway

CREATE OR REPLACE VIEW v_payment_gateway_usage AS
SELECT 
    pg.id_metode,
    pg.nama AS metode_pembayaran,
    pg.tipe AS tipe_gateway,
    COUNT(pb.id_pembayaran) AS frekuensi_penggunaan,
    SUM(CASE WHEN pb.status = 'success' THEN 1 ELSE 0 END) AS transaksi_berhasil,
    SUM(CASE WHEN pb.status = 'failed' OR pb.status = 'expired' THEN 1 ELSE 0 END) AS transaksi_gagal,
    COALESCE(SUM(CASE WHEN pb.status = 'success' THEN pb.jumlah ELSE 0 END), 0) AS total_nominal_berhasil
FROM Payment_gateway pg
LEFT JOIN pembayaran pb ON pg.id_metode = pb.Payment_gateway
GROUP BY pg.id_metode, pg.nama, pg.tipe
ORDER BY frekuensi_penggunaan DESC;

-- 5. TRIGGER #1
-- trg_cek_email_format: Validasi format email mahasiswa sebelum insert/update

CREATE OR REPLACE FUNCTION fn_trg_cek_email_format()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION 'Format email tidak valid: %', NEW.email;
    END IF;
    
    -- Khusus untuk ITS, bisa divalidasi harus domain its.ac.id
    IF NEW.email !~ '.*@.*its\.ac\.id$' THEN
        RAISE WARNING 'Email bukan merupakan email institusi ITS: %', NEW.email;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_cek_email_format
BEFORE INSERT OR UPDATE ON mahasiswa
FOR EACH ROW
EXECUTE FUNCTION fn_trg_cek_email_format();

-- 6. TRIGGER #2
-- trg_auto_set_updated_at: Auto set updated_at saat data pre_order diubah

CREATE OR REPLACE FUNCTION fn_trg_auto_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_auto_set_updated_at
BEFORE UPDATE ON pre_order
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auto_set_updated_at();

-- 7. FUNCTION #1
-- fn_hitung_diskon: Menghitung diskon berdasarkan frekuensi belanja mahasiswa

CREATE OR REPLACE FUNCTION fn_hitung_diskon(
    p_id_mahasiswa VARCHAR,
    p_total_harga DECIMAL
)
RETURNS DECIMAL(13,2) AS $$
DECLARE
    v_jumlah_order INT;
    v_persen_diskon DECIMAL(5,2) := 0.00;
    v_potongan DECIMAL(13,2) := 0.00;
BEGIN
    -- Hitung jumlah order completed mahasiswa
    SELECT COUNT(*) INTO v_jumlah_order
    FROM pre_order
    WHERE mahasiswa_id_us = p_id_mahasiswa 
      AND status = 'completed';
      
    -- Tentukan persentase diskon
    IF v_jumlah_order >= 20 THEN
        v_persen_diskon := 0.10; -- Diskon 10%
    ELSIF v_jumlah_order >= 10 THEN
        v_persen_diskon := 0.05; -- Diskon 5%
    END IF;
    
    -- Hitung nominal potongan
    v_potongan := p_total_harga * v_persen_diskon;
    
    -- Maksimal diskon Rp 20.000
    IF v_potongan > 20000.00 THEN
        v_potongan := 20000.00;
    END IF;
    
    RETURN v_potongan;
END;
$$ LANGUAGE plpgsql;

-- Contoh pemanggilan:
-- SELECT fn_hitung_diskon('USR001', 150000.00);

-- 8. PROCEDURE #1
-- sp_laporan_harian: Procedure untuk men-generate data laporan harian per kantin

CREATE OR REPLACE PROCEDURE sp_laporan_harian(
    p_id_kantin VARCHAR,
    p_tanggal DATE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_nama_kantin VARCHAR;
    v_total_pesanan INT;
    v_total_pendapatan DECIMAL(13,2);
    v_menu_terlaris VARCHAR;
BEGIN
    -- Ambil nama kantin
    SELECT nama_kantin INTO v_nama_kantin
    FROM Kantin
    WHERE id_kantin = p_id_kantin;
    
    IF v_nama_kantin IS NULL THEN
        RAISE EXCEPTION 'Kantin % tidak ditemukan', p_id_kantin;
    END IF;

    -- Hitung total pesanan selesai
    SELECT COUNT(*), COALESCE(SUM(total_harga), 0) 
    INTO v_total_pesanan, v_total_pendapatan
    FROM pre_order po
    JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
    WHERE sw.Kantin_id_kantin = p_id_kantin
      AND po.tanggal_ambil = p_tanggal
      AND po.status = 'completed';
      
    -- Cari menu terlaris hari itu
    SELECT mn.nama_menu INTO v_menu_terlaris
    FROM pre_order_Menu pom
    JOIN pre_order po ON pom.pre_order_id_pre_ord = po.id_pre_order
    JOIN Menu mn ON pom.Menu_id_menu = mn.id_menu
    JOIN Sesi_Waktu sw ON po.Sesi_Waktu_id_slo = sw.id_slot
    WHERE sw.Kantin_id_kantin = p_id_kantin
      AND po.tanggal_ambil = p_tanggal
      AND po.status = 'completed'
    GROUP BY mn.nama_menu
    ORDER BY SUM(pom.jumlah) DESC
    LIMIT 1;
    
    -- Tampilkan laporan via NOTICE
    RAISE NOTICE '========================================';
    RAISE NOTICE 'LAPORAN HARIAN KANTIN: %', v_nama_kantin;
    RAISE NOTICE 'TANGGAL: %', p_tanggal;
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total Pesanan Selesai : %', v_total_pesanan;
    RAISE NOTICE 'Total Pendapatan      : Rp %', v_total_pendapatan;
    RAISE NOTICE 'Menu Terlaris         : %', COALESCE(v_menu_terlaris, '-');
    RAISE NOTICE '========================================';
END;
$$;

-- Contoh pemanggilan:
-- CALL sp_laporan_harian('KNT001', CURRENT_DATE);
