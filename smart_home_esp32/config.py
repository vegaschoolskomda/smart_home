# config.py - Central Configuration for Smart Home ESP32

# ==================== KONEKSI WIFI ====================
# Ubah SSID dan password sesuai router / hotspot Anda (hanya frekuensi 2.4 GHz)
WIFI_SSID = "NAMA_WIFI"
WIFI_PASSWORD = "PASSWORD_WIFI"
WIFI_TIMEOUT_SEC = 20
WIFI_RECONNECT_INTERVAL_SEC = 10

# ==================== KONFIGURASI GPIO ====================
PIN_DHT = 4
PIN_MQ2 = 32
PIN_LDR = 35
PIN_RAIN = 34
PIN_SERVO = 13
PIN_BUZZER = 27
PIN_LED = 25

PIN_US_VISITOR_TRIG = 21
PIN_US_VISITOR_ECHO = 22
PIN_US_VEHICLE_TRIG = 18
PIN_US_VEHICLE_ECHO = 19

# ==================== THRESHOLD DEFAULT ====================
# Threshold berikut dapat diubah secara dinamis melalui HTTP API POST /api/config
CONFIG = {
    "temp_threshold": 33.0,          # Batas suhu alarm (°C)
    "gas_threshold": 1400,           # Batas gas/asap alarm (ADC 0-4095)
    "ldr_dark_threshold": 2000,      # Batas gelap analog (ADC 0-4095)
    "ldr_hysteresis": 150,           # Buffer histeresis agar LED tidak flickering
    "rain_active_low": True,         # True: sinyal LOW = air terdeteksi (standar modul hujan)
    "visitor_distance_cm": 50.0,     # Jarak maksimal tamu terdeteksi (cm)
    "vehicle_distance_cm": 100.0,    # Jarak maksimal mobil terdeteksi (cm)
    "servo_angle_open": 0,           # Sudut kanopi terbuka (derajat)
    "servo_angle_rain": 90,          # Sudut kanopi tertutup saat hujan (derajat)
    "visitor_cooldown_sec": 30,      # Cooldown notifikasi tamu (detik)
    "sensor_interval_ms": 1500,      # Interval pembacaan sensor (ms)
}

def update_config(new_params):
    """
    Memperbarui konfigurasi threshold secara aman dari payload JSON.
    Mengembalikan dict perubahan yang berhasil diterapkan.
    """
    updated = {}
    for key, value in new_params.items():
        if key in CONFIG:
            try:
                # Pertahankan tipe data asli
                orig_type = type(CONFIG[key])
                if orig_type == bool:
                    CONFIG[key] = bool(value)
                elif orig_type == int:
                    CONFIG[key] = int(value)
                elif orig_type == float:
                    CONFIG[key] = float(value)
                else:
                    CONFIG[key] = value
                updated[key] = CONFIG[key]
            except Exception:
                pass
    return updated
