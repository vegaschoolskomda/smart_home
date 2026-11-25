# automation.py - Automation Logic & Event Notifications

import time
from config import CONFIG

class AutomationSystem:
    def __init__(self, sensor_mgr, device_mgr):
        self.sensors = sensor_mgr
        self.devices = device_mgr

        # State tracking sebelumnya untuk deteksi perubahan
        self.prev_rain_detected = None
        self.prev_visitor_detected = False
        self.last_visitor_alert_time = 0

        # Prioritas kondisi alarm buzzer
        self.temp_alarm = False
        self.gas_alarm = False

        # Queue riwayat notifikasi lokal (maksimal 20 item)
        self.notifications = []
        self.notification_id_counter = 1

    def add_notification(self, notif_type, title, message):
        """Menambahkan kejadian ke daftar riwayat notifikasi."""
        entry = {
            "id": self.notification_id_counter,
            "type": notif_type,
            "title": title,
            "message": message,
            "timestamp": time.time()
        }
        self.notification_id_counter += 1
        self.notifications.insert(0, entry)
        # Batasi ukuran antrean notifikasi agar hemat memori RAM
        if len(self.notifications) > 20:
            self.notifications.pop()
        print("[Event]", title + ":", message)

    def process(self):
        """
        Menjalankan seluruh logika otomatisasi secara independen.
        Dipanggil setiap kali ada data sensor baru.
        """
        now = time.time()

        # ==============================================================
        # 1. Otomatisasi Hujan + Motor Servo
        # ==============================================================
        # Ketika hujan terdeteksi -> servo bergerak ke 90° (menutup kanopi)
        # Ketika hujan reda -> servo kembali ke 0° (membuka kanopi)
        # Servo hanya digerakkan ketika status hujan mengalami perubahan
        current_rain = self.sensors.rain_detected
        if self.prev_rain_detected is None or self.prev_rain_detected != current_rain:
            if current_rain:
                target_angle = CONFIG["servo_angle_rain"]
                self.devices.set_servo_angle(target_angle)
                self.add_notification(
                    "RAIN",
                    "Hujan Terdeteksi",
                    "Sensor air mendeteksi hujan. Kanopi bergerak ke " + str(target_angle) + "°."
                )
            else:
                target_angle = CONFIG["servo_angle_open"]
                self.devices.set_servo_angle(target_angle)
                if self.prev_rain_detected is not None:
                    self.add_notification(
                        "RAIN",
                        "Hujan Reda",
                        "Cuaca kembali kering. Kanopi kembali ke " + str(target_angle) + "°."
                    )
            self.prev_rain_detected = current_rain

        # ==============================================================
        # 2. Otomatisasi LDR + Lampu LED (dengan histeresis)
        # ==============================================================
        # Kondisi Gelap: LED menyala
        # Kondisi Terang: LED mati
        if self.sensors.light_status == "DARK":
            self.devices.set_led(True)
        elif self.sensors.light_status == "LIGHT":
            self.devices.set_led(False)

        # ==============================================================
        # 3. Logika Prioritas Alarm Buzzer (DHT11 + MQ-2)
        # ==============================================================
        # Suhu tinggi memicu alarm
        if self.sensors.temperature is not None:
            if self.sensors.temperature >= CONFIG["temp_threshold"]:
                if not self.temp_alarm:
                    self.temp_alarm = True
                    self.add_notification(
                        "TEMPERATURE",
                        "Peringatan Suhu Tinggi",
                        "Suhu ruangan mencapai " + str(round(self.sensors.temperature, 1)) + " °C."
                    )
            else:
                self.temp_alarm = False

        # Gas tinggi memicu alarm
        if self.sensors.gas_value >= CONFIG["gas_threshold"]:
            if not self.gas_alarm:
                self.gas_alarm = True
                self.add_notification(
                    "GAS",
                    "Peringatan Gas / Asap",
                    "Nilai gas MQ-2 tinggi (" + str(self.sensors.gas_value) + "). Waspada bahaya kebakaran."
                )
        else:
            self.gas_alarm = False

        # Aturan Prioritas:
        # Buzzer harus aktif apabila suhu tinggi ATAU gas tinggi.
        # Buzzer baru mati ketika KEDUA kondisi kembali normal.
        if self.temp_alarm or self.gas_alarm:
            self.devices.set_buzzer(True)
        else:
            self.devices.set_buzzer(False)

        # ==============================================================
        # 4. Deteksi Tamu (Ultrasonic 1) + Cooldown Notifikasi
        # ==============================================================
        is_visitor = self.sensors.visitor_detected
        if is_visitor:
            # Tamu terdeteksi: periksa apakah baru atau sudah melewati cooldown
            time_since_last_alert = now - self.last_visitor_alert_time
            if (not self.prev_visitor_detected) or (time_since_last_alert >= CONFIG["visitor_cooldown_sec"]):
                dist_str = str(self.sensors.visitor_distance) if self.sensors.visitor_distance is not None else "--"
                self.add_notification(
                    "VISITOR",
                    "Tamu Terdeteksi",
                    "Ada tamu di depan rumah (jarak " + dist_str + " cm)."
                )
                self.last_visitor_alert_time = now
            self.prev_visitor_detected = True
        else:
            # Tamu meninggalkan area: reset flag
            self.prev_visitor_detected = False

    def get_notifications(self):
        """Mengembalikan daftar riwayat notifikasi."""
        return self.notifications
