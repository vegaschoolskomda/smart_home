# PRD — SMART HOME MOBILE APPLICATION

**Versi:** 1.0  
**Platform:** Android Mobile Application  
**Framework:** Flutter  
**Language:** Dart  
**Database:** SQLite  
**Communication:** Wi-Fi + HTTP API  
**Microcontroller:** ESP32 DevKit V1

## 1. Project Overview

Smart Home adalah aplikasi mobile untuk memantau kondisi rumah dan mengontrol sistem otomatisasi berbasis ESP32.

Aplikasi menerima data sensor melalui jaringan Wi-Fi lokal dengan memasukkan alamat IP ESP32. Data monitoring disimpan secara lokal menggunakan SQLite.

Aplikasi hanya memiliki dua halaman utama:
1. Beranda
2. Monitoring

Prioritas pengembangan adalah kemudahan penggunaan, tampilan yang bersih, dan data sensor yang benar-benar berasal dari ESP32.

## 2. Design Direction

Buat desain aplikasi dengan pendekatan modern minimalis seperti aplikasi smart home profesional.

### Visual Style
- Minimalis dan fungsional.
- Layout rapi dengan jarak antar-elemen yang konsisten.
- Tidak menggunakan terlalu banyak card.
- Hindari shadow berlebihan.
- Hindari gradient yang tidak diperlukan.
- Jangan menggunakan terlalu banyak warna aksen.
- Jangan menggunakan emoji sebagai ikon.
- Gunakan Material Symbols atau Lucide Icons.
- Hindari teks penjelasan panjang pada dashboard.
- Gunakan tipografi yang mudah dibaca.
- Prioritaskan informasi sensor daripada dekorasi.

### Color Palette

| Elemen | Warna |
|---|---|
| Background | #F5F6F4 |
| Surface | #FFFFFF |
| Primary | #245C48 |
| Text Primary | #202823 |
| Text Secondary | #78817B |
| Success | #2D8A59 |
| Warning | #D99A32 |
| Danger | #D64C4C |
| Border | #E5E9E5 |

Gunakan warna secara konsisten dan jangan membuat seluruh komponen terlihat penuh warna.

### Typography
- Gunakan Inter atau font sans-serif modern.
- Judul halaman berukuran sedang.
- Angka sensor dapat dibuat lebih menonjol.
- Label dan deskripsi cukup menggunakan ukuran kecil.
- Hindari penggunaan bold pada hampir semua teks.

## 3. Application Navigation

Aplikasi hanya memiliki dua halaman utama dengan bottom navigation.

| Menu | Fungsi |
|---|---|
| Beranda | Ringkasan kondisi rumah dan koneksi ESP32 |
| Monitoring | Monitoring seluruh sensor dan aktuator |

Ketentuan:
- Bottom navigation selalu tersedia.
- Gunakan ikon sederhana dengan label.
- Jangan menambahkan halaman Settings, Profile, atau halaman utama lainnya.
- Konfigurasi IP dapat dilakukan langsung dari Beranda.

## 4. Page 1 — Beranda

Beranda merupakan halaman pertama ketika aplikasi dibuka.

### A. Header

Tampilkan:
- Nama aplikasi: Smart Home.
- Sapaan singkat atau judul seperti "Ringkasan Rumah".
- Status koneksi ESP32.

Contoh:

Smart Home

Ringkasan Rumah

Status: Online

### B. ESP32 Connection

Bagian ini merupakan fitur utama pada Beranda.

Komponen:
- Input alamat IP ESP32.
- Tombol Connect.
- Tombol Disconnect.
- Indikator status koneksi.

Contoh input:

`192.168.1.10`

Perilaku:
1. Pengguna memasukkan alamat IP ESP32.
2. Pengguna menekan Connect.
3. Aplikasi melakukan HTTP request ke ESP32.
4. Jika berhasil, tampilkan status Online.
5. Jika gagal, tampilkan pesan koneksi gagal.
6. Simpan alamat IP terakhir ke SQLite.
7. Saat aplikasi dibuka kembali, IP terakhir dapat dimuat otomatis.

ESP32 dan smartphone harus berada pada jaringan Wi-Fi yang sama.

### C. Ringkasan Monitoring

Tampilkan tiga informasi utama:

1. Suhu dan kelembapan dari DHT11.
2. Nilai gas dari MQ-2.
3. Kondisi cahaya dari LDR.

Gunakan layout sederhana dan tidak perlu membuat banyak card besar.

Contoh:

| Parameter | Nilai |
|---|---|
| Suhu | 29.5 °C |
| Kelembapan | 70% |
| Gas | 1200 |
| Cahaya | Terang |

Angka tersebut hanya contoh tampilan. Aplikasi harus menggunakan data aktual dari ESP32.

### D. Quick Status

Tampilkan ringkasan singkat:
- Status hujan.
- Status kendaraan.
- Status tamu.
- Status perangkat.

Sediakan tombol atau navigasi menuju halaman Monitoring.

## 5. Page 2 — Monitoring

Halaman Monitoring menampilkan seluruh sensor dan aktuator secara terstruktur.

Jangan menampilkan semua informasi dalam satu card besar. Pisahkan berdasarkan kategori.

### A. Environmental Monitoring

Menampilkan:
- DHT11: suhu.
- DHT11: kelembapan.
- MQ-2: nilai gas.
- LDR: intensitas cahaya.

Setiap parameter memiliki:
- Nama sensor.
- Nilai aktual.
- Satuan jika tersedia.
- Status kondisi.

### B. Security Monitoring

Menampilkan dua ultrasonic.

Ultrasonic 1 — Deteksi Tamu:
- Jarak objek.
- Status: Ada Tamu / Tidak Ada Tamu.
- Waktu deteksi terakhir.

Ultrasonic 2 — Monitoring Kendaraan:
- Jarak kendaraan.
- Status: Mobil Ada / Mobil Tidak Ada.

Jika tamu terdeteksi, aplikasi membuat notifikasi:

"Ada tamu di depan rumah."

Gunakan mekanisme cooldown agar notifikasi tidak muncul berulang kali selama objek masih berada di depan sensor.

### C. Automatic Control

Menampilkan status perangkat otomatisasi.

| Perangkat | Informasi |
|---|---|
| Rain Sensor | Hujan / Tidak Hujan |
| Servo | Posisi 0° / 90° |
| LED | ON / OFF |
| Buzzer | Aktif / Tidak Aktif |

Semua status harus berasal dari ESP32, bukan nilai statis.

### D. Notification History

Tampilkan daftar notifikasi yang tersimpan di SQLite.

Contoh:
- Ada tamu di depan rumah.
- Suhu melewati batas.
- Nilai gas melewati batas.

Setiap notifikasi memiliki:
- Judul.
- Pesan.
- Waktu.
- Status sudah dibaca atau belum.

Notifikasi tamu berasal dari deteksi ultrasonic. Notifikasi suhu dan gas berasal dari kondisi sensor.

## 6. SQLite Database

Gunakan SQLite sebagai database lokal aplikasi.

Disarankan menggunakan package `sqflite`.

Buat database dengan nama:

`smarthome.db`

### Table 1 — connection_settings

Menyimpan konfigurasi koneksi ESP32.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| esp32_ip | TEXT |
| updated_at | TEXT |

### Table 2 — sensor_logs

Menyimpan riwayat pembacaan sensor.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT |
| temperature | REAL |
| humidity | REAL |
| gas_value | INTEGER |
| ldr_value | INTEGER |
| rain_status | INTEGER |
| created_at | TEXT |

### Table 3 — device_logs

Menyimpan riwayat status aktuator.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT |
| servo_angle | INTEGER |
| led_status | INTEGER |
| buzzer_status | INTEGER |
| created_at | TEXT |

### Table 4 — visitor_logs

Menyimpan riwayat deteksi tamu.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT |
| distance | REAL |
| detected | INTEGER |
| detected_at | TEXT |

### Table 5 — vehicle_logs

Menyimpan riwayat keberadaan kendaraan.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT |
| distance | REAL |
| vehicle_status | TEXT |
| detected_at | TEXT |

### Table 6 — notifications

Menyimpan riwayat notifikasi.

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY AUTOINCREMENT |
| title | TEXT |
| message | TEXT |
| type | TEXT |
| is_read | INTEGER DEFAULT 0 |
| created_at | TEXT |

### Database Requirements

- Database dibuat otomatis ketika aplikasi pertama kali dibuka.
- Gunakan foreign key jika dibutuhkan.
- Gunakan timestamp untuk riwayat data.
- Simpan IP ESP32 agar tidak perlu memasukkannya berulang kali.
- Data monitoring disimpan secara berkala.
- Sediakan pembatasan jumlah riwayat agar database tidak terus membesar.
- Gunakan parameterized queries untuk operasi database.
- Jangan menghapus seluruh riwayat ketika aplikasi ditutup.

## 7. ESP32 API Integration

Aplikasi berkomunikasi dengan ESP32 menggunakan HTTP API.

Endpoint yang direncanakan:

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | /api/status | Memeriksa koneksi |
| GET | /api/sensors | Mengambil data sensor |
| GET | /api/devices | Mengambil status aktuator |
| GET | /api/notifications | Mengambil informasi notifikasi |

Contoh respons JSON:

```json
{
  "temperature": 29.5,
  "humidity": 70,
  "gas_value": 1200,
  "ldr_value": 2500,
  "rain_status": false,
  "visitor_detected": true,
  "visitor_distance": 45,
  "vehicle_status": "Ada",
  "vehicle_distance": 80,
  "servo_angle": 0,
  "led_status": false,
  "buzzer_status": false
}
```

Data tersebut hanya contoh struktur API.

### Connection Behavior

- Polling data dilakukan setiap 1–2 detik atau sesuai kemampuan ESP32.
- Tampilkan waktu pembaruan terakhir.
- Jika request gagal, tampilkan status Offline.
- Jangan mengubah data terakhir menjadi nol ketika koneksi terputus.
- Berikan indikator bahwa data yang ditampilkan merupakan data terakhir yang berhasil diterima.

## 8. Flutter Project Architecture

Gunakan struktur folder yang rapi dan mudah dikembangkan.

```text
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│
├── data/
│   ├── models/
│   ├── database/
│   │   └── app_database.dart
│   └── services/
│       ├── esp32_service.dart
│       └── notification_service.dart
│
├── features/
│   ├── home/
│   │   ├── pages/
│   │   │   └── home_page.dart
│   │   └── widgets/
│   │
│   └── monitoring/
│       ├── pages/
│       │   └── monitoring_page.dart
│       └── widgets/
│
└── navigation/
    └── bottom_navigation.dart
```

## 9. Recommended Dependencies

Gunakan package berikut:

- `sqflite` — SQLite database.
- `path` — Database path.
- `http` — HTTP communication dengan ESP32.
- `intl` — Format tanggal dan waktu.
- `flutter_local_notifications` — Notifikasi lokal.
- `shared_preferences` — Opsional untuk preferensi sederhana jika diperlukan.

Hindari menambahkan dependency yang tidak dibutuhkan.

## 10. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | Pengguna dapat memasukkan IP ESP32. |
| FR-02 | Pengguna dapat menghubungkan dan memutus koneksi. |
| FR-03 | Aplikasi menyimpan IP terakhir menggunakan SQLite. |
| FR-04 | Aplikasi menampilkan suhu dan kelembapan. |
| FR-05 | Aplikasi menampilkan nilai gas. |
| FR-06 | Aplikasi menampilkan kondisi cahaya. |
| FR-07 | Aplikasi menampilkan status hujan dan servo. |
| FR-08 | Aplikasi menampilkan deteksi tamu. |
| FR-09 | Aplikasi menampilkan status kendaraan. |
| FR-10 | Aplikasi menampilkan status LED dan buzzer. |
| FR-11 | Aplikasi menyimpan riwayat sensor. |
| FR-12 | Aplikasi menyimpan riwayat notifikasi. |
| FR-13 | Aplikasi menampilkan status Online/Offline. |

## 11. UI/UX Restrictions

Hal-hal yang wajib diperhatikan saat implementasi:

- Jangan membuat desain yang terlalu ramai.
- Jangan menggunakan terlalu banyak shadow.
- Jangan menggunakan emoji sebagai pengganti ikon.
- Jangan membuat semua teks menjadi bold.
- Jangan membuat banyak gradient.
- Jangan membuat card bertumpuk tanpa kebutuhan.
- Jangan menambahkan halaman yang tidak diminta.
- Jangan menambahkan fitur AI atau chatbot.
- Jangan membuat data sensor palsu.
- Jangan membuat tombol yang tidak memiliki fungsi.

Utamakan tampilan yang terasa seperti produk aplikasi sungguhan, bukan hasil template dashboard otomatis.

## 12. Development Priority

Urutan pengerjaan:

1. Setup proyek Flutter.
2. Implementasi SQLite dan pembuatan seluruh tabel.
3. Implementasi halaman Beranda.
4. Implementasi input IP ESP32.
5. Implementasi koneksi HTTP.
6. Implementasi halaman Monitoring.
7. Integrasi seluruh data sensor.
8. Penyimpanan riwayat ke SQLite.
9. Implementasi notifikasi lokal.
10. Testing koneksi dan seluruh fitur.

## 13. Acceptance Criteria

Aplikasi dinyatakan berhasil apabila:

- Hanya memiliki dua halaman utama.
- Pengguna dapat memasukkan IP ESP32.
- Aplikasi dapat terhubung ke ESP32 melalui Wi-Fi.
- Seluruh data monitoring berasal dari sensor aktual.
- Status aktuator ditampilkan sesuai kondisi ESP32.
- Riwayat monitoring tersimpan di SQLite.
- Notifikasi tamu dapat ditampilkan.
- Aplikasi dapat menangani kondisi ESP32 Offline.
- Desain minimalis, mudah digunakan, dan responsif.

---

**Project Name:** Smart Home  
**Document:** Application PRD  
**Version:** 1.0  
**Database:** SQLite  
**Framework:** Flutter