# api_server.py - Asynchronous HTTP REST API Web Server for ESP32

import uasyncio as asyncio
import json
import time
from config import CONFIG, update_config

class ApiServer:
    def __init__(self, wifi_mgr, sensor_mgr, device_mgr, automation_sys):
        self.wifi = wifi_mgr
        self.sensors = sensor_mgr
        self.devices = device_mgr
        self.automation = automation_sys
        self.start_time = time.time()
        self.server = None

    def get_uptime(self):
        """Menghitung waktu aktif (uptime) ESP32 dalam detik."""
        return int(time.time() - self.start_time)

    async def start(self, port=80):
        """Memulai HTTP Server asinkron pada port 80."""
        try:
            self.server = await asyncio.start_server(self._handle_client, "0.0.0.0", port)
            print("[HTTP Server] Berjalan pada port " + str(port))
        except Exception as e:
            print("[HTTP Server] Gagal memulai server:", e)

    async def _handle_client(self, reader, writer):
        """Menangani setiap request HTTP dari client aplikasi atau browser."""
        try:
            # 1. Baca baris pertama HTTP request (contoh: GET /api/status HTTP/1.1)
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

            # 2. Baca HTTP headers untuk mencari Content-Length jika method POST
            content_length = 0
            while True:
                header_line = await reader.readline()
                if not header_line or header_line == b"\r\n":
                    break
                h_str = header_line.decode().strip()
                if h_str.lower().startswith("content-length:"):
                    try:
                        content_length = int(h_str.split(":")[1].strip())
                    except Exception:
                        content_length = 0

            # 3. Baca body request jika ada
            body_data = b""
            if content_length > 0:
                body_data = await reader.read(content_length)

            # 4. Routing request
            await self._route_request(writer, method, path, body_data)

        except Exception as e:
            print("[HTTP] Error handling client:", e)
            try:
                await self._send_json(writer, 500, {"error": "Internal Server Error", "detail": str(e)})
            except Exception:
                pass
        finally:
            await self._close_conn(writer)

    async def _route_request(self, writer, method, path, body_data):
        """Mengarahkan request ke handler endpoint yang sesuai."""
        # Pisahkan query parameters jika ada (misal /api/status?v=1)
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

        # GET /api/status
        # Mengembalikan status sistem dan ringkasan telemetri yang kompatibel dengan Flutter
        elif method == "GET" and clean_path == "/api/status":
            sensor_data = self.sensors.get_summary()
            device_data = self.devices.get_summary()

            payload = {
                "device": "Smart Home ESP32",
                "online": True,
                "wifi_connected": self.wifi.is_connected,
                "ip_address": self.wifi.ip,
                "uptime": self.get_uptime(),

                # Telemetri lengkap untuk konsumsi langsung aplikasi Flutter
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

        # Endpoint tidak ditemukan
        else:
            await self._send_json(writer, 404, {
                "error": "Not Found",
                "path": path,
                "message": "Endpoint tidak tersedia"
            })

    async def _send_json(self, writer, status_code, data):
        """Mengirimkan respon HTTP dengan status code dan JSON payload."""
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
        """Menutup koneksi socket dengan aman."""
        try:
            writer.close()
            await writer.wait_closed()
        except Exception:
            pass
