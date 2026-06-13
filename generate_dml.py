"""
Generate realistic DML data for K-RUN (Kantin ITS Pre-Order System)
"""
import random
from datetime import datetime, timedelta, date, time

random.seed(42)

# ===================== DATA POOLS =====================

NAMA_DEPAN = [
    "Ahmad", "Budi", "Candra", "Dimas", "Eko", "Farhan", "Galih", "Hendra",
    "Irfan", "Joko", "Kevin", "Lukman", "Muhammad", "Nanda", "Oscar",
    "Putra", "Reza", "Satria", "Teguh", "Umar", "Vino", "Wahyu", "Yusuf",
    "Zainal", "Andi", "Bayu", "Deni", "Fajar", "Gilang", "Hari",
    "Rizky", "Arif", "Bagus", "Dwi", "Faisal", "Hanif", "Ilham",
    "Kurniawan", "Maulana", "Nur", "Prasetyo", "Raditya", "Surya",
    "Aditya", "Bambang", "Cahyo", "Doni", "Firman", "Gunawan", "Yoga"
]

NAMA_BELAKANG = [
    "Pratama", "Saputra", "Nugroho", "Hidayat", "Santoso", "Wibowo",
    "Kusuma", "Setiawan", "Ramadhan", "Permana", "Purnomo", "Hartono",
    "Susanto", "Suryadi", "Wijaya", "Firmansyah", "Darmawan", "Kurniawan",
    "Mahendra", "Hakim", "Utomo", "Ardiansyah", "Prasetya", "Maulana",
    "Fadillah", "Rahman", "Herlambang", "Arifin", "Budiman", "Cahyono",
    "Dermawan", "Efendi", "Fauzi", "Gunawan", "Iskandar", "Julianto",
    "Kuswanto", "Lesmana", "Mulyadi", "Nasution", "Oktavian", "Pangestu",
    "Rachman", "Sugiarto", "Tirtayasa", "Utama", "Valentino", "Wicaksono",
    "Yudhoyono", "Zulfikar"
]

NAMA_PEMILIK = [
    "Siti Aminah", "Bambang Sutrisno", "Ibu Yanti", "Pak Joko Susilo",
    "Hj. Nurjanah", "Bapak Sudarso", "Bu Endang Lestari", "Pak Agus Salim",
    "Ibu Maryam", "H. Abdul Rohman", "Bu Sari Dewi", "Pak Heri Prasetyo",
    "Ibu Kartini", "Bapak Wahyudi", "Bu Titik Sumarni", "Pak Darminto",
    "Ibu Rahayu", "Bapak Suroto", "Bu Wati Handayani", "Pak Mulyono",
    "Ibu Lasmi", "Bapak Suyanto", "Bu Tutik Lestari", "Pak Bambang Wiyono",
    "Ibu Sulastri", "Bapak Triyono", "Bu Ningsih", "Pak Hariyanto",
    "Ibu Puji Astuti", "Bapak Suprapto", "Bu Khasanah", "Pak Warsito",
    "Ibu Sumiyati", "Bapak Parman", "Bu Lilis Suryani", "Pak Sugeng",
    "Ibu Fatimah", "Bapak Santoso", "Bu Rusmini", "Pak Mujianto"
]

LOKASI_KANTIN_ITS = [
    "Kantin Pusat ITS, Gedung Riset Center Lt.1",
    "Kantin Pusat ITS, Sayap Barat",
    "Kantin Pusat ITS, Sayap Timur",
    "Kantin Pusat ITS, Area Depan",
    "Kantin Pusat ITS, Area Belakang",
    "Kantin Teknik Informatika, Gedung TC Lt.1",
    "Kantin Teknik Informatika, Gedung TC Lt.Dasar",
    "Kantin Teknik Informatika, Sebelah Musholla TC",
    "Kantin Teknik Sipil, Gedung Teknik Sipil Lt.1",
    "Kantin Teknik Sipil, Area Parkiran Sipil",
    "Kantin Teknik Mesin, Gedung Teknik Mesin Lt.1",
    "Kantin Teknik Mesin, Belakang Lab Mesin",
    "Kantin Teknik Kimia, Jalan Teknik Kimia ITS",
    "Kantin Teknik Kimia, Sebelah Perpustakaan TK",
    "Kantin FMIPA, Gedung FMIPA Lt.1",
    "Kantin FMIPA, Sebelah Lab Fisika",
    "Kantin Asrama Mahasiswa ITS, Blok U",
    "Kantin Asrama Mahasiswa ITS, Blok T",
    "Kantin Asrama Mahasiswa ITS, Area Foodcourt",
    "Kantin Asrama Mahasiswa ITS, Blok J",
    "Kantin SCC ITS, Student Community Center Lt.1",
    "Kantin SCC ITS, Area Outdoor SCC",
    "Kantin Graha ITS, Gedung Graha Sepuluh Nopember",
    "Kantin Graha ITS, Belakang Aula Graha",
    "Kantin Manarul Ilmi, Masjid Manarul Ilmi ITS",
    "Kantin Teknik Elektro, Gedung AJ Lt.1",
    "Kantin Teknik Elektro, Sebelah Lab Elektronika",
    "Kantin Desain, Gedung Desain Produk Lt.1",
    "Kantin Arsitektur, Gedung Arsitektur ITS",
    "Kantin Teknik Industri, Gedung TI Lt.1",
    "Kantin Teknik Perkapalan, Gedung Perkapalan ITS",
    "Kantin Teknik Kelautan, Sebelah Kolam Renang ITS",
    "Kantin Teknik Lingkungan, Gedung TL Lt.1",
    "Kantin PWK, Gedung Planologi ITS",
    "Kantin Sistem Informasi, Gedung SI Lt.1",
    "Kantin Teknik Geomatika, Gedung Geomatika ITS",
    "Kantin Teknik Material, Gedung Material ITS",
    "Kantin Teknik Biomedik, Gedung Biomedik ITS",
    "Kantin Sains dan Analitika, Gedung SA Lt.1",
    "Kantin Bundaran ITS, Area Bundaran ITS"
]

NAMA_KANTIN = [
    "Warung Nasi Bu Siti", "Mie Ayam Pak Joko", "Soto Lamongan Cak Har",
    "Bakso Malang Arema", "Nasi Goreng Mas Budi", "Rawon Setan Surabaya",
    "Pecel Lele Lela", "Ayam Geprek Bensu", "Nasi Padang Minang Jaya",
    "Warung Tegal Sederhana", "Es Teh Jumbo", "Sate Madura Pak Amin",
    "Nasi Campur Bu Rudy", "Rujak Cingur Surabaya", "Lontong Balap Garuda",
    "Tahu Tek Kenjeran", "Nasi Pecel Bu Kus", "Gado-gado Boplo",
    "Nasi Kuning Madura", "Bubur Ayam Jakarta", "Ketoprak Betawi",
    "Sop Buntut Pak Min", "Tongseng Kambing Solo", "Gudeg Yu Djum",
    "Nasi Uduk Betawi", "Geprek Kang Mus", "Dimsum Bamboo",
    "Ramen Ichiban", "Seblak Bandung Juara", "Mie Aceh Pak Tong",
    "Pempek Palembang Asli", "Nasi Liwet Solo", "Ayam Bakar Wong Solo",
    "Warung Sego Sambel", "Bebek Goreng H. Slamet", "Nasi Jagung Bu Dar",
    "Cwie Mie Malang", "Es Campur Legendaris", "Teh Poci Pak Kumis",
    "Kedai Kopi Kenangan"
]

KATEGORI_MENU_DATA = [
    ("KAT001", "Nasi", "Aneka menu berbahan dasar nasi"),
    ("KAT002", "Mie", "Aneka mie dan kwetiau"),
    ("KAT003", "Soto dan Sup", "Soto, sup, dan berkuah"),
    ("KAT004", "Bakso", "Aneka bakso dan pentol"),
    ("KAT005", "Ayam", "Aneka olahan ayam"),
    ("KAT006", "Sate", "Aneka sate"),
    ("KAT007", "Gorengan", "Aneka gorengan dan snack"),
    ("KAT008", "Minuman Dingin", "Es, jus, dan minuman dingin"),
    ("KAT009", "Minuman Panas", "Kopi, teh, dan minuman panas"),
    ("KAT010", "Pecel dan Lalapan", "Pecel, lalapan, dan sambal"),
    ("KAT011", "Seafood", "Aneka seafood"),
    ("KAT012", "Padang", "Masakan Padang"),
    ("KAT013", "Jawa", "Masakan khas Jawa"),
    ("KAT014", "Dimsum", "Aneka dimsum"),
    ("KAT015", "Ramen", "Ramen dan mie Jepang"),
    ("KAT016", "Seblak", "Aneka seblak pedas"),
    ("KAT017", "Pempek", "Pempek dan tekwan"),
    ("KAT018", "Bubur", "Aneka bubur"),
    ("KAT019", "Lontong dan Ketupat", "Lontong, ketupat, dan nasi tumpeng"),
    ("KAT020", "Bebek", "Aneka olahan bebek"),
    ("KAT021", "Dessert", "Kue, es krim, dan makanan penutup"),
    ("KAT022", "Rujak", "Aneka rujak dan lotis"),
    ("KAT023", "Gado-gado", "Gado-gado, ketoprak, tahu tek"),
    ("KAT024", "Nasi Goreng", "Aneka nasi goreng spesial"),
    ("KAT025", "Paket Hemat", "Paket makanan hemat mahasiswa"),
    ("KAT026", "Jus Buah", "Aneka jus buah segar"),
    ("KAT027", "Sop dan Rawon", "Sop, rawon, dan semur"),
    ("KAT028", "Ikan", "Aneka olahan ikan"),
    ("KAT029", "Makanan Ringan", "Snack dan cemilan"),
    ("KAT030", "Nasi Campur", "Nasi campur dan nasi rames"),
    ("KAT031", "Mie Ayam", "Mie ayam dan pangsit"),
    ("KAT032", "Tahu dan Tempe", "Aneka olahan tahu tempe"),
    ("KAT033", "Sambal", "Nasi dengan aneka sambal"),
    ("KAT034", "Geprek", "Ayam geprek berbagai level"),
    ("KAT035", "Bakar", "Aneka bakaran"),
    ("KAT036", "Nasi Kuning", "Nasi kuning dan tumpeng"),
    ("KAT037", "Kopi", "Aneka kopi nusantara"),
    ("KAT038", "Tongseng", "Tongseng dan tengkleng"),
    ("KAT039", "Gudeg", "Gudeg khas Jogja"),
    ("KAT040", "Siomay", "Siomay dan batagor"),
]

MENU_DATA = [
    ("MNU001", "Nasi Goreng Spesial", "Nasi goreng dengan telur, ayam, dan sayuran", 15000, "KAT024"),
    ("MNU002", "Nasi Goreng Seafood", "Nasi goreng dengan udang dan cumi", 18000, "KAT024"),
    ("MNU003", "Mie Ayam Bakso", "Mie ayam dengan bakso sapi", 12000, "KAT031"),
    ("MNU004", "Mie Ayam Pangsit", "Mie ayam dengan pangsit goreng", 13000, "KAT031"),
    ("MNU005", "Soto Ayam Lamongan", "Soto ayam khas Lamongan", 12000, "KAT003"),
    ("MNU006", "Soto Daging Madura", "Soto daging sapi khas Madura", 18000, "KAT003"),
    ("MNU007", "Bakso Urat", "Bakso urat sapi jumbo", 15000, "KAT004"),
    ("MNU008", "Bakso Telur", "Bakso isi telur puyuh", 13000, "KAT004"),
    ("MNU009", "Ayam Geprek Sambal Matah", "Ayam geprek level 1-5 dengan sambal matah", 14000, "KAT034"),
    ("MNU010", "Ayam Geprek Mozarella", "Ayam geprek dengan keju mozarella", 18000, "KAT034"),
    ("MNU011", "Nasi Padang Rendang", "Nasi dengan rendang sapi asli", 20000, "KAT012"),
    ("MNU012", "Nasi Padang Ayam Pop", "Nasi dengan ayam pop dan sambal", 17000, "KAT012"),
    ("MNU013", "Sate Ayam Madura", "10 tusuk sate ayam plus lontong", 15000, "KAT006"),
    ("MNU014", "Sate Kambing", "10 tusuk sate kambing", 25000, "KAT006"),
    ("MNU015", "Pecel Lele Goreng", "Lele goreng dengan sambal pecel", 13000, "KAT010"),
    ("MNU016", "Nasi Pecel Komplit", "Nasi pecel dengan lauk lengkap", 12000, "KAT010"),
    ("MNU017", "Rawon Daging Sapi", "Rawon daging sapi khas Surabaya", 20000, "KAT027"),
    ("MNU018", "Sop Iga Sapi", "Sop iga sapi dengan kuah bening", 25000, "KAT027"),
    ("MNU019", "Rujak Cingur", "Rujak cingur khas Surabaya asli", 15000, "KAT022"),
    ("MNU020", "Rujak Buah Segar", "Rujak buah campur dengan bumbu petis", 10000, "KAT022"),
    ("MNU021", "Lontong Balap", "Lontong balap khas Surabaya", 12000, "KAT019"),
    ("MNU022", "Lontong Sayur", "Lontong sayur dengan opor ayam", 13000, "KAT019"),
    ("MNU023", "Tahu Tek", "Tahu tek khas Surabaya dengan petis", 10000, "KAT023"),
    ("MNU024", "Gado-gado Jakarta", "Gado-gado dengan bumbu kacang", 12000, "KAT023"),
    ("MNU025", "Nasi Kuning Madura", "Nasi kuning dengan ayam suwir", 12000, "KAT036"),
    ("MNU026", "Nasi Kuning Telur Balado", "Nasi kuning dengan telur balado", 11000, "KAT036"),
    ("MNU027", "Bubur Ayam Spesial", "Bubur ayam dengan cakwe dan kerupuk", 12000, "KAT018"),
    ("MNU028", "Bubur Kacang Hijau", "Bubur kacang hijau hangat", 8000, "KAT018"),
    ("MNU029", "Ketoprak Jakarta", "Ketoprak dengan bumbu kacang", 11000, "KAT023"),
    ("MNU030", "Nasi Campur Bali", "Nasi campur khas Bali komplit", 18000, "KAT030"),
    ("MNU031", "Nasi Campur Bu Rudy", "Nasi campur khas Surabaya", 20000, "KAT030"),
    ("MNU032", "Tongseng Kambing", "Tongseng kambing khas Solo", 22000, "KAT038"),
    ("MNU033", "Tengkleng Kambing", "Tengkleng iga kambing Solo", 20000, "KAT038"),
    ("MNU034", "Gudeg Jogja Komplit", "Gudeg komplit dengan opor dan krecek", 18000, "KAT039"),
    ("MNU035", "Gudeg Nangka", "Gudeg nangka tanpa tulang", 15000, "KAT039"),
    ("MNU036", "Nasi Uduk Betawi", "Nasi uduk dengan ayam goreng", 14000, "KAT001"),
    ("MNU037", "Nasi Rames Jawa", "Nasi rames dengan pilihan lauk", 13000, "KAT001"),
    ("MNU038", "Dimsum Hakau", "Hakau udang kukus 4 pcs", 15000, "KAT014"),
    ("MNU039", "Dimsum Siomay Ayam", "Siomay ayam kukus 4 pcs", 13000, "KAT014"),
    ("MNU040", "Ramen Miso", "Ramen kuah miso Jepang", 22000, "KAT015"),
    ("MNU041", "Ramen Shoyu", "Ramen kuah kecap Jepang", 22000, "KAT015"),
    ("MNU042", "Seblak Original", "Seblak kerupuk level pedas 1-5", 12000, "KAT016"),
    ("MNU043", "Seblak Seafood", "Seblak dengan topping seafood", 16000, "KAT016"),
    ("MNU044", "Pempek Kapal Selam", "Pempek telur khas Palembang", 10000, "KAT017"),
    ("MNU045", "Pempek Lenjer", "Pempek lenjer 3 pcs dengan cuko", 12000, "KAT017"),
    ("MNU046", "Bebek Goreng Kremes", "Bebek goreng dengan kremesan", 22000, "KAT020"),
    ("MNU047", "Bebek Penyet Sambal", "Bebek penyet sambal bawang", 20000, "KAT020"),
    ("MNU048", "Es Teh Manis", "Es teh manis segar", 5000, "KAT008"),
    ("MNU049", "Es Jeruk Peras", "Es jeruk peras segar", 7000, "KAT008"),
    ("MNU050", "Jus Alpukat", "Jus alpukat segar dengan susu", 10000, "KAT026"),
    ("MNU051", "Jus Mangga", "Jus mangga segar tanpa gula", 8000, "KAT026"),
    ("MNU052", "Kopi Hitam", "Kopi hitam tubruk Jawa", 5000, "KAT037"),
    ("MNU053", "Kopi Susu Gula Aren", "Es kopi susu dengan gula aren", 12000, "KAT037"),
    ("MNU054", "Teh Poci Hangat", "Teh poci khas Tegal", 5000, "KAT009"),
    ("MNU055", "Wedang Jahe", "Wedang jahe hangat", 7000, "KAT009"),
    ("MNU056", "Nasi Goreng Kampung", "Nasi goreng bumbu kampung", 13000, "KAT024"),
    ("MNU057", "Mie Goreng Jawa", "Mie goreng khas Jawa", 12000, "KAT002"),
    ("MNU058", "Kwetiau Goreng", "Kwetiau goreng seafood", 15000, "KAT002"),
    ("MNU059", "Ayam Bakar Kalasan", "Ayam bakar bumbu kalasan", 18000, "KAT035"),
    ("MNU060", "Ikan Bakar Bumbu Rujak", "Ikan bakar dengan bumbu rujak", 22000, "KAT035"),
    ("MNU061", "Udang Goreng Tepung", "Udang goreng tepung crispy", 20000, "KAT011"),
    ("MNU062", "Cumi Goreng Tepung", "Cumi goreng tepung", 18000, "KAT011"),
    ("MNU063", "Ikan Gurami Asam Manis", "Gurami goreng saus asam manis", 30000, "KAT028"),
    ("MNU064", "Ikan Nila Bakar", "Ikan nila bakar bumbu kecap", 20000, "KAT028"),
    ("MNU065", "Tahu Goreng Crispy", "Tahu goreng crispy 5 pcs", 8000, "KAT032"),
    ("MNU066", "Tempe Mendoan", "Tempe mendoan tipis 5 pcs", 8000, "KAT032"),
    ("MNU067", "Nasi Sambel Bawang", "Nasi putih dengan sambal bawang", 10000, "KAT033"),
    ("MNU068", "Nasi Sambel Matah", "Nasi putih dengan sambal matah Bali", 11000, "KAT033"),
    ("MNU069", "Pisang Goreng Coklat", "Pisang goreng topping coklat", 8000, "KAT021"),
    ("MNU070", "Es Campur", "Es campur buah segar", 10000, "KAT021"),
    ("MNU071", "Tahu Crispy Pedas", "Tahu crispy dengan saus pedas", 7000, "KAT029"),
    ("MNU072", "Kentang Goreng", "French fries dengan saus sambal", 10000, "KAT029"),
    ("MNU073", "Paket Nasi Ayam Hemat", "Nasi plus ayam goreng plus es teh", 15000, "KAT025"),
    ("MNU074", "Paket Nasi Lele Hemat", "Nasi plus lele goreng plus es teh", 14000, "KAT025"),
    ("MNU075", "Nasi Liwet Solo", "Nasi liwet khas Solo komplit", 16000, "KAT001"),
    ("MNU076", "Ayam Penyet Sambal Terasi", "Ayam penyet sambal terasi", 15000, "KAT005"),
    ("MNU077", "Ayam Kremes", "Ayam goreng dengan kremesan", 16000, "KAT005"),
    ("MNU078", "Siomay Bandung", "Siomay bandung isi 5 komplit", 12000, "KAT040"),
    ("MNU079", "Batagor Kuah", "Batagor kuah kacang khas Bandung", 12000, "KAT040"),
    ("MNU080", "Mie Aceh Goreng", "Mie Aceh goreng spesial", 16000, "KAT002"),
    ("MNU081", "Cwie Mie Malang", "Cwie mie khas Malang", 13000, "KAT002"),
    ("MNU082", "Nasi Jagung", "Nasi jagung khas NTT", 10000, "KAT001"),
    ("MNU083", "Sego Sambel Pak Kumis", "Nasi putih aneka sambal pilihan", 12000, "KAT033"),
    ("MNU084", "Teh Tarik", "Teh tarik khas Malaysia", 8000, "KAT009"),
    ("MNU085", "Es Dawet Ireng", "Es dawet hitam khas Purworejo", 8000, "KAT008"),
]

PAYMENT_GATEWAY_DATA = [
    ("PAY001", "GoPay", "E-Wallet"),
    ("PAY002", "OVO", "E-Wallet"),
    ("PAY003", "Dana", "E-Wallet"),
    ("PAY004", "ShopeePay", "E-Wallet"),
    ("PAY005", "LinkAja", "E-Wallet"),
    ("PAY006", "Doku Wallet", "E-Wallet"),
    ("PAY007", "iSaku", "E-Wallet"),
    ("PAY008", "Sakuku BCA", "E-Wallet"),
    ("PAY009", "Jenius Pay", "E-Wallet"),
    ("PAY010", "Blu by BCA Digital", "E-Wallet"),
    ("PAY011", "BCA Transfer", "Bank Transfer"),
    ("PAY012", "BNI Transfer", "Bank Transfer"),
    ("PAY013", "BRI Transfer", "Bank Transfer"),
    ("PAY014", "Mandiri Transfer", "Bank Transfer"),
    ("PAY015", "BSI Transfer", "Bank Transfer"),
    ("PAY016", "CIMB Niaga Transfer", "Bank Transfer"),
    ("PAY017", "Danamon Transfer", "Bank Transfer"),
    ("PAY018", "Permata Transfer", "Bank Transfer"),
    ("PAY019", "BTN Transfer", "Bank Transfer"),
    ("PAY020", "Maybank Transfer", "Bank Transfer"),
    ("PAY021", "BCA Virtual Account", "Virtual Account"),
    ("PAY022", "BNI Virtual Account", "Virtual Account"),
    ("PAY023", "BRI Virtual Account", "Virtual Account"),
    ("PAY024", "Mandiri Virtual Account", "Virtual Account"),
    ("PAY025", "Permata Virtual Account", "Virtual Account"),
    ("PAY026", "CIMB VA", "Virtual Account"),
    ("PAY027", "Danamon VA", "Virtual Account"),
    ("PAY028", "BTN VA", "Virtual Account"),
    ("PAY029", "BSI VA", "Virtual Account"),
    ("PAY030", "Maybank VA", "Virtual Account"),
    ("PAY031", "QRIS GoPay", "QRIS"),
    ("PAY032", "QRIS OVO", "QRIS"),
    ("PAY033", "QRIS Dana", "QRIS"),
    ("PAY034", "QRIS ShopeePay", "QRIS"),
    ("PAY035", "QRIS LinkAja", "QRIS"),
    ("PAY036", "Alfamart", "Retail"),
    ("PAY037", "Indomaret", "Retail"),
    ("PAY038", "Alfamidi", "Retail"),
    ("PAY039", "Visa Credit Card", "Kartu Kredit"),
    ("PAY040", "Mastercard Credit Card", "Kartu Kredit"),
]

# ===================== GENERATE SQL =====================

lines = []
lines.append("-- =====================================================")
lines.append("-- DML - DATA DUMMY K-RUN SISTEM PRE-ORDER KANTIN ITS")
lines.append("-- Kelompok 8 - Manajemen Basis Data (B)")
lines.append("-- =====================================================")
lines.append("")

# ---------- mahasiswa (50) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT mahasiswa (50 rows)")
lines.append("-- =====================================================")
lines.append("")

used_names = set()
mahasiswa_ids = []
for i in range(1, 51):
    uid = f"USR{i:03d}"
    mahasiswa_ids.append(uid)
    while True:
        fn = random.choice(NAMA_DEPAN)
        ln = random.choice(NAMA_BELAKANG)
        full = f"{fn} {ln}"
        if full not in used_names:
            used_names.add(full)
            break
    nrp = f"5025{random.choice(['22','23','24'])}{random.randint(1000,1999)}"
    email = f"{fn.lower()}.{ln.lower()}{random.randint(1,99)}@student.its.ac.id"
    hp = f"08{random.choice(['11','12','13','21','22','31','52','53','57','58','59','77','78','81','82','83','85','88'])}{random.randint(10000000,99999999)}"
    ts = f"2026-{random.randint(1,5):02d}-{random.randint(1,28):02d} {random.randint(8,20):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"
    lines.append(f"INSERT INTO mahasiswa VALUES ('{uid}', '{full}', '{email}', '{hp}', '{ts}');")

lines.append("")

# ---------- Pemilik_Kantin (40) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Pemilik_Kantin (40 rows)")
lines.append("-- =====================================================")
lines.append("")

pemilik_ids = []
for i in range(1, 41):
    pid = f"PMK{i:03d}"
    pemilik_ids.append(pid)
    nama = NAMA_PEMILIK[i-1]
    email_name = nama.lower().replace(" ", ".").replace(".", "_", 1).replace(" ", "")
    email = f"{nama.lower().replace(' ','').replace('.','')}{random.randint(1,99)}@gmail.com"
    hp = f"08{random.choice(['11','12','13','21','22','31','52','53','57','58','59','77','78','81','82','83','85','88'])}{random.randint(10000000,99999999)}"
    pw = f"hashed_pw_{pid.lower()}"
    lines.append(f"INSERT INTO Pemilik_Kantin VALUES ('{pid}', '{nama}', '{email}', '{hp}', '{pw}');")

lines.append("")

# ---------- Kantin (40) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Kantin (40 rows)")
lines.append("-- =====================================================")
lines.append("")

kantin_ids = []
for i in range(1, 41):
    kid = f"KNT{i:03d}"
    kantin_ids.append(kid)
    nama_k = NAMA_KANTIN[i-1]
    lokasi = LOKASI_KANTIN_ITS[i-1]
    jam_buka_h = random.choice([7, 8, 9])
    jam_tutup_h = random.choice([17, 18, 19, 20])
    rating = round(random.uniform(3.5, 5.0), 1)
    pemilik = pemilik_ids[i-1]
    lines.append(f"INSERT INTO Kantin VALUES ('{kid}', '{nama_k}', '{lokasi}', '{jam_buka_h:02d}:00:00', '{jam_tutup_h:02d}:00:00', {rating}, '{pemilik}');")

lines.append("")

# ---------- Sesi_Waktu (80 = 2 slot x 40 kantin) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Sesi_Waktu (80 rows - 2 sesi per kantin)")
lines.append("-- =====================================================")
lines.append("")

slot_ids = []
slot_counter = 0
for i, kid in enumerate(kantin_ids):
    for sesi_idx, (label, jm, js) in enumerate([
        ("Siang", "11:00:00", "13:30:00"),
        ("Sore", "15:30:00", "18:00:00"),
    ]):
        slot_counter += 1
        sid = f"SLT{slot_counter:03d}"
        slot_ids.append(sid)
        kap = random.randint(15, 50)
        active = "TRUE" if random.random() > 0.1 else "FALSE"
        lines.append(f"INSERT INTO Sesi_Waktu VALUES ('{sid}', '{label}', '{jm}', '{js}', {kap}, {active}, '{kid}');")

lines.append("")

# ---------- Kategori_Menu (40) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Kategori_Menu (40 rows)")
lines.append("-- =====================================================")
lines.append("")

kategori_ids = []
for kid_idx, (kat_id, nama_kat, desk) in enumerate(KATEGORI_MENU_DATA):
    kategori_ids.append(kat_id)
    # Assign kategori to random kantin
    assigned_kantin = kantin_ids[kid_idx % len(kantin_ids)]
    lines.append(f"INSERT INTO Kategori_Menu VALUES ('{kat_id}', '{nama_kat}', '{desk}', '{assigned_kantin}');")

lines.append("")

# ---------- Menu (85) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Menu (85 rows)")
lines.append("-- =====================================================")
lines.append("")

menu_ids = []
for mid, nama_m, desk_m, harga, kat_id in MENU_DATA:
    menu_ids.append(mid)
    stok = random.randint(10, 50)
    terjual = random.randint(0, min(stok, 20))
    avail = "TRUE" if stok > 0 else "FALSE"
    lines.append(f"INSERT INTO Menu VALUES ('{mid}', '{nama_m}', '{desk_m}', {harga:.2f}, {avail}, {stok}, {terjual}, '{kat_id}');")

lines.append("")

# ---------- Payment_gateway (40) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT Payment_gateway (40 rows)")
lines.append("-- =====================================================")
lines.append("")

pg_ids = []
for pg_id, nama_pg, tipe_pg in PAYMENT_GATEWAY_DATA:
    pg_ids.append(pg_id)
    active = "TRUE" if random.random() > 0.15 else "FALSE"
    lines.append(f"INSERT INTO Payment_gateway VALUES ('{pg_id}', '{nama_pg}', '{tipe_pg}', {active});")

lines.append("")

# ---------- pre_order (120) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT pre_order (120 rows)")
lines.append("-- =====================================================")
lines.append("")

po_ids = []
statuses = ['pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled']
status_bayar_opts = ['unpaid', 'paid', 'expired', 'refunded']
metode_bayar_opts = ['e-wallet', 'bank_transfer', 'va', 'qris', 'retail', 'kartu_kredit']

base_date = date(2026, 4, 1)
for i in range(1, 121):
    po_id = f"PRE{i:03d}"
    po_ids.append(po_id)
    kode = f"KR-{base_date.year}{(base_date.month + (i-1)//30):02d}{((i-1)%30+1):02d}-{random.randint(1000,9999)}"
    days_offset = random.randint(0, 70)
    tgl_ambil = base_date + timedelta(days=days_offset)
    status = random.choices(statuses, weights=[10, 15, 10, 15, 40, 10], k=1)[0]
    
    # Generate menu items for this order (1-4 items)
    num_items = random.randint(1, 4)
    selected_menus = random.sample(MENU_DATA, min(num_items, len(MENU_DATA)))
    subtot = sum(m[3] * random.randint(1, 3) for m in selected_menus)
    total = subtot  # simplified
    
    metode = random.choice(metode_bayar_opts)
    if status == 'completed':
        sb = 'paid'
    elif status == 'cancelled':
        sb = random.choice(['refunded', 'expired'])
    else:
        sb = random.choice(['unpaid', 'paid'])
    
    url_bukti = f"https://krun.its.ac.id/bukti/{po_id}" if sb == 'paid' else ""
    catatan_opts = [
        "Tidak pakai sambal", "Extra pedas level 5", "Tambah nasi", "Tanpa sayuran",
        "Pakai plastik terpisah", "Tidak pakai bawang", "Extra kuah", "Minta sendok garpu",
        "Sambal terpisah", "", "", "", "", "", ""
    ]
    catatan = random.choice(catatan_opts)
    
    created = datetime(2026, 4, 1) + timedelta(days=days_offset - random.randint(0, 2),
                                                  hours=random.randint(7, 11),
                                                  minutes=random.randint(0, 59))
    updated = created + timedelta(hours=random.randint(0, 4))
    
    mhs = random.choice(mahasiswa_ids)
    sesi = random.choice(slot_ids)
    
    lines.append(f"INSERT INTO pre_order VALUES ('{po_id}', '{kode}', '{tgl_ambil}', '{status}', {subtot:.2f}, {total:.2f}, '{metode}', '{sb}', '{url_bukti}', '{catatan}', '{created.strftime('%Y-%m-%d %H:%M:%S')}', '{updated.strftime('%Y-%m-%d %H:%M:%S')}', '{mhs}', '{sesi}');")

lines.append("")

# ---------- pre_order_Menu (200+) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT pre_order_Menu (200+ rows)")
lines.append("-- =====================================================")
lines.append("")

po_menu_pairs = set()
po_menu_count = 0
for po_id in po_ids:
    num_items = random.randint(1, 4)
    selected = random.sample(menu_ids, min(num_items, len(menu_ids)))
    for m_id in selected:
        if (po_id, m_id) not in po_menu_pairs:
            po_menu_pairs.add((po_id, m_id))
            jumlah = random.randint(1, 3)
            # Get harga from MENU_DATA
            harga = 0
            for md in MENU_DATA:
                if md[0] == m_id:
                    harga = md[3]
                    break
            lines.append(f"INSERT INTO pre_order_Menu VALUES ('{po_id}', '{m_id}', {jumlah}, {harga:.2f});")
            po_menu_count += 1

lines.append("")
lines.append(f"-- Total pre_order_Menu rows: {po_menu_count}")
lines.append("")

# ---------- pembayaran (120) ----------
lines.append("-- =====================================================")
lines.append("-- INSERT pembayaran (120 rows)")
lines.append("-- =====================================================")
lines.append("")

for i in range(1, 121):
    pby_id = f"PBY-{po_ids[i-1]}-{random.randint(100,999)}"
    po_id = po_ids[i-1]
    metode = random.choice(["GoPay", "OVO", "Dana", "ShopeePay", "BCA VA", "BNI VA", "QRIS", "Mandiri VA", "BRI VA", "LinkAja"])
    # Match status with pre_order
    status = random.choice(["pending", "success", "failed", "expired"])
    jumlah = random.randint(10000, 80000)
    kode_unik = f"UNQ-{random.randint(100000,999999)}"
    url_bayar = f"https://pay.krun.its.ac.id/{pby_id}"
    
    base_ts = datetime(2026, 4, 1) + timedelta(days=random.randint(0, 70),
                                                  hours=random.randint(7, 18),
                                                  minutes=random.randint(0, 59))
    expired = base_ts + timedelta(hours=24)
    paid_at = base_ts + timedelta(minutes=random.randint(1, 120)) if status == "success" else None
    
    pg_id = random.choice(pg_ids)
    
    paid_str = f"'{paid_at.strftime('%Y-%m-%d %H:%M:%S')}'" if paid_at else "NULL"
    
    lines.append(f"INSERT INTO pembayaran VALUES ('{pby_id}', '{metode}', '{status}', {jumlah:.2f}, '{kode_unik}', '{url_bayar}', '{expired.strftime('%Y-%m-%d %H:%M:%S')}', {paid_str}, '{po_id}', '{pg_id}');")

lines.append("")
lines.append("-- =====================================================")
lines.append("-- END OF DML")
lines.append("-- =====================================================")

# Write to file
output_path = r"c:\Users\TUF\OneDrive\Semester 4\MBD\FP MBD\dml.sql"
with open(output_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

print(f"Generated {output_path}")
print(f"  mahasiswa: 50")
print(f"  Pemilik_Kantin: 40")
print(f"  Kantin: 40")
print(f"  Sesi_Waktu: {len(slot_ids)}")
print(f"  Kategori_Menu: {len(kategori_ids)}")
print(f"  Menu: {len(menu_ids)}")
print(f"  Payment_gateway: {len(pg_ids)}")
print(f"  pre_order: {len(po_ids)}")
print(f"  pre_order_Menu: {po_menu_count}")
print(f"  pembayaran: 120")
