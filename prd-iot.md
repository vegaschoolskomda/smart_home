# PRODUCT REQUIREMENTS DOCUMENT (PRD)
# SMART HOME IoT MONITORING SYSTEM

**Versi:** 1.0  
**Platform:** Mobile Application  
**Mikrokontroler:** ESP32 DevKit V1  
**Firmware:** MicroPython  
**IDE:** Thonny  
**Database:** SQLite  
**Komunikasi:** Wi-Fi + HTTP API

---

## 1. PROJECT OVERVIEW

Smart Home IoT Monitoring System merupakan aplikasi mobile berbasis Internet of Things (IoT) yang digunakan untuk memantau kondisi rumah dan menjalankan otomatisasi perangkat elektronik menggunakan ESP32.

Sistem mengintegrasikan berbagai sensor untuk mendeteksi kondisi lingkungan, keberadaan tamu, kendaraan, serta kondisi hujan. Seluruh data sensor dikirimkan oleh ESP32 ke aplikasi mobile melalui jaringan Wi-Fi.

Pengguna harus memasukkan alamat IP ESP32 terlebih dahulu sebelum aplikasi dapat terhubung dan menerima data monitoring.

### Tujuan Proyek
- Memantau kondisi rumah secara real-time.
- Mendeteksi keberadaan tamu di depan rumah.
- Memantau keberadaan kendaraan di area parkir.
- Mengotomatisasi servo berdasarkan sensor hujan.
- Mengotomatisasi lampu berdasarkan intensitas cahaya.
- Memberikan peringatan suara ketika suhu atau gas melewati batas tertentu.

---

## 2. HARDWARE COMPONENTS

| No. | Komponen | Jumlah | GPIO |
|---|---|---:|---|
| 1 | ESP32 DevKit V1 | 1 | Main Controller |
| 2 | Buzzer | 1 | GPIO27 |
| 3 | DHT11 | 1 | GPIO4 |
| 4 | MQ-2 Gas Sensor | 1 | GPIO32 |
| 5 | LDR 3 Pin Module | 1 | GPIO35 |
| 6 | Servo Motor | 1 | GPIO13 |
| 7 | HC-SR04 Ultrasonic | 1 | TRIG 21, ECHO 22 |
| 8 | HC-SR04 Ultrasonic | 1 | TRIG 18, ECHO 19 |
| 9 | Rain Sensor | 1 | GPIO34 |
| 10 | LED | 1 | GPIO25 |

### GPIO Configuration

- Buzzer: GPIO27
- DHT11: GPIO4
- MQ-2: GPIO32
- LDR: GPIO35
- Servo: GPIO13
- Ultrasonic Visitor: TRIG GPIO21, ECHO GPIO22
- Ultrasonic Vehicle: TRIG GPIO18, ECHO GPIO19
- Rain Sensor: GPIO34
- LED: GPIO25

**Hardware Safety Notes:**
- GPIO34 dan GPIO35 merupakan pin input-only.
- Output sensor ke ESP32 tidak boleh melebihi 3.3V.
- Pin ECHO HC-SR04 membutuhkan voltage divider.
- Servo dan MQ-2 membutuhkan suplai daya yang sesuai, bukan langsung dari pin 3.3V ESP32.
- Semua ground perangkat harus terhubung bersama.
- Buzzer harus disesuaikan dengan jenis dan kebutuhan arusnya.

---

## 3. SYSTEM AUTOMATION

### 3.1 Rain Sensor + Servo Motor

Fungsi: Mengotomatisasi gerakan servo ketika sensor mendeteksi air hujan.

| Kondisi | Aksi |
|---|---|
| Hujan terdeteksi | Servo bergerak ke 90 derajat |
| Tidak ada hujan | Servo kembali ke 0 derajat |

Ketentuan:
- Servo hanya bergerak ketika status hujan berubah.
- Posisi servo ditampilkan pada aplikasi.
- Sudut awal servo adalah 0 derajat.

### 3.2 DHT11 + Buzzer

Fungsi: Memantau suhu dan kelembapan lingkungan.

Ketentuan:
- DHT11 membaca suhu dan kelembapan secara berkala.
- Jika suhu melewati batas yang ditentukan, buzzer aktif.
- Jika suhu kembali normal, buzzer berhenti.
- Nilai suhu dan kelembapan ditampilkan pada aplikasi.

### 3.3 MQ-2 Gas Sensor + Buzzer

Fungsi: Mendeteksi peningkatan nilai gas/asap.

Ketentuan:
- MQ-2 membaca nilai analog secara berkala.
- Jika nilai melewati ambang batas, buzzer aktif.
- Jika nilai kembali normal, alarm berhenti.
- Nilai gas ditampilkan pada aplikasi.

**Prioritas alarm:** Buzzer tetap aktif selama suhu atau gas masih berada dalam kondisi peringatan. Buzzer baru berhenti ketika kedua kondisi kembali normal.

Ambang batas suhu dan gas harus dapat dikonfigurasi.

### 3.4 Ultrasonic 1 — Visitor Detection

Fungsi: Mendeteksi keberadaan tamu di depan rumah.

Ketentuan:
- Sensor membaca jarak objek.
- Jika objek terdeteksi dalam jarak yang ditentukan, sistem mencatat adanya tamu.
- Aplikasi menampilkan notifikasi: "Ada tamu di depan rumah".
- Sistem menggunakan cooldown agar notifikasi tidak dikirim berulang kali selama objek masih terdeteksi.
- Notifikasi baru dapat dikirim kembali setelah area dinyatakan kosong dan ada deteksi baru.

### 3.5 Ultrasonic 2 — Vehicle Monitoring

Fungsi: Memantau keberadaan kendaraan di area parkir.

| Kondisi | Status Aplikasi |
|---|---|
| Kendaraan terdeteksi | Mobil Ada |
| Kendaraan tidak terdeteksi | Mobil Tidak Ada |

Ketentuan:
- Sensor membaca jarak kendaraan.
- Status diperbarui secara otomatis.
- Status kendaraan ditampilkan pada halaman Monitoring.
- Sistem hanya mendeteksi keberadaan kendaraan, bukan menentukan apakah kendaraan dicuri.

### 3.6 LDR + LED

Fungsi: Mengotomatisasi lampu berdasarkan intensitas cahaya.

| Kondisi | LED |
|---|---|
| Siang / Terang | Mati |
| Malam / Gelap | Menyala |

Ketentuan:
- LDR membaca intensitas cahaya.
- Sistem menggunakan ambang batas terang dan gelap.
- LED otomatis menyala ketika kondisi gelap.
- LED otomatis mati ketika kondisi terang.

---

## 4. MOBILE APPLICATION STRUCTURE

Aplikasi hanya memiliki **2 halaman utama**.

### 4.1 Beranda

Fungsi: Menampilkan informasi umum dan status singkat sistem Smart Home.

Komponen halaman:
- Logo dan nama Smart Home.
- Deskripsi singkat proyek.
- Status koneksi ESP32.
- Input alamat IP ESP32.
- Tombol Connect.
- Tombol Disconnect.
- Ringkasan suhu dan kelembapan.
- Ringkasan nilai gas.
- Ringkasan status rumah.
- Navigasi menuju halaman Monitoring.

#### IP Connection

Contoh alamat IP:
`192.168.1.10`

Alur:
1. Pengguna membuka aplikasi.
2. Pengguna memasukkan IP ESP32.
3. Pengguna menekan tombol Connect.
4. Aplikasi mengirim permintaan koneksi.
5. Jika berhasil, status berubah menjadi Online.
6. Jika gagal, aplikasi menampilkan pesan koneksi gagal.

### 4.2 Monitoring

Fungsi: Menampilkan seluruh data sensor dan status aktuator.

Informasi yang ditampilkan:

| Perangkat | Informasi |
|---|---|
| DHT11 | Suhu dan kelembapan |
| MQ-2 | Nilai gas dan status |
| LDR | Kondisi terang/gelap |
| Rain Sensor | Hujan / Tidak Hujan |
| Servo | Posisi 0° / 90° |
| Ultrasonic Tamu | Jarak dan status deteksi |
| Ultrasonic Mobil | Jarak dan status kendaraan |
| LED | Menyala / Mati |
| Buzzer | Aktif / Tidak Aktif |

Fitur tambahan:
- Indikator Online / Offline.
- Waktu pembaruan data terakhir.
- Notifikasi ketika tamu terdeteksi.
- Riwayat monitoring.
- Status setiap perangkat.

### Navigation

Bottom Navigation hanya memiliki:
1. Beranda
2. Monitoring

Tidak diperbolehkan menambahkan halaman utama lain di luar dua halaman tersebut.

---

## 5. SYSTEM ARCHITECTURE

### Communication Flow

```text
MOBILE APPLICATION
       |
       | Input ESP32 IP
       |
       v
   WIFI NETWORK
       |
       v
   ESP32 WEB SERVER
       |
       | MicroPython
       |
       v
   SENSOR PROCESSING
       |
       +---- DHT11
       +---- MQ-2
       +---- LDR
       +---- Rain Sensor
       +---- Ultrasonic 1
       +---- Ultrasonic 2
       |
       v
   AUTOMATION SYSTEM
       |
       +---- Servo
       +---- LED
       +---- Buzzer
       |
       v
   HTTP API RESPONSE
       |
       v
   MOBILE APPLICATION
       |
       v
      SQLITE
```

### Connection Requirements

- ESP32 dan smartphone harus terhubung ke jaringan Wi-Fi yang sama.
- ESP32 menjalankan HTTP server menggunakan MicroPython.
- Aplikasi mengakses alamat IP ESP32.
- Data sensor dikirim dalam format JSON.
- Aplikasi melakukan pembaruan data secara berkala.
- Jika koneksi terputus, aplikasi menampilkan status Offline.
- Data lama tidak boleh ditampilkan seolah-olah merupakan data terbaru.

---

## 6. DATABASE DESIGN — SQLITE

SQLite digunakan untuk menyimpan konfigurasi koneksi, riwayat sensor, status perangkat, dan notifikasi.

### Table: connection_settings

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| esp32_ip | TEXT |
| connection_status | TEXT |
| updated_at | DATETIME |

### Table: sensor_logs

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| temperature | REAL |
| humidity | REAL |
| gas_value | INTEGER |
| ldr_value | INTEGER |
| rain_status | TEXT |
| created_at | DATETIME |

### Table: device_status

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| servo_angle | INTEGER |
| led_status | TEXT |
| buzzer_status | TEXT |
| created_at | DATETIME |

### Table: visitor_logs

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| distance | REAL |
| detected | INTEGER |
| detected_at | DATETIME |

### Table: vehicle_logs

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| distance | REAL |
| vehicle_status | TEXT |
| detected_at | DATETIME |

### Table: notifications

| Field | Type |
|---|---|
| id | INTEGER PRIMARY KEY |
| title | TEXT |
| message | TEXT |
| type | TEXT |
| is_read | INTEGER |
| created_at | DATETIME |

SQLite berada di aplikasi mobile dan digunakan untuk menyimpan riwayat lokal. ESP32 tetap bertugas membaca sensor dan menjalankan otomatisasi.

---

## 7. API REQUIREMENTS

ESP32 menyediakan HTTP API untuk komunikasi dengan aplikasi.

Contoh endpoint yang direncanakan:

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/api/status` | Status koneksi ESP32 |
| GET | `/api/sensors` | Data seluruh sensor |
| GET | `/api/devices` | Status aktuator |
| GET | `/api/notifications` | Informasi notifikasi |
| POST | `/api/config` | Mengatur ambang batas |

Contoh format JSON data sensor:

```json
{
  "temperature": 29.5,
  "humidity": 70,
  "gas_value": 1200,
  "ldr_value": 2500,
  "rain_detected": false,
  "visitor_detected": true,
  "visitor_distance": 45,
  "vehicle_status": "Ada",
  "vehicle_distance": 80,
  "servo_angle": 0,
  "led_status": "OFF",
  "buzzer_status": "OFF"
}
```

Nilai di atas hanya contoh struktur respons, bukan data sensor sebenarnya.

---

## 8. NON-FUNCTIONAL REQUIREMENTS

- Aplikasi memiliki desain modern, minimalis, dan mudah digunakan.
- Menggunakan tema Smart Home yang konsisten.
- Data monitoring diperbarui secara berkala.
- Koneksi ESP32 harus memiliki indikator status.
- SQLite digunakan untuk penyimpanan lokal.
- Sistem dapat menangani kondisi sensor tidak tersedia.
- Tidak menampilkan data palsu sebagai data real-time.
- Otomatisasi dasar tetap berjalan pada ESP32 meskipun aplikasi ditutup.
- Aplikasi hanya membutuhkan dua halaman utama.

---

## 9. TECHNOLOGY STACK

| Layer | Technology |
|---|---|
| Mobile Application | Flutter |
| Programming Language | Dart |
| Microcontroller | ESP32 DevKit V1 |
| ESP32 Programming | MicroPython |
| IDE | Thonny |
| Communication | Wi-Fi + HTTP |
| API Format | JSON |
| Database | SQLite |
| Local Storage | SQLite |

---

## 10. DEVELOPMENT ROADMAP

### Phase 1 — Hardware Setup
- Memasang seluruh sensor dan aktuator.
- Memastikan GPIO sesuai konfigurasi.
- Menguji pembacaan setiap sensor.

### Phase 2 — ESP32 Programming
- Membuat program MicroPython.
- Membuat logika otomatisasi hujan dan servo.
- Membuat logika buzzer.
- Membuat logika LED.
- Membuat deteksi tamu dan kendaraan.

### Phase 3 — ESP32 HTTP Server
- Menghubungkan ESP32 ke Wi-Fi.
- Menjalankan HTTP server.
- Membuat endpoint JSON.
- Menguji komunikasi menggunakan browser atau API client.

### Phase 4 — Mobile Application
- Membuat halaman Beranda.
- Membuat halaman Monitoring.
- Membuat fitur input IP ESP32.
- Menghubungkan aplikasi dengan HTTP API.

### Phase 5 — Database Integration
- Membuat database SQLite.
- Menyimpan riwayat monitoring.
- Menyimpan riwayat notifikasi.

### Phase 6 — Testing
- Menguji seluruh sensor.
- Menguji otomatisasi.
- Menguji notifikasi tamu.
- Menguji status kendaraan.
- Menguji koneksi dan kondisi offline.

---

## 11. SUCCESS CRITERIA

Proyek dinyatakan berhasil apabila:

1. Semua sensor dapat dibaca oleh ESP32.
2. Servo bergerak ke 90° ketika hujan terdeteksi dan kembali ke 0° ketika tidak hujan.
3. Buzzer aktif ketika suhu atau gas melewati ambang batas.
4. Aplikasi menerima notifikasi ketika tamu terdeteksi.
5. Status mobil diperbarui berdasarkan deteksi ultrasonic.
6. LED mati saat terang dan menyala saat gelap.
7. Pengguna dapat menghubungkan aplikasi melalui IP ESP32.
8. Monitoring menampilkan data aktual perangkat.
9. Riwayat data tersimpan di SQLite.
10. Sistem otomatisasi tetap bekerja tanpa aplikasi terbuka.

---

**END OF DOCUMENT**

**Project:** Smart Home IoT Monitoring System  
**Document:** iot.md  
**Version:** 1.0