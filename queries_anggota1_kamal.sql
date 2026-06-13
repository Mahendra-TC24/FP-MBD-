-- 1
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

-- 2
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

-- 3
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

select * from v_ringkasan_order;

-- 4
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
GROUP BY k.id_kantin, k.nama_kantin, mn.id_menu, mn.nama_menu, km.nama_kategori, mn.harga, mn.stok_hari_ini, mn.terjual_hari_ini ORDER BY total_dipesan DESC;

select * from v_menu_populer;
-- 5
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

SELECT * FROM menu;
SELECT * FROM pre_order_Menu;
SELECT * FROM pre_order;
INSERT INTO pre_order_Menu (
    pre_order_id_pre_ord,
    Menu_id_menu,
    jumlah,
    harga_satuan
)
VALUES (
    'PRE101',
    'MNU001',
    2,
    15000
);
-- 6
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

select * from pre_order;
select * from pre_order_menu;
select * from menu;
UPDATE pre_order
SET status = 'completed'
WHERE id_pre_order = 'PRE019';

-- 7
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

select * from pre_order;
select * from pre_order_menu;

SELECT fn_hitung_total_order('PRE001');
-- 8
DROP PROCEDURE IF EXISTS sp_buat_pre_order_lengkap;
CREATE OR REPLACE PROCEDURE sp_buat_pre_order_lengkap(
    IN p_id_pre_order VARCHAR,
    IN p_mahasiswa_id VARCHAR,
    IN p_sesi_waktu_id VARCHAR,
    IN p_tanggal_ambil DATE,
    IN p_metode_bayar VARCHAR,
    IN p_catatan TEXT,
    IN p_menu_ids VARCHAR[],
    IN p_jumlahs INT[],
    OUT o_kode_order VARCHAR,
    OUT o_subtotal DECIMAL(13,2),
    OUT o_total_harga DECIMAL(13,2)
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_kapasitas INT;
    v_jumlah_order INT;
    v_len_menu INT;
    v_len_jumlah INT;
    v_harga DECIMAL(10,2);
    v_stok INT;
    i INT;
BEGIN
    v_len_menu := array_length(p_menu_ids, 1);
    v_len_jumlah := array_length(p_jumlahs, 1);

    IF v_len_menu IS NULL OR v_len_menu = 0 THEN
        RAISE EXCEPTION 'Daftar menu tidak boleh kosong';
    END IF;

    IF v_len_menu IS DISTINCT FROM v_len_jumlah THEN
        RAISE EXCEPTION 'Jumlah menu dan jumlah pesanan tidak sesuai';
    END IF;

    SELECT kapasitas_order
    INTO v_kapasitas
    FROM Sesi_Waktu
    WHERE id_slot = p_sesi_waktu_id
      AND is_active = TRUE;

    IF v_kapasitas IS NULL THEN
        RAISE EXCEPTION 'Sesi waktu % tidak ditemukan atau tidak aktif', p_sesi_waktu_id;
    END IF;

    SELECT COUNT(*)
    INTO v_jumlah_order
    FROM pre_order
    WHERE Sesi_Waktu_id_slo = p_sesi_waktu_id
      AND tanggal_ambil = p_tanggal_ambil
      AND status NOT IN ('cancelled');

    IF v_jumlah_order >= v_kapasitas THEN
        RAISE EXCEPTION 'Kapasitas sesi waktu % sudah penuh (%/%)',
            p_sesi_waktu_id, v_jumlah_order, v_kapasitas;
    END IF;

    LOOP
        o_kode_order := 'KR-' || TO_CHAR(p_tanggal_ambil, 'YYYYMMDD') || '-' ||
                        LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

        EXIT WHEN NOT EXISTS (
            SELECT 1
            FROM pre_order
            WHERE kode_order = o_kode_order
        );
    END LOOP;

    INSERT INTO pre_order (
        id_pre_order,
        kode_order,
        tanggal_ambil,
        status,
        subtotal,
        total_harga,
        metode_bayar,
        status_bayar,
        url_bukti_bayar,
        catatan,
        created_at,
        updated_at,
        mahasiswa_id_us,
        Sesi_Waktu_id_slo
    )
    VALUES (
        p_id_pre_order,
        o_kode_order,
        p_tanggal_ambil,
        'pending',
        0.00,
        0.00,
        p_metode_bayar,
        'unpaid',
        '',
        p_catatan,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP,
        p_mahasiswa_id,
        p_sesi_waktu_id
    );

    FOR i IN 1..v_len_menu LOOP
        IF p_jumlahs[i] IS NULL OR p_jumlahs[i] <= 0 THEN
            RAISE EXCEPTION 'Jumlah menu % harus lebih dari 0', p_menu_ids[i];
        END IF;

        SELECT mn.harga, mn.stok_hari_ini
        INTO v_harga, v_stok
        FROM Menu mn
        JOIN Kategori_Menu km ON mn.Kategori_Menu = km.id_categori
        JOIN Sesi_Waktu sw ON sw.Kantin_id_kantin = km.Kantin_id_kantin
        WHERE mn.id_menu = p_menu_ids[i]
          AND sw.id_slot = p_sesi_waktu_id
          AND mn.is_available = TRUE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Menu % tidak ditemukan, tidak aktif, atau tidak sesuai dengan kantin pada sesi %',
                p_menu_ids[i], p_sesi_waktu_id;
        END IF;

        IF v_stok < p_jumlahs[i] THEN
            RAISE EXCEPTION 'Stok menu % tidak cukup. Stok tersedia %, diminta %',
                p_menu_ids[i], v_stok, p_jumlahs[i];
        END IF;

        INSERT INTO pre_order_Menu (
            pre_order_id_pre_ord,
            Menu_id_menu,
            jumlah,
            harga_satuan
        )
        VALUES (
            p_id_pre_order,
            p_menu_ids[i],
            p_jumlahs[i],
            v_harga
        );
    END LOOP;

    SELECT COALESCE(SUM(jumlah * harga_satuan), 0)
    INTO o_subtotal
    FROM pre_order_Menu
    WHERE pre_order_id_pre_ord = p_id_pre_order;

    o_total_harga := o_subtotal;

    UPDATE pre_order
    SET subtotal = o_subtotal,
        total_harga = o_total_harga,
        updated_at = CURRENT_TIMESTAMP
    WHERE id_pre_order = p_id_pre_order;

    RAISE NOTICE 'Pre-order % berhasil dibuat dengan kode %, subtotal %, total harga %',
        p_id_pre_order, o_kode_order, o_subtotal, o_total_harga;
END;
$$;

select * from sesi_waktu;
select * from mahasiswa;
select * from pre_order;
select * from menu;
CALL sp_buat_pre_order_lengkap(
    'PRE902',
    'USR001',
    'SLT001',
    DATE '2026-06-15',
    'QRIS',
    'Tidak pakai sambal',
    ARRAY['MNU001', 'MNU002']::VARCHAR[],
    ARRAY[2, 1]::INT[],
    NULL,
    NULL,
    NULL
);