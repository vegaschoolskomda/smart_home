# Panduan Firmware ESP32 MicroPython - Smart Home IoT Monitoring System

Firmware MicroPython modular untuk mikrokontroler **ESP32 DevKit V1** yang menjalankan pembacaan sensor real-time, otomatisasi perangkat lokal, dan HTTP REST API Web Server untuk komunikasi dengan aplikasi mobile Flutter.

---

## 1. Skema Rangkaian Hardware & Pinout GPIO

| No | Komponen Hardware | Pin ESP32 | Tipe Pin | Keterangan & Catatan Keamanan |
|---|---|---|---|---|
| 1 | **DHT11** (Suhu & Kelembapan) | GPIO 4 | Input/Output | Tambahkan resistor pull-up 4.7kΩ - 10kΩ antara pin Data dan 3.3V jika modul belum memiliki pull-up internal. |
| 2 | **MQ-2** (Sensor Gas / Asap) | GPIO 32 | ADC Input | Hubungkan pin Analog Out (A0) ke GPIO 32. Suplai VCC modul MQ-2 membutuhkan 5V stabil. Pastikan tegangan output analog tidak melebihi 3.3V. |
| 3 | **LDR Module** (Sensor Cahaya) | GPIO 35 | ADC Input | GPIO 35 adalah **Input-Only** tanpa pull-up internal. Hubungkan pin Analog Out (AO) LDR ke GPIO 35. |
| 4 | **Rain Sensor** (Sensor Hujan) | GPIO 34 | Digital Input | GPIO 34 adalah **Input-Only**. Hubungkan pin Digital Out (DO) modul ke GPIO 34. Sinyal LOW (0) menandakan air hujan terdeteksi. |
| 5 | **Servo Motor** (Kanopi) | GPIO 13 | PWM Output | Frekuensi PWM 50 Hz. Suplai daya servo (VCC) wajib menggunakan sumber daya 5V eksternal atau pin VIN dengan ground bersama (common ground), **bukan dari pin 3.3V ESP32**. |
| 6 | **Buzzer** (Alarm Peringatan) | GPIO 27 | Digital Output | Sinyal HIGH mengaktifkan buzzer. Gunakan transistor driver (misal 2N2222) jika buzzer membutuhkan arus lebih dari 12mA. |
| 7 | **LED** (Lampu Penerangan) | GPIO 25 | Digital Output | Tambahkan resistor 220Ω - 330Ω secara seri dengan anoda LED ke GPIO 25. |
| 8 | **HC-SR04 1** (Deteksi Tamu) | TRIG: GPIO 21<br>ECHO: GPIO 22 | Out / In | **Penting:** Pin ECHO menghasilkan sinyal 5V. Wajib gunakan pembagi tegangan (*voltage divider*) 1kΩ dan 2kΩ agar sinyal yang masuk ke GPIO 22 aman pada level 3.3V. |
| 9 | **HC-SR04 2** (Deteksi Kendaraan) | TRIG: GPIO 18<br>ECHO: GPIO 19 | Out / In | **Penting:** Pin ECHO wajib menggunakan pembagi tegangan (*voltage divider*) ke GPIO 19. |

> **Catatan Keselamatan Hardware:**
> - Semua ground (GND) dari ESP32, sensor, modul, dan catu daya eksternal **wajib dihubungkan bersama (Common Ground)**.
> - GPIO 34 dan GPIO 35 hanya berfungsi sebagai pin input (tidak memiliki fungsi output digital).

---

## 2. Struktur File Firmware

Firmware kini telah disatukan secara monolitik ke dalam **1 file tunggal** agar sangat mudah dijalankan melalui Thonny IDE:

- **`main.py`** : Seluruh modul Wi-Fi, sensor, aktuator, otomatisasi, dan HTTP Web Server tergabung lengkap dalam 1 file ini. Cukup buka file ini di Thonny dan tekan **Run Current Script (F5)** atau simpan sebagai `main.py` di ESP32 agar otomatis berjalan saat dinyalakan.

---

## 3. Persiapan & Cara Menjalankan di Thonny IDE (1 File Saja)

1. **Buka Thonny IDE:**
   - Hubungkan board ESP32 ke laptop menggunakan kabel USB.
   - Buka Thonny IDE, klik menu **Tools** > **Options** > tab **Interpreter**:
     - Pilih: **MicroPython (ESP32)**.
     - Port: Pilih port COM ESP32 Anda (misal `COM3` atau `COM4`).
2. **Buka `main.py`:**
   - Buka file `smart_home_esp32/main.py` di Thonny IDE.
3. **Ubah Konfigurasi Wi-Fi di Bagian Atas File:**
   - Cari baris berikut di bagian awal `main.py`:
     ```python
     WIFI_SSID = "NAMA_WIFI_ANDA"
     WIFI_PASSWORD = "PASSWORD_WIFI_ANDA"
     ```
   - Masukkan nama Wi-Fi (SSID) dan password router/hotspot 2.4 GHz Anda.
4. **Jalankan Program:**
   - **Cara A (Uji Langsung):** Klik tombol hijau **Run current script (F5)** di Thonny.
   - **Cara B (Jalan Otomatis saat ESP32 Dicolokkan):** Klik menu **File** > **Save as...** > pilih **MicroPython device** > beri nama **`main.py`**.
   - Tekan tombol **EN / RST** pada board ESP32. Program akan langsung berjalan secara otomatis.

---

## 4. Mendapatkan Alamat IP ESP32

Setelah perangkat menyala, buka **Shell / Serial Monitor** di Thonny IDE (baudrate 115200). Anda akan melihat output berikut:

```text
Boot completed. Memory free: 112450 bytes
========================================
      SMART HOME ESP32 DevKit V1        
========================================
SMART HOME IoT SYSTEM
-------------------------
Connecting to WiFi: MyHome
....
WiFi Connected!
SSID: MyHome
ESP32 IP: 192.168.1.10
Subnet: 255.255.255.0
Gateway: 192.168.1.1
-------------------------
[Device] Memindahkan Servo dari 0° ke 0°
[HTTP Server] Berjalan pada port 80
[Core] Loop otomatisasi sensor aktif.
```

Catat **Alamat IP ESP32** (contoh: `192.168.1.10`). Alamat IP inilah yang dimasukkan ke aplikasi Flutter.

---

## 5. Dokumentasi Endpoint HTTP REST API

ESP32 menyediakan web server asinkron pada port 80 dengan respons JSON standar:

### 1. GET `/api/status`
Endpoint utama yang digunakan aplikasi mobile Flutter untuk mendapatkan status koneksi dan telemetri sensor terpadu.

**Contoh Response (200 OK):**
```json
{
  "device": "Smart Home ESP32",
  "online": true,
  "wifi_connected": true,
  "ip_address": "192.168.1.10",
  "uptime": 145,
  "temperature": 28.4,
  "humidity": 68.0,
  "gas_value": 420,
  "gas_status": "NORMAL",
  "ldr_value": 980,
  "light_status": "LIGHT",
  "rain_status": false,
  "rain_detected": false,
  "visitor_detected": false,
  "visitor_distance": 142.5,
  "vehicle_status": "Ada",
  "vehicle_distance": 62.0,
  "servo_angle": 0,
  "led_status": false,
  "buzzer_status": false,
  "updated_at": 1700000145
}
```

### 2. GET `/api/sensors`
Mengambil pembacaan data sensor secara spesifik.

**Contoh Response (200 OK):**
```json
{
  "temperature": 28.4,
  "humidity": 68.0,
  "gas_value": 420,
  "gas_status": "NORMAL",
  "ldr_value": 980,
  "light_status": "LIGHT",
  "rain_detected": false,
  "visitor_distance": 142.5,
  "visitor_detected": false,
  "vehicle_distance": 62.0,
  "vehicle_status": "Ada",
  "updated_at": 1700000145
}
```

### 3. GET `/api/devices`
Mengambil status aktuator perangkat saat ini.

**Contoh Response (200 OK):**
```json
{
  "servo_angle": 0,
  "led_status": "OFF",
  "buzzer_status": "OFF",
  "led_active": false,
  "buzzer_active": false
}
```

### 4. GET `/api/notifications`
Mengambil antrean riwayat kejadian/event terbaru yang tercatat oleh ESP32.

**Contoh Response (200 OK):**
```json
{
  "notifications": [
    {
      "id": 1,
      "type": "VISITOR",
      "title": "Tamu Terdeteksi",
      "message": "Ada tamu di depan rumah (jarak 35.0 cm).",
      "timestamp": 1700000130
    }
  ]
}
```

### 5. POST `/api/config`
Memperbarui ambang batas (*threshold*) sensor secara dinamis tanpa perlu merestart program.

**Contoh Request Body (JSON):**
```json
{
  "temp_threshold": 34.0,
  "gas_threshold": 1500,
  "visitor_distance_cm": 60.0
}
```

**Contoh Response (200 OK):**
```json
{
  "success": true,
  "message": "Konfigurasi threshold berhasil diperbarui",
  "updated": {
    "temp_threshold": 34.0,
    "gas_threshold": 1500,
    "visitor_distance_cm": 60.0
  }
}
```

---

## 6. Panduan Pengujian Bertahap

Lakukan pengujian secara bertahap untuk memastikan sistem bekerja sempurna:

### Langkah 1: Pengujian Web Server Melalui Browser HP / Laptop
Pastikan laptop atau HP terhubung ke Wi-Fi yang sama dengan ESP32. Buka browser dan akses URL berikut:
- `http://192.168.1.10/` (Ganti dengan IP aktual ESP32 Anda) -> Memastikan web server aktif.
- `http://192.168.1.10/api/status` -> Memastikan data JSON status muncul.
- `http://192.168.1.10/api/sensors` -> Memastikan data sensor terkirim.

### Langkah 2: Pengujian Otomatisasi Hujan & Servo
- Teteskan sedikit air pada papan sensor hujan (GPIO 34).
- Amati servo motor: servo harus bergerak otomatis ke sudut **90°** (kanopi tertutup).
- Keringkan sensor menggunakan tisu: servo harus kembali otomatis ke sudut **0°** (kanopi terbuka).

### Langkah 3: Pengujian Otomatisasi Cahaya & Lampu LED
- Tutupi permukaan LDR (GPIO 35) dengan jari hingga kondisi gelap: LED pada GPIO 25 harus otomatis menyala.
- Buka kembali penutup: LED harus otomatis mati.

### Langkah 4: Pengujian Alarm Peringatan Buzzer
- Berikan hembusan gas korek api ke dekat sensor MQ-2 (GPIO 32) atau naikkan suhu DHT11 melewati ambang batas: Buzzer pada GPIO 27 harus berbunyi.
- Jauhkan sumber gas dan biarkan suhu turun ke normal: Buzzer harus otomatis berhenti berbunyi saat kedua kondisi aman.

### Langkah 5: Pengujian Sensor Ultrasonic Tamu & Mobil
- Tempatkan tangan di depan sensor Ultrasonic 1 (GPIO 21 & 22) dengan jarak di bawah 50 cm: Status berubah menjadi *Tamu Terdeteksi*.
- Periksa endpoint `http://192.168.1.10/api/notifications` untuk melihat catatan notifikasi tamu.
- Tempatkan objek di depan sensor Ultrasonic 2 (GPIO 18 & 19): Status berubah menjadi *Mobil Ada*.

### Langkah 6: Pengujian Integrasi dengan Aplikasi Mobile Flutter
1. Buka aplikasi **Smart Home** pada smartphone Android Anda.
2. Masukkan alamat IP ESP32 pada kolom input di halaman **Beranda**.
3. Tekan tombol **Connect**.
4. Badge status akan berubah menjadi **Online** berwarna hijau.
5. Pindah ke tab **Monitoring** untuk melihat seluruh pembacaan sensor dan status aktuator secara langsung.
