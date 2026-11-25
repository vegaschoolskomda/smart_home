# ==============================================================================
# SMART HOME IoT MONITORING SYSTEM - ESP32 DevKit V1
# Single-File Monolithic MicroPython Firmware for Thonny IDE
# ==============================================================================

import gc
import esp
import time
import json
import network
import uasyncio as asyncio
from machine import Pin, ADC, PWM, time_pulse_us
import dht

# Nonaktifkan debug output OS ESP32 agar serial monitor Thonny bersih
esp.osdebug(None)
gc.enable()
gc.collect()

# ==============================================================================
# 1. KONFIGURASI WIFI & GPIO
# ==============================================================================

# Ubah SSID dan Password sesuai router / hotspot Wi-Fi Anda (wajib 2.4 GHz)
WIFI_SSID = "punyaghea"
WIFI_PASSWORD = "kudanilungu"
WIFI_TIMEOUT_SEC = 20
WIFI_RECONNECT_INTERVAL_SEC = 10

# Konfigurasi Pin GPIO ESP32 DevKit V1
PIN_DHT = 4                   # DHT11 (Suhu & Kelembapan)
PIN_MQ2 = 32                  # MQ-2 Gas/Asap Analog ADC
PIN_LDR = 35                  # LDR Cahaya Analog ADC (Input-Only)
PIN_RAIN = 34                 # Sensor Hujan Digital (Input-Only)
PIN_SERVO = 13                # Motor Servo PWM Kanopi
PIN_BUZZER = 27               # Buzzer Alarm Peringatan
PIN_LED = 25                  # Lampu LED Penerangan

PIN_US_VISITOR_TRIG = 21      # Ultrasonic 1 (Tamu) TRIG
PIN_US_VISITOR_ECHO = 22      # Ultrasonic 1 (Tamu) ECHO (Wajib Voltage Divider)
PIN_US_VEHICLE_TRIG = 18      # Ultrasonic 2 (Kendaraan) TRIG
PIN_US_VEHICLE_ECHO = 19      # Ultrasonic 2 (Kendaraan) ECHO (Wajib Voltage Divider)

# Threshold Default (Dapat diperbarui secara dinamis via POST /api/config)
CONFIG = {
    "temp_threshold": 33.0,          # Batas suhu alarm (°C)
    "gas_threshold": 1400,           # Batas gas/asap alarm (ADC 0-4095)
    "ldr_dark_threshold": 2000,      # Batas gelap analog (ADC 0-4095)
    "ldr_hysteresis": 150,           # Buffer histeresis agar LED tidak kedip
    "rain_active_low": True,         # True: sinyal LOW = hujan (standar modul)
    "visitor_distance_cm": 50.0,     # Jarak maksimal deteksi tamu (cm)
    "vehicle_distance_cm": 100.0,    # Jarak maksimal deteksi mobil (cm)
    "servo_angle_open": 0,           # Sudut kanopi terbuka (derajat)
    "servo_angle_rain": 90,          # Sudut kanopi tertutup saat hujan (derajat)
    "visitor_cooldown_sec": 30,      # Cooldown notifikasi tamu (detik)
    "sensor_interval_ms": 1500,      # Interval pembacaan sensor (ms)
}

def update_config(new_params):
    """Memperbarui konfigurasi threshold secara aman dari payload JSON."""
    updated = {}
    for key, value in new_params.items():
        if key in CONFIG:
            try:
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

# ==============================================================================
# 2. WIFI MANAGER (STATION MODE & AUTO RECONNECT)
# ==============================================================================

class WiFiManager:
    def __init__(self):
        self.wlan = network.WLAN(network.STA_IF)
        self.ip = "0.0.0.0"
        self.subnet = "0.0.0.0"
        self.gateway = "0.0.0.0"
        self.dns = "0.0.0.0"
        self.is_connected = False

    def connect(self):
        print("\nSMART HOME IoT SYSTEM")
        print("-------------------------")
        print("Connecting to WiFi:", WIFI_SSID)

        try:
            # 1. Nonaktifkan Access Point (AP_IF) jika aktif
            try:
                ap = network.WLAN(network.AP_IF)
                if ap.active():
                    ap.active(False)
            except Exception:
                pass

            # 2. Reset interface Station (STA_IF) untuk mengatasi bug "Wifi Internal State Error"
            # saat soft reboot Thonny IDE
            if self.wlan.active():
                try:
                    self.wlan.disconnect()
                except Exception:
                    pass
                self.wlan.active(False)
                time.sleep_ms(300)

            self.wlan.active(True)
            time.sleep_ms(300)

            # 3. Lakukan koneksi ke AP router
            if not self.wlan.isconnected():
                self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
                start_time = time.time()

                while not self.wlan.isconnected():
                    elapsed = time.time() - start_time
                    if elapsed > WIFI_TIMEOUT_SEC:
                        print("\n[!] WiFi Connection Timeout (" + str(WIFI_TIMEOUT_SEC) + "s)")
                        print("[!] Otomatisasi sensor lokal tetap aktif.")
                        self.is_connected = False
                        return False
                    print(".", end="")
                    time.sleep(0.5)

            self.is_connected = True
            config = self.wlan.ifconfig()
            self.ip = config[0]
            self.subnet = config[1]
            self.gateway = config[2]
            self.dns = config[3]

            print("\nWiFi Connected!")
            print("SSID: " + WIFI_SSID)
            print("ESP32 IP: " + self.ip)
            print("Subnet: " + self.subnet)
            print("Gateway: " + self.gateway)
            print("HTTP Server: Running")
            print("-------------------------")
            return True

        except Exception as e:
            print("\n[WiFi] Peringatan koneksi:", e)
            print("[WiFi] Sensor dan aktuator tetap beroperasi secara mandiri.")
            self.is_connected = False
            return False

    async def monitor_loop(self):
        """Memantau koneksi Wi-Fi di background dan reconnect otomatis jika terputus."""
        while True:
            try:
                if not self.wlan.isconnected():
                    self.is_connected = False
                    print("[WiFi] Terputus. Menghubungkan ulang...")
                    try:
                        if not self.wlan.active():
                            self.wlan.active(True)
                            time.sleep_ms(200)
                        self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
                    except Exception as e:
                        print("[WiFi] Reconnect error:", e)

                    for _ in range(10):
                        if self.wlan.isconnected():
                            self.is_connected = True
                            self.ip = self.wlan.ifconfig()[0]
                            print("[WiFi] Terhubung kembali! IP:", self.ip)
                            break
                        await asyncio.sleep(1)
                else:
                    self.is_connected = True
            except Exception as e:
                print("[WiFi] Monitor error:", e)

            await asyncio.sleep(WIFI_RECONNECT_INTERVAL_SEC)

# ==============================================================================
# 3. SENSOR MANAGER
# ==============================================================================

class SensorManager:
    def __init__(self):
        # DHT11 (GPIO4)
        try:
            self.dht_sensor = dht.DHT11(Pin(PIN_DHT))
        except Exception as e:
            print("[Sensor] Gagal inisialisasi DHT11:", e)
            self.dht_sensor = None

        # MQ-2 ADC (GPIO32) - 12-bit (0-4095), 11dB (0-3.3V)
        self.mq2_adc = ADC(Pin(PIN_MQ2))
        self.mq2_adc.atten(ADC.ATTN_11DB)
        self.mq2_adc.width(ADC.WIDTH_12BIT)

        # LDR ADC (GPIO35 - Input Only)
        self.ldr_adc = ADC(Pin(PIN_LDR))
        self.ldr_adc.atten(ADC.ATTN_11DB)
        self.ldr_adc.width(ADC.WIDTH_12BIT)

        # Rain Sensor (GPIO34 - Input Only)
        self.rain_pin = Pin(PIN_RAIN, Pin.IN)

        # Ultrasonic 1 (Tamu - TRIG 21, ECHO 22)
        self.us_vis_trig = Pin(PIN_US_VISITOR_TRIG, Pin.OUT)
        self.us_vis_echo = Pin(PIN_US_VISITOR_ECHO, Pin.IN)
        self.us_vis_trig.value(0)

        # Ultrasonic 2 (Kendaraan - TRIG 18, ECHO 19)
        self.us_veh_trig = Pin(PIN_US_VEHICLE_TRIG, Pin.OUT)
        self.us_veh_echo = Pin(PIN_US_VEHICLE_ECHO, Pin.IN)
        self.us_veh_trig.value(0)

        # Cache data sensor
        self.temperature = None
        self.humidity = None
        self.gas_value = 0
        self.gas_status = "NORMAL"
        self.ldr_value = 0
        self.light_status = "LIGHT"
        self.rain_detected = False
        self.visitor_distance = None
        self.visitor_detected = False
        self.vehicle_distance = None
        self.vehicle_status = "Tidak Ada"
        self.last_read_timestamp = time.time()

    def read_dht(self):
        if self.dht_sensor is None:
            return None, None
        try:
            self.dht_sensor.measure()
            temp = float(self.dht_sensor.temperature())
            hum = float(self.dht_sensor.humidity())
            if 0.0 <= temp <= 50.0 and 20.0 <= hum <= 90.0:
                self.temperature = temp
                self.humidity = hum
                return temp, hum
        except Exception:
            pass
        return self.temperature, self.humidity

    def read_mq2(self):
        try:
            total = 0
            for _ in range(3):
                total += self.mq2_adc.read()
                time.sleep_us(100)
            self.gas_value = total // 3
            if self.gas_value >= CONFIG["gas_threshold"]:
                self.gas_status = "WARNING"
            else:
                self.gas_status = "NORMAL"
            return self.gas_value, self.gas_status
        except Exception as e:
            print("[Sensor] Error MQ-2:", e)
            return self.gas_value, self.gas_status

    def read_ldr(self):
        try:
            total = 0
            for _ in range(3):
                total += self.ldr_adc.read()
                time.sleep_us(100)
            self.ldr_value = total // 3

            threshold = CONFIG["ldr_dark_threshold"]
            hysteresis = CONFIG["ldr_hysteresis"]
            if self.ldr_value >= (threshold + hysteresis):
                self.light_status = "DARK"
            elif self.ldr_value <= (threshold - hysteresis):
                self.light_status = "LIGHT"

            return self.ldr_value, self.light_status
        except Exception as e:
            print("[Sensor] Error LDR:", e)
            return self.ldr_value, self.light_status

    def read_rain(self):
        try:
            val = self.rain_pin.value()
            if CONFIG["rain_active_low"]:
                self.rain_detected = (val == 0)
            else:
                self.rain_detected = (val == 1)
            return self.rain_detected
        except Exception as e:
            print("[Sensor] Error Rain:", e)
            return self.rain_detected

    def _measure_distance(self, trig_pin, echo_pin):
        try:
            trig_pin.value(0)
            time.sleep_us(2)
            trig_pin.value(1)
            time.sleep_us(10)
            trig_pin.value(0)

            duration = time_pulse_us(echo_pin, 1, 30000)
            if duration > 0:
                distance = (duration * 0.0343) / 2
                if 2.0 <= distance <= 400.0:
                    return round(distance, 1)
            return None
        except Exception:
            return None

    def read_visitor_distance(self):
        dist = self._measure_distance(self.us_vis_trig, self.us_vis_echo)
        if dist is not None:
            self.visitor_distance = dist
            self.visitor_detected = (dist <= CONFIG["visitor_distance_cm"])
        return self.visitor_distance, self.visitor_detected

    def read_vehicle_distance(self):
        dist = self._measure_distance(self.us_veh_trig, self.us_veh_echo)
        if dist is not None:
            self.vehicle_distance = dist
            if dist <= CONFIG["vehicle_distance_cm"]:
                self.vehicle_status = "Ada"
            else:
                self.vehicle_status = "Tidak Ada"
        return self.vehicle_distance, self.vehicle_status

    def read_all(self):
        self.read_dht()
        self.read_mq2()
        self.read_ldr()
        self.read_rain()
        self.read_visitor_distance()
        self.read_vehicle_distance()
        self.last_read_timestamp = time.time()
        return self.get_summary()

    def get_summary(self):
        return {
            "temperature": self.temperature,
            "humidity": self.humidity,
            "gas_value": self.gas_value,
            "gas_status": self.gas_status,
            "ldr_value": self.ldr_value,
            "light_status": self.light_status,
            "rain_detected": self.rain_detected,
            "visitor_distance": self.visitor_distance,
            "visitor_detected": self.visitor_detected,
            "vehicle_distance": self.vehicle_distance,
            "vehicle_status": self.vehicle_status,
            "updated_at": self.last_read_timestamp
        }

# ==============================================================================
# 4. DEVICE MANAGER (SERVO, BUZZER, LED)
# ==============================================================================

class DeviceManager:
    def __init__(self):
        self.led_pin = Pin(PIN_LED, Pin.OUT)
        self.led_pin.value(0)
        self.led_state = False

        self.buzzer_pin = Pin(PIN_BUZZER, Pin.OUT)
        self.buzzer_pin.value(0)
        self.buzzer_state = False

        try:
            self.servo_pwm = PWM(Pin(PIN_SERVO), freq=50)
            self.current_servo_angle = CONFIG["servo_angle_open"]
            self._set_servo_duty(self.current_servo_angle)
        except Exception as e:
            print("[Device] Gagal inisialisasi Servo PWM:", e)
            self.servo_pwm = None
            self.current_servo_angle = 0

    def _angle_to_duty_u16(self, angle):
        clamped_angle = max(0, min(180, angle))
        duty = int(1638 + (clamped_angle / 180.0) * (8192 - 1638))
        return duty

    def _set_servo_duty(self, angle):
        if self.servo_pwm is not None:
            try:
                duty = self._angle_to_duty_u16(angle)
                self.servo_pwm.duty_u16(duty)
            except Exception as e:
                print("[Servo] Duty error:", e)

    def set_servo_angle(self, angle):
        if self.current_servo_angle != angle:
            print("[Actuator] Memindahkan Servo dari " + str(self.current_servo_angle) + "° ke " + str(angle) + "°")
            self._set_servo_duty(angle)
            self.current_servo_angle = angle
            time.sleep_ms(300)

    def set_led(self, state):
        self.led_state = bool(state)
        self.led_pin.value(1 if self.led_state else 0)

    def set_buzzer(self, state):
        self.buzzer_state = bool(state)
        self.buzzer_pin.value(1 if self.buzzer_state else 0)

    def get_summary(self):
        return {
            "servo_angle": self.current_servo_angle,
            "led_status": "ON" if self.led_state else "OFF",
            "buzzer_status": "ON" if self.buzzer_state else "OFF",
            "led_active": self.led_state,
            "buzzer_active": self.buzzer_state
        }

# ==============================================================================
# 5. AUTOMATION SYSTEM
# ==============================================================================

class AutomationSystem:
    def __init__(self, sensor_mgr, device_mgr):
        self.sensors = sensor_mgr
        self.devices = device_mgr

        self.prev_rain_detected = None
        self.prev_visitor_detected = False
        self.last_visitor_alert_time = 0

        self.temp_alarm = False
        self.gas_alarm = False

        self.notifications = []
        self.notification_id_counter = 1

    def add_notification(self, notif_type, title, message):
        entry = {
            "id": self.notification_id_counter,
            "type": notif_type,
            "title": title,
            "message": message,
            "timestamp": time.time()
        }
        self.notification_id_counter += 1
        self.notifications.insert(0, entry)
        if len(self.notifications) > 20:
            self.notifications.pop()
        print("[Event]", title + ":", message)

    def process(self):
        now = time.time()

        # 1. Hujan + Servo Kanopi
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

        # 2. LDR + LED Penerangan (dengan histeresis)
        if self.sensors.light_status == "DARK":
            self.devices.set_led(True)
        elif self.sensors.light_status == "LIGHT":
            self.devices.set_led(False)

        # 3. Logika Prioritas Buzzer (Suhu Tinggi ATAU Gas Tinggi)
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

        # Buzzer aktif jika salah satu atau keduanya bahaya; mati jika keduanya normal
        if self.temp_alarm or self.gas_alarm:
            self.devices.set_buzzer(True)
        else:
            self.devices.set_buzzer(False)

        # 4. Deteksi Tamu (Ultrasonic 1) + Cooldown
        is_visitor = self.sensors.visitor_detected
        if is_visitor:
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
            self.prev_visitor_detected = False

    def get_notifications(self):
        return self.notifications

# ==============================================================================
# 6. HTTP WEB SERVER REST API (NON-BLOCKING ASYNC)
# ==============================================================================

class ApiServer:
    def __init__(self, wifi_mgr, sensor_mgr, device_mgr, automation_sys):
        self.wifi = wifi_mgr
        self.sensors = sensor_mgr
        self.devices = device_mgr
        self.automation = automation_sys
        self.start_time = time.time()
        self.server = None

    def get_uptime(self):
        return int(time.time() - self.start_time)

    async def start(self, port=80):
        try:
            self.server = await asyncio.start_server(self._handle_client, "0.0.0.0", port)
            print("[HTTP Server] Berjalan pada port " + str(port))
        except Exception as e:
            print("[HTTP Server] Gagal memulai server:", e)

    async def _handle_client(self, reader, writer):
        try:
            line = await reader.readline()
            if not line:
                await self._close_conn(writer)
                return

            request_line = line.decode().strip()
            parts = request_line.split()
            if len(parts) < 2:
                await self._send_json(writer, 400, {"error": "Bad Request"})
                return

            method = parts[0].upper()
            path = parts[1]
            print("[HTTP]", method, path)

            content_length = 0
            while True:
                header_line = await reader.readline()
                if not header_line or header_line.strip() == b"":
                    break
                h_str = header_line.decode().strip()
                if h_str.lower().startswith("content-length:"):
                    try:
                        content_length = int(h_str.split(":")[1].strip())
                    except Exception:
                        content_length = 0

            body_data = b""
            if content_length > 0:
                body_data = await reader.read(content_length)

            await self._route_request(writer, method, path, body_data)

        except Exception as e:
            print("[HTTP] Error handling client:", e)
            try:
                await self._send_json(writer, 500, {"error": "Internal Server Error", "detail": str(e)})
            except Exception:
                pass
        finally:
            await asyncio.sleep_ms(20)
            await self._close_conn(writer)

    async def _route_request(self, writer, method, path, body_data):
        clean_path = path.split("?")[0].rstrip("/")
        if clean_path == "":
            clean_path = "/"

        # GET /
        if method == "GET" and clean_path == "/":
            payload = {
                "system": "Smart Home IoT Monitoring System",
                "firmware": "MicroPython ESP32",
                "uptime": self.get_uptime(),
                "endpoints": [
                    "GET /",
                    "GET /api/status",
                    "GET /api/sensors",
                    "GET /api/devices",
                    "GET /api/notifications",
                    "POST /api/config"
                ]
            }
            await self._send_json(writer, 200, payload)

        # GET /api/status (Digunakan aplikasi Flutter untuk sinkronisasi telemetri)
        elif method == "GET" and clean_path == "/api/status":
            sensor_data = self.sensors.get_summary()
            device_data = self.devices.get_summary()

            payload = {
                "device": "Smart Home ESP32",
                "online": True,
                "wifi_connected": self.wifi.is_connected,
                "ip_address": self.wifi.ip,
                "uptime": self.get_uptime(),
                "temperature": sensor_data["temperature"],
                "humidity": sensor_data["humidity"],
                "gas_value": sensor_data["gas_value"],
                "gas_status": sensor_data["gas_status"],
                "ldr_value": sensor_data["ldr_value"],
                "light_status": sensor_data["light_status"],
                "rain_status": sensor_data["rain_detected"],
                "rain_detected": sensor_data["rain_detected"],
                "visitor_detected": sensor_data["visitor_detected"],
                "visitor_distance": sensor_data["visitor_distance"],
                "vehicle_status": sensor_data["vehicle_status"],
                "vehicle_distance": sensor_data["vehicle_distance"],
                "servo_angle": device_data["servo_angle"],
                "led_status": device_data["led_active"],
                "buzzer_status": device_data["buzzer_active"],
                "updated_at": sensor_data["updated_at"]
            }
            await self._send_json(writer, 200, payload)

        # GET /api/sensors
        elif method == "GET" and clean_path == "/api/sensors":
            payload = self.sensors.get_summary()
            await self._send_json(writer, 200, payload)

        # GET /api/devices
        elif method == "GET" and clean_path == "/api/devices":
            payload = self.devices.get_summary()
            await self._send_json(writer, 200, payload)

        # GET /api/notifications
        elif method == "GET" and clean_path == "/api/notifications":
            payload = {
                "notifications": self.automation.get_notifications()
            }
            await self._send_json(writer, 200, payload)

        # POST /api/config
        elif method == "POST" and clean_path == "/api/config":
            try:
                body_json = json.loads(body_data.decode("utf-8"))
                updated = update_config(body_json)
                payload = {
                    "success": True,
                    "message": "Konfigurasi threshold berhasil diperbarui",
                    "updated": updated,
                    "current_config": CONFIG
                }
                await self._send_json(writer, 200, payload)
            except Exception as e:
                await self._send_json(writer, 400, {
                    "success": False,
                    "error": "Format JSON tidak valid",
                    "detail": str(e)
                })

        # 404 Not Found
        else:
            await self._send_json(writer, 404, {
                "error": "Not Found",
                "path": path,
                "message": "Endpoint tidak tersedia"
            })

    async def _send_json(self, writer, status_code, data):
        status_text = {
            200: "OK",
            400: "Bad Request",
            404: "Not Found",
            500: "Internal Server Error"
        }.get(status_code, "OK")

        json_bytes = json.dumps(data).encode("utf-8")
        header = (
            "HTTP/1.1 " + str(status_code) + " " + status_text + "\r\n"
            "Content-Type: application/json; charset=utf-8\r\n"
            "Content-Length: " + str(len(json_bytes)) + "\r\n"
            "Access-Control-Allow-Origin: *\r\n"
            "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"
            "Access-Control-Allow-Headers: Content-Type\r\n"
            "Connection: close\r\n\r\n"
        ).encode("utf-8")

        writer.write(header)
        writer.write(json_bytes)
        await writer.drain()

    async def _close_conn(self, writer):
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass

# ==============================================================================
# 7. MAIN ORCHESTRATOR
# ==============================================================================

async def sensor_automation_loop(sensor_mgr, automation_sys):
    print("[Core] Loop otomatisasi sensor aktif.")
    while True:
        try:
            sensor_mgr.read_all()
            automation_sys.process()
        except Exception as e:
            print("[Core] Error pada loop sensor/otomatisasi:", e)

        interval_sec = CONFIG.get("sensor_interval_ms", 1500) / 1000.0
        await asyncio.sleep(interval_sec)

async def memory_maintenance_loop():
    while True:
        await asyncio.sleep(30)
        gc.collect()

async def main():
    print("========================================")
    print("      SMART HOME ESP32 DevKit V1        ")
    print("========================================")

    # 1. Inisialisasi Hardware
    sensor_mgr = SensorManager()
    device_mgr = DeviceManager()
    automation_sys = AutomationSystem(sensor_mgr, device_mgr)

    # 2. Hubungkan Wi-Fi (dengan proteksi agar kegagalan Wi-Fi tidak menghentikan otomatisasi)
    wifi_mgr = WiFiManager()
    try:
        wifi_mgr.connect()
    except Exception as e:
        print("[WiFi] Peringatan koneksi:", e)

    # 3. Jalankan HTTP REST API Server
    api_server = ApiServer(wifi_mgr, sensor_mgr, device_mgr, automation_sys)
    try:
        await api_server.start(port=80)
    except Exception as e:
        print("[HTTP] Server start error:", e)

    # 4. Jalankan seluruh task asinkron
    await asyncio.gather(
        sensor_automation_loop(sensor_mgr, automation_sys),
        wifi_mgr.monitor_loop(),
        memory_maintenance_loop()
    )

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[System] Program dihentikan oleh pengguna.")
    except Exception as e:
        print("\n[Fatal] Error sistem:", e)
