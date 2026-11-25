# FLOWCHART — SMART HOME IoT SYSTEM

**Project:** Smart Home IoT Monitoring System  
**Version:** 1.0  
**Microcontroller:** ESP32 DevKit V1  
**Firmware:** MicroPython  
**Mobile Application:** Flutter  
**Database:** SQLite  
**Communication:** Wi-Fi + HTTP API

---

## 1. FLOWCHART SISTEM UTAMA

Menggambarkan keseluruhan proses kerja Smart Home dari pembacaan sensor sampai data ditampilkan di aplikasi.

```mermaid
flowchart TD
    A([Start]) --> B[ESP32 Menyala]
    B --> C[Inisialisasi GPIO dan Sensor]
    C --> D[ESP32 Terhubung ke Wi-Fi]
    D --> E[Menjalankan HTTP Server]
    E --> F[Membaca Seluruh Sensor]

    F --> G[Memproses Data Sensor]
    G --> H[Menjalankan Otomatisasi]
    H --> I[Menyediakan Data melalui HTTP API]

    I --> J{Aplikasi Terhubung?}
    J -->|Ya| K[Flutter Mengambil Data]
    J -->|Tidak| L[Sistem Otomatisasi Tetap Berjalan]

    K --> M[Menampilkan Monitoring]
    M --> N[Menyimpan Riwayat ke SQLite]
    N --> O[Memperbarui Data]

    L --> F
    O --> F
```

## 2. FLOWCHART INISIALISASI ESP32

```mermaid
flowchart TD
    A([Start]) --> B[Menyalakan ESP32]
    B --> C[Import Library MicroPython]
    C --> D[Inisialisasi GPIO]
    D --> E[Inisialisasi DHT11]
    E --> F[Inisialisasi MQ-2]
    F --> G[Inisialisasi LDR]
    G --> H[Inisialisasi Rain Sensor]
    H --> I[Inisialisasi Ultrasonic 1 dan 2]
    I --> J[Inisialisasi Servo]
    J --> K[Inisialisasi LED dan Buzzer]
    K --> L[Hubungkan ke Wi-Fi]
    L --> M{Wi-Fi Terhubung?}
    M -->|Ya| N[Mulai HTTP Server]
    M -->|Tidak| O[Ulangi Koneksi]
    O --> L
    N --> P([Masuk ke Main Loop])
```

## 3. FLOWCHART RAIN SENSOR DAN SERVO

Fungsi: Ketika sensor hujan mendeteksi air, servo bergerak ke 90°. Ketika tidak ada air, servo kembali ke 0°.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi Rain Sensor]
    B --> C[Inisialisasi Servo]
    C --> D[Baca Sensor Hujan]
    D --> E{Air Terdeteksi?}
    E -->|Ya| F[Servo Bergerak ke 90 Derajat]
    E -->|Tidak| G[Servo Bergerak ke 0 Derajat]
    F --> H[Perbarui Status Servo]
    G --> H
    H --> I[Kirim Status ke Aplikasi]
    I --> D
```

## 4. FLOWCHART DHT11 DAN BUZZER

Fungsi: Membaca suhu dan kelembapan. Jika suhu melewati batas, buzzer akan aktif.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi DHT11]
    B --> C[Baca Suhu dan Kelembapan]
    C --> D{Suhu Melebihi Batas?}
    D -->|Ya| E[Status Suhu Tinggi]
    D -->|Tidak| F[Status Suhu Normal]
    E --> G[Kirim Status ke Sistem Alarm]
    F --> G
    G --> H[Perbarui Data Monitoring]
    H --> C
```

## 5. FLOWCHART MQ-2 DAN BUZZER

Fungsi: Membaca nilai gas/asap dari MQ-2.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi MQ-2]
    B --> C[Baca Nilai Gas]
    C --> D{Nilai Gas Melebihi Batas?}
    D -->|Ya| E[Status Gas Tinggi]
    D -->|Tidak| F[Status Gas Normal]
    E --> G[Kirim Status ke Sistem Alarm]
    F --> G
    G --> H[Perbarui Data Monitoring]
    H --> C
```

### Logika Gabungan Buzzer

Buzzer dikendalikan berdasarkan dua kondisi sekaligus.

```mermaid
flowchart TD
    A([Mulai Pemeriksaan Alarm]) --> B[Baca Status Suhu]
    B --> C[Baca Status Gas]
    C --> D{Suhu Tinggi ATAU Gas Tinggi?}
    D -->|Ya| E[Aktifkan Buzzer]
    D -->|Tidak| F[Matikan Buzzer]
    E --> G[Perbarui Status Buzzer]
    F --> G
    G --> A
```

Ketentuan:
- Suhu tinggi menyebabkan buzzer aktif.
- Gas tinggi menyebabkan buzzer aktif.
- Jika keduanya normal, buzzer mati.
- Buzzer tidak mati selama salah satu kondisi masih tinggi.

## 6. FLOWCHART ULTRASONIC 1 — DETEKSI TAMU

Fungsi: Mendeteksi keberadaan tamu di depan rumah dan mengirimkan notifikasi ke aplikasi.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi Ultrasonic 1]
    B --> C[Baca Jarak Objek]
    C --> D{Objek dalam Jarak Deteksi?}
    D -->|Ya| E[Status Ada Tamu]
    D -->|Tidak| F[Status Tidak Ada Tamu]
    E --> G{Tamu Baru Terdeteksi?}
    G -->|Ya| H[Buat Notifikasi Tamu]
    G -->|Tidak| I[Perbarui Status]
    H --> J[Kirim Data ke Aplikasi]
    F --> K[Reset Status Deteksi]
    I --> J
    K --> J
    J --> C
```

Contoh notifikasi:

"Ada tamu di depan rumah."

Notifikasi hanya dibuat ketika terjadi deteksi baru, bukan setiap kali sensor membaca objek yang sama.

## 7. FLOWCHART ULTRASONIC 2 — MONITORING KENDARAAN

Fungsi: Mendeteksi apakah mobil masih berada di area parkir.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi Ultrasonic 2]
    B --> C[Baca Jarak Kendaraan]
    C --> D{Kendaraan Terdeteksi?}
    D -->|Ya| E[Status Mobil Ada]
    D -->|Tidak| F[Status Mobil Tidak Ada]
    E --> G[Kirim Status ke Aplikasi]
    F --> G
    G --> H[Tampilkan Status Kendaraan]
    H --> C
```

## 8. FLOWCHART LDR DAN LED

Fungsi: Menghidupkan lampu secara otomatis ketika kondisi gelap.

```mermaid
flowchart TD
    A([Start]) --> B[Inisialisasi LDR]
    B --> C[Inisialisasi LED]
    C --> D[Baca Nilai Cahaya]
    D --> E{Kondisi Gelap?}
    E -->|Ya| F[Nyalakan LED]
    E -->|Tidak| G[Matikan LED]
    F --> H[Perbarui Status LED]
    G --> H
    H --> D
```

## 9. FLOWCHART KONEKSI APLIKASI DAN ESP32

Fungsi: Menghubungkan aplikasi Flutter dengan ESP32 melalui alamat IP.

```mermaid
flowchart TD
    A([Buka Aplikasi]) --> B[Halaman Beranda]
    B --> C[Ambil IP dari SQLite]
    C --> D{IP Tersimpan?}
    D -->|Ya| E[Tampilkan IP Tersimpan]
    D -->|Tidak| F[Input IP ESP32]
    E --> G[Klik Connect]
    F --> G
    G --> H[Kirim HTTP Request]
    H --> I{Koneksi Berhasil?}
    I -->|Ya| J[Status Online]
    I -->|Tidak| K[Status Offline]
    J --> L[Mulai Mengambil Data Sensor]
    K --> F
    L --> M[Halaman Monitoring]
```

## 10. FLOWCHART PENGAMBILAN DATA SENSOR

```mermaid
flowchart TD
    A([Mulai Polling]) --> B[HTTP Request ke ESP32]
    B --> C{Respons Diterima?}
    C -->|Tidak| D[Tampilkan Status Offline]
    D --> E[Tampilkan Waktu Data Terakhir]
    E --> F[Ulangi Request]
    C -->|Ya| G[Validasi Format JSON]
    G --> H{Data Valid?}
    H -->|Tidak| I[Tampilkan Data Tidak Tersedia]
    H -->|Ya| J[Parsing Data Sensor]
    J --> K[Update UI Monitoring]
    K --> L[Simpan Riwayat ke SQLite]
    L --> F
```

## 11. FLOWCHART DATABASE SQLITE

Fungsi: Menyimpan data monitoring dan riwayat notifikasi secara lokal.

```mermaid
flowchart TD
    A([Aplikasi Menerima Data]) --> B[Validasi Data]
    B --> C{Data Valid?}
    C -->|Tidak| D[Tidak Menyimpan Data]
    C -->|Ya| E[Proses Penyimpanan SQLite]
    E --> F{Jenis Data}
    F -->|Sensor| G[Insert sensor_logs]
    F -->|Aktuator| H[Insert device_logs]
    F -->|Tamu| I[Insert visitor_logs]
    F -->|Kendaraan| J[Insert vehicle_logs]
    F -->|Notifikasi| K[Insert notifications]
    G --> L[Data Tersimpan]
    H --> L
    I --> L
    J --> L
    K --> L
    L --> M([Selesai])
```

## 12. FLOWCHART NAVIGASI APLIKASI

Aplikasi hanya memiliki dua halaman utama.

```mermaid
flowchart TD
    A([Start Application]) --> B[Beranda]
    B --> C{Pilih Menu}
    C -->|Beranda| B
    C -->|Monitoring| D[Halaman Monitoring]
    D --> E{Pilih Menu}
    E -->|Monitoring| D
    E -->|Beranda| B
```

### Halaman Beranda
- Informasi umum Smart Home.
- Input IP ESP32.
- Tombol Connect dan Disconnect.
- Status koneksi.
- Ringkasan suhu.
- Ringkasan kelembapan.
- Ringkasan gas.
- Ringkasan cahaya.

### Halaman Monitoring
- Data seluruh sensor.
- Status servo.
- Status LED.
- Status buzzer.
- Deteksi tamu.
- Status kendaraan.
- Riwayat notifikasi.

## 13. FLOWCHART KESELURUHAN OTOMATISASI

```mermaid
flowchart TD
    A([ESP32 Main Loop]) --> B[Baca DHT11]
    B --> C[Baca MQ-2]
    C --> D[Baca LDR]
    D --> E[Baca Rain Sensor]
    E --> F[Baca Ultrasonic Tamu]
    F --> G[Baca Ultrasonic Kendaraan]

    G --> H[Evaluasi Suhu dan Gas]
    H --> I{Suhu atau Gas Tinggi?}
    I -->|Ya| J[Buzzer ON]
    I -->|Tidak| K[Buzzer OFF]

    J --> L[Evaluasi Hujan]
    K --> L

    L --> M{Hujan Terdeteksi?}
    M -->|Ya| N[Servo 90 Derajat]
    M -->|Tidak| O[Servo 0 Derajat]

    N --> P[Evaluasi Cahaya]
    O --> P

    P --> Q{Gelap?}
    Q -->|Ya| R[LED ON]
    Q -->|Tidak| S[LED OFF]

    R --> T[Update Data dan Status]
    S --> T

    T --> U[Sediakan Data melalui HTTP API]
    U --> V([Ulangi Main Loop])
    V --> A
```

---

## 14. CATATAN IMPLEMENTASI

1. Semua otomatisasi utama dijalankan langsung oleh ESP32.
2. Flutter bertugas menampilkan data dan riwayat monitoring.
3. SQLite digunakan sebagai database lokal aplikasi.
4. Koneksi aplikasi menggunakan IP ESP32 pada jaringan Wi-Fi yang sama.
5. Setiap sensor harus diuji secara terpisah sebelum digabungkan.
6. Ambang batas suhu, gas, jarak tamu, dan jarak kendaraan harus ditentukan berdasarkan pengujian.
7. Gunakan pembacaan sensor yang memiliki timeout agar satu sensor yang bermasalah tidak menghentikan seluruh sistem.
8. Data monitoring harus memiliki timestamp.
9. Status Offline harus ditampilkan jika komunikasi gagal.
10. Sistem otomatisasi tetap berjalan meskipun aplikasi mobile ditutup.

---

**END OF DOCUMENT**

Project: Smart Home IoT Monitoring System  
Document: flowchart.md  
Version: 1.0