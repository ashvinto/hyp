import json
import os
import re
import glob

hypr_config = os.path.expanduser("~/.config/hypr/configs/keybinds.conf")
nvim_base = os.path.expanduser("~/.config/nvim")
lazy_base = os.path.expanduser("~/.local/share/nvim/lazy")

binds = []

# 0. Standard Vim Built-ins
vim_builtins = [
    {"keys": ":w", "action": "Save current file", "type": "Built-in"},
    {"keys": ":q", "action": "Quit current window", "type": "Built-in"},
    {"keys": ":wq", "action": "Save and quit", "type": "Built-in"},
    {"keys": ":qa", "action": "Quit all windows", "type": "Built-in"},
    {"keys": "u", "action": "Undo", "type": "Built-in"},
    {"keys": "<C-r>", "action": "Redo", "type": "Built-in"},
    {"keys": "/", "action": "Search forward", "type": "Built-in"},
    {"keys": "?", "action": "Search backward", "type": "Built-in"},
    {"keys": "n", "action": "Next search match", "type": "Built-in"},
    {"keys": "N", "action": "Previous search match", "type": "Built-in"},
    {"keys": "gg", "action": "Go to top of file", "type": "Built-in"},
    {"keys": "G", "action": "Go to bottom of file", "type": "Built-in"},
    {"keys": "v", "action": "Enter Visual mode", "type": "Built-in"},
    {"keys": "<C-v>", "action": "Enter Visual Block mode", "type": "Built-in"},
    {"keys": "V", "action": "Enter Visual Line mode", "type": "Built-in"},
    {"keys": "i", "action": "Enter Insert mode", "type": "Built-in"},
    {"keys": "a", "action": "Append after cursor", "type": "Built-in"},
    {"keys": "o", "action": "Open new line below", "type": "Built-in"},
    {"keys": "O", "action": "Open new line above", "type": "Built-in"},
    {"keys": "x", "action": "Delete character", "type": "Built-in"},
    {"keys": "dd", "action": "Delete line", "type": "Built-in"},
    {"keys": "yy", "action": "Copy (yank) line", "type": "Built-in"},
    {"keys": "p", "action": "Paste after cursor", "type": "Built-in"},
    {"keys": "P", "action": "Paste before cursor", "type": "Built-in"},
]

for b in vim_builtins:
    binds.append({
        "source": "Neovim",
        "keys": b["keys"],
        "action": b["action"],
        "type": b["type"]
    })

# 1. Hyprland Parser
if os.path.exists(hypr_config):
    try:
        with open(hypr_config, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith("bind ="):
                    # bind = MODS, KEY, ACTION, ARGS
                    parts = [p.strip() for p in line[6:].split(',')]
                    if len(parts) >= 3:
                        desc = parts[2]
                        if len(parts) > 3: desc = desc + " " + " ".join(parts[3:])

                        binds.append({
                            "source": "Hyprland",
                            "keys": parts[0] + " + " + parts[1],
                            "action": desc,
                            "type": "WM"
                        })
    except Exception:
        pass

# 2. Neovim Parser (Lua)
nvim_files = []
nvim_files.append(os.path.join(nvim_base, "init.lua"))
nvim_files.extend(glob.glob(os.path.join(nvim_base, "lua/config/*.lua")))
nvim_files.extend(glob.glob(os.path.join(nvim_base, "lua/plugins/*.lua")))

lazyvim_keymaps = os.path.join(lazy_base, "LazyVim/lua/lazyvim/config/keymaps.lua")
if os.path.exists(lazyvim_keymaps):
    nvim_files.append(lazyvim_keymaps)

nvim_files = list(set(nvim_files))

for nvim_config in nvim_files:
    if os.path.exists(nvim_config):
        source = "Neovim"
        if "lazyvim/config/keymaps.lua" in nvim_config:
            source = "LazyVim"
        
        try:
            with open(nvim_config, 'r') as f:
                content = f.read()
                
                # vim.keymap.set / map / LazyVim.safe_keymap_set
                keymap_pattern = r'''(?:vim\.keymap\.set|map|LazyVim\.safe_keymap_set)\s*\(\s*(?:['"](\w*)['"]|(\{[^}]*\}))\s*,\s*['"]([^'"]+)['"]\s*,\s*([^,]+?)\s*(?:,\s*(\{.*?\}))?\s*\)'''
                matches = re.findall(keymap_pattern, content, re.DOTALL)

                for mode, mode_list, key, action, opts in matches:
                    m = mode if mode else (mode_list if mode_list else "?")
                    desc = str(action).strip()
                    if opts and "desc" in opts:
                        desc_match = re.search(r'''desc\s*=\s*['"]([^'"]+)['"]''', opts)
                        if desc_match:
                            desc = desc_match.group(1)
                    
                    if (desc.startswith("'") and desc.endswith("'")) or (desc.startswith('"') and desc.endswith('"')):
                        desc = desc[1:-1]
                    
                    if desc == "which_key_ignore": continue

                    binds.append({
                        "source": source,
                        "keys": key,
                        "action": desc,
                        "type": "Editor (" + m + ")"
                    })
                
                # Toggles
                snacks_matches = re.findall(r'''Snacks\.toggle\.(\w+)[^)]*\)\s*:\s*map\s*\(\s*['"]([^'"]+)['"]\s*\)''', content)
                for name, key in snacks_matches:
                    binds.append({
                        "source": source,
                        "keys": key,
                        "action": "Toggle " + name.replace("_", " ").capitalize(),
                        "type": "Toggle"
                    })

                # lazy.nvim style keys = { ... }
                # More robust pattern for lazy keys
                lazy_key_pattern = r'''\{\s*['"]([^'"]+)['"]\s*,\s*.*?desc\s*=\s*['"]([^'"]+)['"]\s*,?.*?\}'''
                lazy_matches = re.findall(lazy_key_pattern, content, re.DOTALL)
                for key, desc in lazy_matches:
                    binds.append({
                        "source": source,
                        "keys": key,
                        "action": desc,
                        "type": "Plugin"
                    })

        except Exception:
            pass

print(json.dumps(binds))