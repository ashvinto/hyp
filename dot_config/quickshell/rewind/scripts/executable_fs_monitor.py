import os
import time
import json
import sys
from datetime import datetime

# Config
WATCH_DIRS = [
    os.path.expanduser("~/.config/hypr"),
    os.path.expanduser("~/.config/quickshell"),
    os.path.expanduser("~/.config/waybar"),
    os.path.expanduser("~/.config/kitty"),
    os.path.expanduser("~/.config/fish"),
    os.path.expanduser("~/.config/nvim"),
    os.path.expanduser("~/.config/foot"),
    os.path.expanduser("~/.config/rofi"),
    os.path.expanduser("~/.config/dunst"),
    os.path.expanduser("~/.local/share/quickshell")
]
HISTORY_FILE = os.path.expanduser("~/.cache/fs_history.json")
MAX_HISTORY = 100

IGNORE_PATTERNS = [
    "/vivaldi/",
    "/google-chrome/",
    "/Code/CachedData/",
    "/Cursor/CachedData/",
    "/Electron/",
    "/.cache/",
    "/.git/",
    "/.log",
    "lockfile",
    "LOCK"
]

def should_ignore(path):
    for pattern in IGNORE_PATTERNS:
        if pattern in path:
            return True
    return False

def get_dir_state(paths):
    state = {}
    for root_path in paths:
        if not os.path.exists(root_path):
            continue
        for root, dirs, files in os.walk(root_path):
            for name in files:
                path = os.path.join(root, name)
                if should_ignore(path):
                    continue
                try:
                    mtime = os.path.getmtime(path)
                    state[path] = mtime
                except FileNotFoundError:
                    pass # File deleted during scan
    return state

def load_history():
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE, 'r') as f:
                return json.load(f)
        except:
            return []
    return []

def save_history(history):
    # Keep only last N entries
    history = history[:MAX_HISTORY]
    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)

def main():
    print(f"Starting FS Monitor on: {WATCH_DIRS}")
    
    # Ensure cache dir exists
    os.makedirs(os.path.dirname(HISTORY_FILE), exist_ok=True)
    
    current_state = get_dir_state(WATCH_DIRS)
    history = load_history()
    
    # Force initial save to ensure file exists
    if not os.path.exists(HISTORY_FILE):
        save_history(history)
    
    while True:
        time.sleep(1) # Scan interval
        
        new_state = get_dir_state(WATCH_DIRS)
        
        # Check for deletions
        for path in list(current_state.keys()):
            if path not in new_state:
                # DELETED
                timestamp = datetime.now().isoformat()
                event = {
                    "time": timestamp,
                    "type": "DELETE",
                    "path": path,
                    "details": "File removed"
                }
                print(f"[DELETE] {path}")
                history.insert(0, event)
                save_history(history)
        
        # Check for modifications / creations
        for path, mtime in new_state.items():
            if path not in current_state:
                # CREATED
                timestamp = datetime.now().isoformat()
                event = {
                    "time": timestamp,
                    "type": "CREATE",
                    "path": path,
                    "details": "File created"
                }
                print(f"[CREATE] {path}")
                history.insert(0, event)
                save_history(history)
            elif mtime != current_state[path]:
                # MODIFIED
                timestamp = datetime.now().isoformat()
                event = {
                    "time": timestamp,
                    "type": "MODIFY",
                    "path": path,
                    "details": "Content changed"
                }
                print(f"[MODIFY] {path}")
                history.insert(0, event)
                save_history(history)
        
        current_state = new_state

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
