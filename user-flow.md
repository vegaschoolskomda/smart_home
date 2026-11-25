# USER FLOW — SMART HOME APPLICATION

**Project:** Smart Home IoT Monitoring System  
**Version:** 1.0  
**Platform:** Android Mobile Application  
**Framework:** Flutter  
**Database:** SQLite  
**Communication:** Wi-Fi + HTTP API

---

## 1. OVERVIEW

User Flow ini menjelaskan alur interaksi pengguna ketika menggunakan aplikasi Smart Home.

Aplikasi memiliki dua halaman utama:
1. Beranda
2. Monitoring

Pengguna harus menghubungkan aplikasi dengan ESP32 menggunakan alamat IP sebelum dapat melihat data monitoring secara langsung.

## 2. MAIN APPLICATION FLOW

```mermaid
flowchart TD
    A([Buka Aplikasi]) --> B[Halaman Beranda]
    B --> C{IP ESP32 Tersimpan?}
    C -->|Ya| D[Isi IP Otomatis]
    C -->|Tidak| E[Masukkan IP ESP32]
    D --> F[Klik Connect]
    E --> F
    F --> G{Koneksi Berhasil?}
    G -->|Ya| H[Status Online]
    G -->|Tidak| I[Tampilkan Pesan Gagal]
    I --> E
    H --> J[Ambil Data ESP32]
    J --> K[Simpan Riwayat ke SQLite]
    K --> L{Pilih Halaman}
    L -->|Beranda| B
    L -->|Monitoring| M[Halaman Monitoring]
    M --> J
```

## 3. USER FLOW — BERANDA

Beranda merupakan halaman pertama yang dibuka pengguna.

### Alur Pengguna

1. Pengguna membuka aplikasi.
2. Aplikasi menampilkan halaman Beranda.
3. Aplikasi memeriksa IP ESP32 yang tersimpan di SQLite.
4. Jika IP tersedia, input IP diisi otomatis.
5. Jika IP belum tersedia, pengguna memasukkan IP secara manual.
6. Pengguna menekan tombol Connect.
7. Aplikasi mengirim HTTP request ke ESP32.
8. Aplikasi memeriksa hasil koneksi.

### Kondisi Koneksi

**Jika berhasil:**
- Status koneksi berubah menjadi Online.
- Aplikasi mulai mengambil data sensor.
- IP disimpan ke SQLite.
- Ringkasan monitoring ditampilkan.

**Jika gagal:**
- Status koneksi berubah menjadi Offline.
- Aplikasi menampilkan pesan koneksi gagal.
- Pengguna dapat mencoba menghubungkan kembali.

### Beranda — Informasi yang Ditampilkan

- Status koneksi ESP32.
- Input IP ESP32.
- Tombol Connect dan Disconnect.
- Suhu DHT11.
- Kelembapan DHT11.
- Nilai gas MQ-2.
- Kondisi cahaya LDR.
- Ringkasan kondisi rumah.
- Navigasi ke Monitoring.

## 4. USER FLOW — MONITORING

Halaman Monitoring digunakan untuk melihat seluruh informasi sensor dan aktuator.

### Alur Pengguna

1. Pengguna memilih menu Monitoring.
2. Aplikasi memeriksa status koneksi ESP32.
3. Jika Online, aplikasi mengambil data sensor.
4. Data ditampilkan berdasarkan kategori.
5. Data monitoring disimpan ke SQLite.
6. Aplikasi memperbarui data secara berkala.

Jika Offline:
- Tampilkan indikator Offline.
- Tampilkan informasi waktu pembaruan terakhir.
- Jangan menganggap data lama sebagai data terbaru.
- Pengguna dapat kembali ke Beranda untuk memperbaiki koneksi.

### Monitoring Categories

**A. Environmental Monitoring**
- Suhu.
- Kelembapan.
- Nilai gas.
- Intensitas cahaya.

**B. Security Monitoring**
- Deteksi tamu.
- Jarak tamu.
- Status kendaraan.
- Jarak kendaraan.

**C. Automatic Control**
- Status hujan.
- Posisi servo.
- Status LED.
- Status buzzer.

**D. Notification History**
- Notifikasi tamu.
- Peringatan suhu tinggi.
- Peringatan gas tinggi.
- Waktu notifikasi.
- Status sudah dibaca atau belum.

## 5. USER FLOW — VISITOR DETECTION

Fitur ini menggunakan Ultrasonic 1.

```mermaid
flowchart TD
    A([ESP32 Membaca Ultrasonic 1]) --> B{Objek Terdeteksi?}
    B -->|Tidak| C[Status Tidak Ada Tamu]
    B -->|Ya| D[Status Ada Tamu]
    D --> E[Periksa Cooldown]
    E --> F{Boleh Kirim Notifikasi?}
    F -->|Ya| G[Buat Notifikasi]
    F -->|Tidak| H[Tidak Mengirim Ulang]
    G --> I[Simpan ke SQLite]
    I --> J[Tampilkan Notifikasi]
    C --> A
    H --> A
    J --> A
```

### Hasil yang Diharapkan

Ketika tamu terdeteksi:
- Aplikasi menerima informasi deteksi.
- Notifikasi ditampilkan.
- Riwayat notifikasi disimpan.

Contoh notifikasi:

**Ada tamu di depan rumah.**

Notifikasi tidak dikirim berulang kali selama orang masih berada di area deteksi.

## 6. USER FLOW — VEHICLE MONITORING

Fitur ini menggunakan Ultrasonic 2.

```mermaid
flowchart TD
    A([ESP32 Membaca Ultrasonic 2]) --> B{Kendaraan Terdeteksi?}
    B -->|Ya| C[Status Mobil Ada]
    B -->|Tidak| D[Status Mobil Tidak Ada]
    C --> E[Kirim Status ke Aplikasi]
    D --> E
    E --> F[Tampilkan Status]
    F --> G[Simpan Riwayat SQLite]
    G --> A
```

### Status Aplikasi

| Kondisi | Status |
|---|---|
| Kendaraan terdeteksi | Mobil Ada |
| Kendaraan tidak terdeteksi | Mobil Tidak Ada |

Status diperbarui secara otomatis berdasarkan pembacaan sensor.

## 7. USER FLOW — RAIN SENSOR & SERVO

Fitur otomatisasi hujan berjalan langsung pada ESP32.

```mermaid
flowchart TD
    A([Sensor Hujan Membaca Kondisi]) --> B{Air Terdeteksi?}
    B -->|Ya| C[Servo Bergerak 90 Derajat]
    B -->|Tidak| D[Servo Bergerak 0 Derajat]
    C --> E[Kirim Status ke Aplikasi]
    D --> E
    E --> F[Tampilkan Status Hujan dan Servo]
    F --> A
```

### Kondisi

| Kondisi | Servo |
|---|---|
| Hujan terdeteksi | 90° |
| Tidak ada hujan | 0° |

Aplikasi hanya menampilkan status otomatisasi tersebut.

## 8. USER FLOW — TEMPERATURE & GAS ALERT

Fitur ini menggunakan DHT11, MQ-2, dan buzzer.

```mermaid
flowchart TD
    A([ESP32 Membaca Sensor]) --> B[Periksa Suhu DHT11]
    B --> C[Periksa Nilai Gas MQ-2]
    C --> D{Suhu Tinggi atau Gas Tinggi?}
    D -->|Ya| E[Aktifkan Buzzer]
    D -->|Tidak| F[Matikan Buzzer]
    E --> G[Kirim Status ke Aplikasi]
    F --> G
    G --> H[Tampilkan Status Sensor]
    H --> A
```

### Ketentuan

- Suhu melewati ambang batas: buzzer aktif.
- Gas melewati ambang batas: buzzer aktif.
- Salah satu kondisi masih tinggi: buzzer tetap aktif.
- Kedua kondisi normal: buzzer mati.

Nilai ambang batas ditentukan melalui pengujian sensor.

## 9. USER FLOW — LDR & LED

Fitur otomatisasi pencahayaan berjalan langsung di ESP32.

```mermaid
flowchart TD
    A([LDR Membaca Intensitas Cahaya]) --> B{Kondisi Gelap?}
    B -->|Ya| C[LED Menyala]
    B -->|Tidak| D[LED Mati]
    C --> E[Kirim Status ke Aplikasi]
    D --> E
    E --> F[Tampilkan Kondisi Cahaya dan LED]
    F --> A
```

| Kondisi | LED |
|---|---|
| Gelap | ON |
| Terang | OFF |

## 10. USER FLOW — SQLITE DATABASE

SQLite digunakan sebagai database lokal aplikasi.

### Data yang Disimpan

| Aktivitas | Penyimpanan |
|---|---|
| IP ESP32 | connection_settings |
| Pembacaan sensor | sensor_logs |
| Status aktuator | device_logs |
| Deteksi tamu | visitor_logs |
| Status kendaraan | vehicle_logs |
| Notifikasi | notifications |

### Database Flow

```mermaid
flowchart TD
    A([Aplikasi Menerima Data ESP32]) --> B[Validasi Data]
    B --> C{Data Valid?}
    C -->|Tidak| D[Tampilkan Error]
    C -->|Ya| E[Tampilkan Data Monitoring]
    E --> F[Simpan ke SQLite]
    F --> G[Data Tersimpan]
    G --> H[Dapat Dibaca Kembali]
```

Database tetap menyimpan riwayat lokal meskipun aplikasi ditutup.

## 11. ERROR HANDLING FLOW

### A. ESP32 Tidak Terhubung

- Pengguna memasukkan IP.
- Aplikasi mencoba koneksi.
- Request mengalami kegagalan.
- Status menjadi Offline.
- Aplikasi menampilkan pesan kesalahan.
- Pengguna dapat mencoba kembali.

### B. Data Sensor Tidak Tersedia

- Aplikasi menerima respons tidak lengkap.
- Parameter yang tidak tersedia ditandai sebagai Unavailable.
- Data lama tidak dianggap sebagai pembacaan terbaru.
- Sistem tetap menampilkan parameter lain yang berhasil diterima.

### C. Koneksi Terputus

- Aplikasi mendeteksi request gagal.
- Status berubah menjadi Offline.
- Waktu pembaruan terakhir ditampilkan.
- Aplikasi mencoba menghubungkan kembali sesuai mekanisme retry.

## 12. APPLICATION NAVIGATION

```mermaid
flowchart TD
    A([Application]) --> B[Beranda]
    B --> C[Monitoring]
    C --> B
```

Tidak ada halaman utama tambahan.

Pengguna hanya dapat berpindah antara:
- Beranda
- Monitoring

## 13. FINAL USER JOURNEY

Alur utama penggunaan aplikasi:

1. Pengguna membuka aplikasi.
2. Pengguna memasukkan IP ESP32.
3. Aplikasi berhasil terhubung.
4. Pengguna melihat ringkasan kondisi rumah di Beranda.
5. Pengguna membuka Monitoring.
6. Pengguna memantau seluruh sensor dan aktuator.
7. Aplikasi menerima pembaruan data secara berkala.
8. Riwayat monitoring dan notifikasi tersimpan di SQLite.
9. Sistem otomatisasi tetap berjalan pada ESP32 tanpa harus membuka aplikasi.

---

**END OF DOCUMENT**

Project: Smart Home IoT Monitoring System  
Document: userflow.md  
Version: 1.0