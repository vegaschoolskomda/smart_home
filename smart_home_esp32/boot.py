# boot.py - ESP32 Boot Initialization
# Smart Home IoT System

import gc
import esp

# Nonaktifkan debug output OS ESP32 agar serial monitor bersih
esp.osdebug(None)

# Aktifkan automatic garbage collection untuk stabilitas memori RAM
gc.enable()
gc.collect()

print("Boot completed. Memory free:", gc.mem_free(), "bytes")
