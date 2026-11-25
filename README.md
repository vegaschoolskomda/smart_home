# Smart Home IoT Mobile Application

Aplikasi mobile monitoring sistem Smart Home IoT berbasis **Flutter (Dart)** yang terhubung secara real-time dengan mikrokontroler **ESP32 DevKit V1** (MicroPython) melalui jaringan Wi-Fi lokal, dengan penyimpanan riwayat lokal menggunakan **SQLite** dan sistem notifikasi peringatan dini.

---

## 1. File APK Siap Pakai

File installer APK Android versi rilis telah berhasil dikompilasi dan siap dipasang pada smartphone:

- **Lokasi File APK:**  
  `build/app/outputs/flutter-apk/app-release.apk`
- **Ukuran File:** ±50 MB
- **Target OS:** Android 6.0 (API level 23) ke atas

---

## 2. Cara Install APK di Smartphone Android

Ikuti langkah-langkah berikut untuk memasang aplikasi di HP Android Anda:

### Langkah A: Memindahkan File APK ke Smartphone
Pilih salah satu cara yang paling mudah:
1. **Kabel USB:** Hubungkan smartphone ke laptop/PC dengan kabel data, lalu salin file `app-release.apk` ke folder `Download` di penyimpanan internal smartphone.
2. **Kirim via Cloud / Chat:** Unggah file APK ke Google Drive atau kirim melalui dokumen WhatsApp/Telegram ke akun pribadi Anda di smartphone.
3. **Menggunakan ADB (Khusus Developer):**
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

### Langkah B: Mengizinkan Instalasi Aplikasi dari Sumber Tidak Dikenal
1. Buka pengelola file (File Manager) di smartphone Anda.
2. Temukan dan klik file `app-release.apk`.
3. Jika muncul dialog peringatan keamanan **"Sumber Tidak Dikenal"** (*Install Unknown Apps*):
   - Klik **Setelan** (*Settings*).
   - Aktifkan tombol **Izinkan dari sumber ini** (*Allow from this source*).
   - Kembali ke layar instalasi.

### Langkah C: Proses Instalasi & Izin Notifikasi
1. Klik tombol **Install** dan tunggu hingga proses pemasangan selesai.
2. Buka aplikasi **Smart Home**.
3. Saat pertama kali dibuka di Android 13 ke atas, izinkan permintaan notifikasi (**Allow Notifications**) agar peringatan deteksi tamu, suhu panas, dan gas berbahaya dapat muncul di bilah notifikasi smartphone Anda.

---

## 3. Cara Menggunakan Aplikasi

Aplikasi dirancang dengan antarmuka bersih, cepat, dan hanya memiliki **2 halaman utama** sesuai navigasi bawah:

```
[ Beranda ]  <======>  [ Monitoring ]
```

### A. Halaman Beranda (Home)
Halaman ini adalah pusat ringkasan informasi dan pengelolaan koneksi mikrokontroler:

1. **Menghubungkan ke ESP32:**
   - Pastikan smartphone dan ESP32 terhubung ke **jaringan Wi-Fi / Hotspot yang sama**.
   - Masukkan alamat IP ESP32 pada kolom input (contoh: `192.168.1.10`).
   - Tekan tombol **Connect**.
   - Aplikasi akan melakukan ping dan verifikasi koneksi ke endpoint `/api/status`.
   - Alamat IP ini secara otomatis disimpan ke database SQLite (`connection_settings`), sehingga saat aplikasi dibuka kembali, alamat IP terakhir akan terisi secara otomatis.
   - Jika koneksi berhasil, status di sudut kanan atas berubah menjadi badge hijau **Online**.
   - Jika ingin memutus koneksi, cukup tekan tombol merah **Disconnect**.

2. **Mode Uji Coba / Demo:**
   - Jika Anda sedang tidak berada di dekat perangkat ESP32 fisik, aktifkan toggle **Demo** di kartu Koneksi.
   - Aplikasi akan menjalankan simulasi telemetri sensor dinamis dan logika otomatisasi secara langsung.

3. **Ringkasan Kondisi Rumah:**
   - Menampilkan 4 parameter utama: Suhu DHT11 (°C), Kelembapan udara (%), Kadar gas MQ-2 (ADC), dan Status cahaya LDR (Terang/Gelap).
   - Jika koneksi offline/terputus, kartu menampilkan tanda `--` dan keterangan waktu sinkronisasi terakhir secara jujur.

4. **Ringkasan Perangkat:**
   - Memantau status Lampu LED (Aktif/Mati), Buzzer Alarm (Aktif/Mati), Motor Servo Kanopi (Sudut 0°/90°), dan Sensor Air Hujan.
   - Terdapat tombol akses cepat **Buka Halaman Monitoring Lengkap** yang langsung mengarahkan Anda ke halaman monitoring.

---

### B. Halaman Monitoring (Detail Sensor & Riwayat)
Halaman ini menyajikan pembagian komprehensif seluruh sensor dan histori peringatan:

1. **1. Environmental Monitoring:**
   - **Suhu Lingkungan (DHT11 - GPIO4):** Nilai temperatur aktual dan badge status (Normal, Dingin, atau Tinggi).
   - **Kelembapan Udara (DHT11 - GPIO4):** Persentase kelembapan udara ruangan.
   - **Kadar Gas / Asap (MQ-2 - GPIO32):** Nilai analog ADC beserta status (Aman, Waspada, atau Bahaya / Asap Terdeteksi).
   - **Intensitas Cahaya (LDR - GPIO35):** Nilai pembacaan intensitas cahaya dan status Terang atau Gelap.
   - **Sensor Air Hujan (Rain Module - GPIO34):** Status real-time cuaca (Hujan atau Tidak Hujan).

2. **2. Security Monitoring:**
   - **Ultrasonic 1 - Deteksi Tamu (HC-SR04 - TRIG 21, ECHO 22):** Mengukur jarak objek di depan pintu masuk. Status berupa *Tamu Terdeteksi* atau *Tidak Ada Tamu*.
   - **Ultrasonic 2 - Monitoring Kendaraan (HC-SR04 - TRIG 18, ECHO 19):** Mengukur jarak kendaraan di area parkir/garasi. Status berupa *Mobil Ada* atau *Mobil Tidak Ada*.

3. **3. Automatic Device Control:**
   - **Motor Servo Kanopi (GPIO13):** Menampilkan sudut servo (0° saat kering, bergerak ke 90° menutup kanopi saat sensor mendeteksi air hujan).
   - **Lampu LED (GPIO25):** Menyala otomatis saat sensor LDR mendeteksi kondisi gelap, dan mati saat terang.
   - **Buzzer Alarm (GPIO27):** Otomatis berbunyi saat suhu ruangan atau kadar gas melebihi batas aman, dan berhenti jika kedua kondisi kembali normal.
   - *Catatan:* Seluruh logika otomatisasi di atas dijalankan langsung oleh firmware MicroPython di ESP32. Aplikasi mobile bertindak sebagai pemantau status real-time.

4. **4. Notification History (Riwayat Notifikasi Lokal):**
   - Menampilkan daftar kejadian penting yang tercatat di database SQLite:
     - Tamu terdeteksi di depan pintu rumah.
     - Peringatan suhu ruangan melebihi ambang batas.
     - Peringatan gas/asap terdeteksi tinggi.
     - Perubahan status hujan dan penutupan kanopi.
   - Setiap entri memiliki ikon kategori, judul, deskripsi, waktu kejadian relatif (misal: "2 menit lalu"), serta tombol tandai dibaca.
   - Fitur **Uji Notifikasi** (ikon lonceng bertanda tambah di header) untuk menguji pengiriman notifikasi lokal ke status bar smartphone Anda.
   - Menu opsi untuk **Tandai Semua Dibaca** dan **Hapus Semua Riwayat**.

---

## 4. Struktur Database SQLite (smarthome.db)

Aplikasi menyimpan seluruh data di database lokal SQLite secara otomatis:

1. `connection_settings` (id, esp32_ip, updated_at)
2. `sensor_logs` (id, temperature, humidity, gas_value, ldr_value, rain_status, created_at)
3. `device_logs` (id, servo_angle, led_status, buzzer_status, created_at)
4. `visitor_logs` (id, distance, detected, detected_at)
5. `vehicle_logs` (id, distance, vehicle_status, detected_at)
6. `notifications` (id, title, message, type, is_read, created_at)

Sistem database dilengkapi dengan mekanisme pembersihan otomatis (*auto-pruning*) sehingga ukuran database tetap ringan dan hemat penyimpanan perangkat.

---

## 5. Spesifikasi Komunikasi HTTP API (MicroPython ESP32)

Aplikasi mengirimkan permintaan HTTP GET ke alamat IP ESP32 secara berkala (polling interval 1.5 detik) dengan proteksi anti-request stacking.

### Endpoint Utama
- `GET /api/status`

### Contoh Format Response JSON dari ESP32
```json
{
  "temperature": 29.5,
  "humidity": 70.0,
  "gas_value": 1200,
  "ldr_value": 2500,
  "rain_status": false,
  "visitor_detected": true,
  "visitor_distance": 45.0,
  "vehicle_status": "Ada",
  "vehicle_distance": 80.0,
  "servo_angle": 0,
  "led_status": false,
  "buzzer_status": false
}
```

Aplikasi memiliki parser toleran yang mampu menangani tipe data string, angka desimal, maupun boolean dari MicroPython tanpa menyebabkan crash.
