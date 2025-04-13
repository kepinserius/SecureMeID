# SecureMeID - Dompet Identitas Blockchain

Aplikasi dompet digital yang menyimpan dokumen identitas pribadi di blockchain, memberikan keamanan untuk verifikasi KYC tanpa mengekspos dokumen mentah.

## Fitur Utama

### Fitur Inti
- **Penyimpanan Identitas Terenkripsi**: Simpan KTP, SIM, dan dokumen identitas lainnya secara aman di IPFS dengan enkripsi kunci pribadi
- **Integrasi Blockchain**: Catatan dokumen diamankan di Internet Computer Protocol (ICP)
- **Autentikasi Biometrik**: Akses dokumen Anda hanya dengan sidik jari atau FaceID
- **Verifikasi KYC Aman**: Bagikan token verifikasi tanpa menunjukkan dokumen asli
- **Pemulihan via Rekan Terpercaya**: Sistem pemulihan multi-signature melalui kontak terpercaya

### Fitur Tambahan
- **Pemeriksa Validitas Dokumen**: Verifikasi keaslian dan tanggal kedaluwarsa dokumen
- **Pengungkapan Selektif**: Bagikan hanya informasi spesifik dari dokumen
- **Jejak Audit**: Lacak kapan dan dengan siapa identitas Anda dibagikan
- **Zero-Knowledge Proofs**: Buktikan atribut identitas tanpa mengungkapkan data sebenarnya
- **Sinkronisasi Lintas Platform**: Sinkronkan identitas Anda secara aman di berbagai perangkat
- **Fungsi Offline**: Akses dokumen penting bahkan tanpa koneksi internet
- **Protokol Akses Darurat**: Tentukan kondisi akses darurat dan pihak yang berwenang

## Stack Teknologi

- **Frontend**: Flutter untuk pengembangan mobile lintas platform
- **Penyimpanan Blockchain**: Internet Computer Protocol (ICP)
- **Smart Contracts**: Canister ICP (Motoko/Rust)
- **Enkripsi**: AES-256 + RSA Encryption
- **Autentikasi Biometrik**: Plugin Flutter LocalAuth
- **Penyimpanan Lokal**: Hive untuk penyimpanan terenkripsi

## Memulai

### Prasyarat
- Flutter SDK (versi 3.0+)
- Dart SDK (versi 2.17+)
- Akses ke Internet Computer Protocol (ICP)
- Identitas Internet Identity (II) untuk autentikasi

### Instalasi
1. Clone repositori
```
git clone https://github.com/kepinserius/SecureMeID.git
```

2. Instal dependensi
```
cd SecureMeID
flutter pub get
```

3. Jalankan aplikasi
```
flutter run
```

## Fitur yang Telah Diimplementasikan

### Layar Verifikasi Dokumen
- Masukkan token verifikasi untuk memverifikasi dokumen yang dibagikan
- Tampilan informasi dokumen terverifikasi secara terperinci
- Format tanggal kedaluwarsa token yang mudah dibaca
- Tampilan visual dengan ikon yang sesuai untuk setiap jenis dokumen

### Integrasi Blockchain ICP
- Layanan ICPService untuk berinteraksi dengan canister ICP
- Autentikasi menggunakan Internet Identity
- Penyimpanan dan pengambilan dokumen terenkripsi
- Generasi dan verifikasi token dokumen

### Keamanan dan Enkripsi
- Enkripsi client-side sebelum menyimpan di blockchain
- Tidak ada data sensitif yang disimpan dalam bentuk plaintext
- Menggunakan agent-js untuk interaksi aman dengan ICP

## Fitur Keamanan

- Enkripsi end-to-end untuk semua dokumen tersimpan
- Penyimpanan kunci pribadi secara aman (diturunkan dari biometrik)
- Penyimpanan dokumen terdesentralisasi di node ICP
- Kontrol akses berbasis canister
- Autentikasi multi-faktor

## Pertimbangan Privasi

SecureMeID dirancang dengan prinsip privacy-first:
- Tidak ada penyimpanan terpusat untuk dokumen pengguna
- Pengumpulan data pribadi minimal
- Verifikasi kriptografis tanpa eksposur dokumen
- Pembagian data yang dikendalikan pengguna

## Pengembangan Selanjutnya

- Implementasi canister ICP untuk penyimpanan dan verifikasi dokumen
- Integrasi biometrik untuk keamanan tambahan
- Fitur pemulihan multi-signature
- Panel admin untuk verifikasi KYC oleh otoritas resmi

## Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT - lihat file LICENSE untuk detail. 