# sensor_manager.py - Sensor Acquisition Module for ESP32

from machine import Pin, ADC, time_pulse_us
import time
import dht
from config import (
    PIN_DHT, PIN_MQ2, PIN_LDR, PIN_RAIN,
    PIN_US_VISITOR_TRIG, PIN_US_VISITOR_ECHO,
    PIN_US_VEHICLE_TRIG, PIN_US_VEHICLE_ECHO,
    CONFIG
)

class SensorManager:
    def __init__(self):
        # 1. Inisialisasi DHT11 (GPIO4)
        try:
            self.dht_sensor = dht.DHT11(Pin(PIN_DHT))
        except Exception as e:
            print("[Sensor] Gagal inisialisasi DHT11:", e)
            self.dht_sensor = None

        # 2. Inisialisasi MQ-2 Gas ADC (GPIO32)
        # Attenuation 11dB = Rentang tegangan input 0V hingga 3.3V, lebar 12-bit (0-4095)
        self.mq2_adc = ADC(Pin(PIN_MQ2))
        self.mq2_adc.atten(ADC.ATTN_11DB)
        self.mq2_adc.width(ADC.WIDTH_12BIT)

        # 3. Inisialisasi LDR ADC (GPIO35 - Input Only)
        self.ldr_adc = ADC(Pin(PIN_LDR))
        self.ldr_adc.atten(ADC.ATTN_11DB)
        self.ldr_adc.width(ADC.WIDTH_12BIT)

        # 4. Inisialisasi Rain Sensor (GPIO34 - Input Only)
        self.rain_pin = Pin(PIN_RAIN, Pin.IN)

        # 5. Inisialisasi Ultrasonic 1 (Tamu - TRIG 21, ECHO 22)
        self.us_vis_trig = Pin(PIN_US_VISITOR_TRIG, Pin.OUT)
        self.us_vis_echo = Pin(PIN_US_VISITOR_ECHO, Pin.IN)
        self.us_vis_trig.value(0)

        # 6. Inisialisasi Ultrasonic 2 (Kendaraan - TRIG 18, ECHO 19)
        self.us_veh_trig = Pin(PIN_US_VEHICLE_TRIG, Pin.OUT)
        self.us_veh_echo = Pin(PIN_US_VEHICLE_ECHO, Pin.IN)
        self.us_veh_trig.value(0)

        # Cache nilai pembacaan terakhir
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
        """Membaca suhu dan kelembapan dari DHT11."""
        if self.dht_sensor is None:
            return None, None
        try:
            self.dht_sensor.measure()
            temp = float(self.dht_sensor.temperature())
            hum = float(self.dht_sensor.humidity())
            # Validasi batas fisik wajar sensor DHT11
            if 0.0 <= temp <= 50.0 and 20.0 <= hum <= 90.0:
                self.temperature = temp
                self.humidity = hum
                return temp, hum
        except Exception:
            # DHT11 rentan timeout, pertahankan nilai cache atau None jika awal
            pass
        return self.temperature, self.humidity

    def read_mq2(self):
        """Membaca nilai analog ADC MQ-2 (0-4095)."""
        try:
            # Rata-rata 3 sampel untuk meredam noise analog
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
        """Membaca intensitas cahaya dari LDR ADC (0-4095)."""
        try:
            total = 0
            for _ in range(3):
                total += self.ldr_adc.read()
                time.sleep_us(100)
            self.ldr_value = total // 3

            # Evaluasi gelap / terang dengan histeresis
            threshold = CONFIG["ldr_dark_threshold"]
            hysteresis = CONFIG["ldr_hysteresis"]
            if self.ldr_value >= (threshold + hysteresis):
                self.light_status = "DARK"
            elif self.ldr_value <= (threshold - hysteresis):
                self.light_status = "LIGHT"
            # Jika berada di zona histeresis, pertahankan status sebelumnya

            return self.ldr_value, self.light_status
        except Exception as e:
            print("[Sensor] Error LDR:", e)
            return self.ldr_value, self.light_status

    def read_rain(self):
        """Membaca status air hujan dari Rain Sensor Pin."""
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
        """Mengukur jarak HC-SR04 dalam cm dengan pulse duration."""
        try:
            trig_pin.value(0)
            time.sleep_us(2)
            trig_pin.value(1)
            time.sleep_us(10)
            trig_pin.value(0)

            # Timeout 30000 us (~5 meter)
            duration = time_pulse_us(echo_pin, 1, 30000)
            if duration > 0:
                # Kecepatan suara di udara ~343 m/s = 0.0343 cm/us
                distance = (duration * 0.0343) / 2
                if 2.0 <= distance <= 400.0:
                    return round(distance, 1)
            return None
        except Exception:
            return None

    def read_visitor_distance(self):
        """Membaca jarak tamu pada Ultrasonic 1."""
        dist = self._measure_distance(self.us_vis_trig, self.us_vis_echo)
        if dist is not None:
            self.visitor_distance = dist
            self.visitor_detected = (dist <= CONFIG["visitor_distance_cm"])
        return self.visitor_distance, self.visitor_detected

    def read_vehicle_distance(self):
        """Membaca jarak kendaraan pada Ultrasonic 2."""
        dist = self._measure_distance(self.us_veh_trig, self.us_veh_echo)
        if dist is not None:
            self.vehicle_distance = dist
            if dist <= CONFIG["vehicle_distance_cm"]:
                self.vehicle_status = "Ada"
            else:
                self.vehicle_status = "Tidak Ada"
        return self.vehicle_distance, self.vehicle_status

    def read_all(self):
        """Membaca seluruh sensor sekaligus."""
        self.read_dht()
        self.read_mq2()
        self.read_ldr()
        self.read_rain()
        self.read_visitor_distance()
        self.read_vehicle_distance()
        self.last_read_timestamp = time.time()

        return self.get_summary()

    def get_summary(self):
        """Mengembalikan data pembacaan sensor dalam bentuk dictionary."""
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
