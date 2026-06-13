-- FINAL PROJECT K-RUN - MANAJEMEN BASIS DATA
-- Kelompok 8 - Sistem Pre-order Makanan Kantin ITS


-- Drop existing tables
DROP TABLE IF EXISTS log_status_order CASCADE;
DROP TABLE IF EXISTS pre_order_Menu CASCADE;
DROP TABLE IF EXISTS pembayaran CASCADE;
DROP TABLE IF EXISTS pre_order CASCADE;
DROP TABLE IF EXISTS Menu CASCADE;
DROP TABLE IF EXISTS Kategori_Menu CASCADE;
DROP TABLE IF EXISTS Sesi_Waktu CASCADE;
DROP TABLE IF EXISTS Kantin CASCADE;
DROP TABLE IF EXISTS Pemilik_Kantin CASCADE;
DROP TABLE IF EXISTS Payment_gateway CASCADE;
DROP TABLE IF EXISTS mahasiswa CASCADE;


-- CREATE TABLES


CREATE TABLE mahasiswa (
    id_user VARCHAR(9) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    no_hp VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Pemilik_Kantin (
    id_pemilik VARCHAR(9) PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    no_hp VARCHAR(13),
    password_hash VARCHAR(100) NOT NULL
);

CREATE TABLE Kantin (
    id_kantin VARCHAR(9) PRIMARY KEY,
    nama_kantin TEXT NOT NULL,
    lokasi TEXT,
    jam_buka TIME,
    jam_tutup TIME,
    rating DECIMAL(2,1) DEFAULT 0.0,
    Pemilik_Kantin_id_p VARCHAR(9) NOT NULL,
    FOREIGN KEY (Pemilik_Kantin_id_p) REFERENCES Pemilik_Kantin(id_pemilik)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Sesi_Waktu (
    id_slot VARCHAR(9) PRIMARY KEY,
    label TEXT NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    kapasitas_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    Kantin_id_kantin VARCHAR(9) NOT NULL,
    FOREIGN KEY (Kantin_id_kantin) REFERENCES Kantin(id_kantin)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Kategori_Menu (
    id_categori VARCHAR(9) PRIMARY KEY,
    nama_kategori VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    Kantin_id_kantin VARCHAR(9) NOT NULL,
    FOREIGN KEY (Kantin_id_kantin) REFERENCES Kantin(id_kantin)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE Menu (
    id_menu VARCHAR(9) PRIMARY KEY,
    nama_menu VARCHAR(40) NOT NULL,
    deskripsi TEXT,
    harga DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_available BOOLEAN DEFAULT TRUE,
    stok_hari_ini INT DEFAULT 0,
    terjual_hari_ini INT DEFAULT 0,
    Kategori_Menu VARCHAR(9) NOT NULL,
    FOREIGN KEY (Kategori_Menu) REFERENCES Kategori_Menu(id_categori)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Payment_gateway (
    id_metode VARCHAR(9) PRIMARY KEY,
    nama VARCHAR(25) NOT NULL,
    tipe VARCHAR(25),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE pre_order (
    id_pre_order VARCHAR(9) PRIMARY KEY,
    kode_order VARCHAR(50) NOT NULL UNIQUE,
    tanggal_ambil DATE NOT NULL,
    status VARCHAR(10) DEFAULT 'pending',
    subtotal DECIMAL(12,2) DEFAULT 0.00,
    total_harga DECIMAL(13,2) DEFAULT 0.00,
    metode_bayar VARCHAR(20),
    status_bayar VARCHAR(20) DEFAULT 'unpaid',
    url_bukti_bayar VARCHAR(50),
    catatan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mahasiswa_id_us VARCHAR(9) NOT NULL,
    Sesi_Waktu_id_slo VARCHAR(9) NOT NULL,
    FOREIGN KEY (mahasiswa_id_us) REFERENCES mahasiswa(id_user)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (Sesi_Waktu_id_slo) REFERENCES Sesi_Waktu(id_slot)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pembayaran (
    id_pembayaran VARCHAR(50) PRIMARY KEY,
    metode VARCHAR(20) NOT NULL,
    status VARCHAR(10) DEFAULT 'pending',
    jumlah DECIMAL(13,2) NOT NULL DEFAULT 0.00,
    kode_unik VARCHAR(50),
    url_bayar VARCHAR(50),
    expired_at TIMESTAMP,
    paid_at TIMESTAMP,
    pre_order_id_pre VARCHAR(9) NOT NULL,
    Payment_gateway VARCHAR(9) NOT NULL,
    FOREIGN KEY (pre_order_id_pre) REFERENCES pre_order(id_pre_order)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (Payment_gateway) REFERENCES Payment_gateway(id_metode)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE pre_order_Menu (
    pre_order_id_pre_ord VARCHAR(9) NOT NULL,
    Menu_id_menu VARCHAR(9) NOT NULL,
    jumlah INT DEFAULT 1,
    harga_satuan DECIMAL(10,2) DEFAULT 0.00,
    PRIMARY KEY (pre_order_id_pre_ord, Menu_id_menu),
    FOREIGN KEY (pre_order_id_pre_ord) REFERENCES pre_order(id_pre_order)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (Menu_id_menu) REFERENCES Menu(id_menu)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE log_status_order (
    id_log SERIAL PRIMARY KEY,
    id_pre_order VARCHAR(9) NOT NULL,
    status_lama VARCHAR(10),
    status_baru VARCHAR(10),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- CREATE INDEXES


CREATE INDEX idx_preorder_mahasiswa ON pre_order(mahasiswa_id_us);
CREATE INDEX idx_preorder_sesiwaktu ON pre_order(Sesi_Waktu_id_slo);
CREATE INDEX idx_preorder_status ON pre_order(status);
CREATE INDEX idx_preorder_tanggal ON pre_order(tanggal_ambil);
CREATE INDEX idx_menu_kategori ON Menu(Kategori_Menu);
CREATE INDEX idx_menu_available ON Menu(is_available);
CREATE INDEX idx_sesiwaktu_kantin ON Sesi_Waktu(Kantin_id_kantin);
CREATE INDEX idx_kategorimenu_kantin ON Kategori_Menu(Kantin_id_kantin);
CREATE INDEX idx_kantin_pemilik ON Kantin(Pemilik_Kantin_id_p);
CREATE INDEX idx_pembayaran_preorder ON pembayaran(pre_order_id_pre);
CREATE INDEX idx_pembayaran_status ON pembayaran(status);


-- CREATE USERS WITH DIFFERENT ACCESS RIGHTS
DROP OWNED BY admin_user, kantin_manager, customer_user, payment_service CASCADE;
DROP ROLE IF EXISTS admin_user;
DROP ROLE IF EXISTS kantin_manager;
DROP ROLE IF EXISTS customer_user;
DROP ROLE IF EXISTS payment_service;


-- User 1: Admin 
CREATE ROLE admin_user WITH LOGIN PASSWORD 'admin_password_123' NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- User 2: Kantin Manager 
CREATE ROLE kantin_manager WITH LOGIN PASSWORD 'manager_password_123' NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- User 3: Customer 
CREATE ROLE customer_user WITH LOGIN PASSWORD 'customer_password_123' NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- User 4: payment Service 
CREATE ROLE payment_service WITH LOGIN PASSWORD 'payment_service_password_123' NOSUPERUSER NOCREATEDB NOCREATEROLE;

-- Grant permissions
GRANT CONNECT ON DATABASE postgres TO admin_user, kantin_manager, customer_user;
GRANT USAGE ON SCHEMA public TO admin_user, kantin_manager, customer_user;

-- Admin: Full permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_user;

-- Kantin Manager
GRANT SELECT ON ALL TABLES IN SCHEMA public TO kantin_manager;
GRANT UPDATE (nama_kantin, lokasi, jam_buka, jam_tutup) ON Kantin TO kantin_manager;
GRANT INSERT ON Sesi_Waktu TO kantin_manager;
GRANT UPDATE (label, jam_mulai, jam_selesai, kapasitas_order, is_active) ON Sesi_Waktu TO kantin_manager;
GRANT INSERT ON Kategori_Menu TO kantin_manager;
GRANT UPDATE (nama_kategori, deskripsi) ON Kategori_Menu TO kantin_manager;
GRANT INSERT ON Menu TO kantin_manager;
GRANT UPDATE (nama_menu, deskripsi, harga, is_available, stok_hari_ini, Kategori_Menu) ON Menu TO kantin_manager;
GRANT UPDATE (status) ON pre_order TO kantin_manager;

-- Customer
GRANT SELECT ON mahasiswa, Kantin, Sesi_Waktu, Kategori_Menu, Menu, Payment_gateway TO customer_user;
GRANT INSERT (id_pre_order,kode_order,tanggal_ambil,metode_bayar,catatan,mahasiswa_id_us,Sesi_Waktu_id_slo)
ON pre_order TO customer_user;
GRANT UPDATE (tanggal_ambil,metode_bayar,catatan,Sesi_Waktu_id_slo) ON pre_order TO customer_user;
GRANT INSERT (pre_order_id_pre_ord,Menu_id_menu,jumlah) ON pre_order_Menu TO customer_user;
GRANT SELECT ON pembayaran TO customer_user;

-- payment service

GRANT CONNECT ON DATABASE postgres TO payment_service;
GRANT USAGE ON SCHEMA public TO payment_service;
GRANT INSERT ON pembayaran TO payment_service;
GRANT UPDATE (status, kode_unik, url_bayar, expired_at, paid_at) ON pembayaran TO payment_service;
GRANT UPDATE (status_bayar, url_bukti_bayar, updated_at) ON pre_order TO payment_service;
GRANT SELECT ON pre_order, pembayaran, Payment_gateway TO payment_service;