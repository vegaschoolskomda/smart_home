# device_manager.py - Actuator Control (Servo, Buzzer, LED)

from machine import Pin, PWM
import time
from config import PIN_SERVO, PIN_BUZZER, PIN_LED, CONFIG

class DeviceManager:
    def __init__(self):
        # 1. Inisialisasi LED (GPIO25)
        self.led_pin = Pin(PIN_LED, Pin.OUT)
        self.led_pin.value(0)
        self.led_state = False

        # 2. Inisialisasi Buzzer (GPIO27)
        self.buzzer_pin = Pin(PIN_BUZZER, Pin.OUT)
        self.buzzer_pin.value(0)
        self.buzzer_state = False

        # 3. Inisialisasi Servo PWM (GPIO13 - 50Hz)
        try:
            self.servo_pwm = PWM(Pin(PIN_SERVO), freq=50)
            # Posisikan awal pada 0 derajat
            self.current_servo_angle = CONFIG["servo_angle_open"]
            self._set_servo_duty(self.current_servo_angle)
        except Exception as e:
            print("[Device] Gagal inisialisasi Servo PWM:", e)
            self.servo_pwm = None
            self.current_servo_angle = 0

    def _angle_to_duty_u16(self, angle):
        """
        Konversi sudut (0 - 180 derajat) ke nilai duty 16-bit (0 - 65535) pada frekuensi 50Hz.
        0 derajat   = 0.5 ms -> duty ~1638
        90 derajat  = 1.5 ms -> duty ~4915
        180 derajat = 2.5 ms -> duty ~8192
        """
        clamped_angle = max(0, min(180, angle))
        # Rumus linier pemetaan sudut ke duty_u16
        duty = int(1638 + (clamped_angle / 180.0) * (8192 - 1638))
        return duty

    def _set_servo_duty(self, angle):
        """Mengirimkan sinyal PWM ke servo motor."""
        if self.servo_pwm is not None:
            try:
                duty = self._angle_to_duty_u16(angle)
                self.servo_pwm.duty_u16(duty)
            except Exception as e:
                print("[Servo] Duty error:", e)

    def set_servo_angle(self, angle):
        """Mengubah sudut servo jika berbeda dari posisi saat ini."""
        if self.current_servo_angle != angle:
            print("[Actuator] Memindahkan Servo dari " + str(self.current_servo_angle) + "° ke " + str(angle) + "°")
            self._set_servo_duty(angle)
            self.current_servo_angle = angle
            # Berikan waktu servo mekanik untuk bergerak
            time.sleep_ms(300)

    def set_led(self, state):
        """Menghidupkan (True) atau mematikan (False) LED."""
        self.led_state = bool(state)
        self.led_pin.value(1 if self.led_state else 0)

    def set_buzzer(self, state):
        """Mengaktifkan (True) atau mematikan (False) buzzer alarm."""
        self.buzzer_state = bool(state)
        self.buzzer_pin.value(1 if self.buzzer_state else 0)

    def get_summary(self):
        """Mengembalikan status seluruh aktuator."""
        return {
            "servo_angle": self.current_servo_angle,
            "led_status": "ON" if self.led_state else "OFF",
            "buzzer_status": "ON" if self.buzzer_state else "OFF",
            # Boolean format untuk Flutter
            "led_active": self.led_state,
            "buzzer_active": self.buzzer_state
        }
