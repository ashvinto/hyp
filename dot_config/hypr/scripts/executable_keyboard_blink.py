#!/usr/bin/env python3
import struct
import sys
import os
import subprocess
import threading
import time
import random
import colorsys

# --- Configuration ---
# Device path for your keyboard. 
KEYBOARD_DEV = "/dev/input/event3"

# Brightness Configuration (0.0 to 1.0)
BRIGHTNESS = 0.2  # Set to 20% brightness (Low)

# Colors
COLOR_IDLE = "000033"   # Dim Blue (Blue at low brightness)
IDLE_TIMEOUT = 0.2      # Seconds to wait after last keypress before reverting to idle

# ---------------------

def get_random_color():
    # Generate random Hue (0.0 - 1.0)
    hue = random.random()
    # Convert HSV to RGB with fixed Low Brightness (Value)
    r, g, b = colorsys.hsv_to_rgb(hue, 1.0, BRIGHTNESS)
    return "{:02x}{:02x}{:02x}".format(int(r*255), int(g*255), int(b*255))

def set_color(color):
    try:
        # Fire and forget to avoid blocking the input loop
        subprocess.Popen(["asusctl", "aura", "static", "-c", color], 
                       stdout=subprocess.DEVNULL, 
                       stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"Error setting color: {e}")

class BlinkController:
    def __init__(self):
        self.timer = None
        self.current_state = "idle"
        self.lock = threading.Lock()

    def on_keypress(self):
        with self.lock:
            # Generate a new random dim color for every keypress
            new_color = get_random_color()
            set_color(new_color)
            self.current_state = "typing"
            
            # Reset the idle timer
            if self.timer:
                self.timer.cancel()
            self.timer = threading.Timer(IDLE_TIMEOUT, self.on_idle)
            self.timer.start()

    def on_idle(self):
        with self.lock:
            self.current_state = "idle"
            set_color(COLOR_IDLE)

def main():
    if not os.access(KEYBOARD_DEV, os.R_OK):
        print(f"Permission denied: Cannot read {KEYBOARD_DEV}")
        print("Ensure you are in the 'input' group: sudo usermod -aG input $USER")
        sys.exit(1)

    print(f"Monitoring {KEYBOARD_DEV}...")
    print(f"Idle color: #{COLOR_IDLE} (Low Brightness)")
    print("Press Ctrl+C to stop.")

    # Set initial state
    set_color(COLOR_IDLE)
    
    controller = BlinkController()

    # struct format for input_event on 64-bit Linux:
    # long tv_sec, long tv_usec, unsigned short type, unsigned short code, signed int value
    fmt = 'llHHi'
    event_size = struct.calcsize(fmt)

    try:
        with open(KEYBOARD_DEV, "rb") as f:
            while True:
                data = f.read(event_size)
                if len(data) < event_size:
                    break
                
                tv_sec, tv_usec, type_, code, value = struct.unpack(fmt, data)
                
                # EV_KEY is type 1
                if type_ == 1:
                    if value == 1: # Key Press
                        controller.on_keypress()

    except KeyboardInterrupt:
        print("\nStopping...")
        set_color(COLOR_IDLE) # Revert to idle color on exit

if __name__ == "__main__":
    main()
