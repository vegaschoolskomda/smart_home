# wifi_manager.py - Wi-Fi Station Manager with Auto-Reconnect

import network
import time
import uasyncio as asyncio
from config import WIFI_SSID, WIFI_PASSWORD, WIFI_TIMEOUT_SEC, WIFI_RECONNECT_INTERVAL_SEC

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
            # Nonaktifkan AP jika aktif
            try:
                ap = network.WLAN(network.AP_IF)
                if ap.active():
                    ap.active(False)
            except Exception:
                pass

            # Reset bersih interface Station (STA) untuk mengatasi bug "Wifi Internal State Error"
            # saat soft reboot di Thonny IDE
            if self.wlan.active():
                try:
                    self.wlan.disconnect()
                except Exception:
                    pass
                self.wlan.active(False)
                time.sleep_ms(300)

            self.wlan.active(True)
            time.sleep_ms(300)

            if not self.wlan.isconnected():
                self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
                start_time = time.time()

                while not self.wlan.isconnected():
                    elapsed = time.time() - start_time
                    if elapsed > WIFI_TIMEOUT_SEC:
                        print("\n[!] WiFi Connection Timeout (" + str(WIFI_TIMEOUT_SEC) + "s)")
                        print("[!] ESP32 akan tetap menjalankan otomatisasi lokal.")
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
            print("-------------------------")
            return True

        except Exception as e:
            print("\n[WiFi] Peringatan koneksi:", e)
            print("[WiFi] Sensor dan otomatisasi tetap berjalan lokal.")
            self.is_connected = False
            return False

    def check_connection(self):
        """Periksa apakah koneksi aktif dan perbarui status."""
        self.is_connected = self.wlan.isconnected()
        if self.is_connected:
            self.ip = self.wlan.ifconfig()[0]
        else:
            self.ip = "0.0.0.0"
        return self.is_connected

    async def monitor_loop(self):
        """
        Background task asinkron untuk menjaga koneksi Wi-Fi.
        Otomatis reconnect apabila router restart atau sinyal drop,
        tanpa mengganggu jalannya otomatisasi sensor.
        """
        while True:
            if not self.wlan.isconnected():
                self.is_connected = False
                print("[WiFi] Terputus. Mencoba menghubungkan kembali...")
                try:
                    self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
                except Exception as e:
                    print("[WiFi] Reconnect error:", e)

                # Tunggu hingga terhubung atau timeout
                for _ in range(10):
                    if self.wlan.isconnected():
                        self.is_connected = True
                        self.ip = self.wlan.ifconfig()[0]
                        print("[WiFi] Terhubung kembali! IP:", self.ip)
                        break
                    await asyncio.sleep(1)
            else:
                self.is_connected = True

            await asyncio.sleep(WIFI_RECONNECT_INTERVAL_SEC)
