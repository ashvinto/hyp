#!/bin/bash
# Advanced Shader Manager for Hyprland
# Usage: ./shader_man.sh dim <0-100> | warm <1000-10000>

STATE_FILE="$HOME/.config/hypr/configs/shader_state.conf"
SHADER_FILE="$HOME/.config/hypr/shaders/composite.frag"
SHADER_DIR="$HOME/.config/hypr/shaders"

mkdir -p "$SHADER_DIR"

# Defaults
DIM_VAL=100   # 100% Brightness
WARM_VAL=6500 # 6500K (Neutral)

# Load State
if [ -f "$STATE_FILE" ]; then
    saved_dim=$(grep "DIM_VAL=" "$STATE_FILE" | cut -d= -f2)
    saved_warm=$(grep "WARM_VAL=" "$STATE_FILE" | cut -d= -f2)
    [ -n "$saved_dim" ] && DIM_VAL=$saved_dim
    [ -n "$saved_warm" ] && WARM_VAL=$saved_warm
fi

# Parse Args
while [[ "$#" -gt 0 ]]; do
    case $1 in
        dim) DIM_VAL="$2"; shift ;;
        warm) WARM_VAL="$2"; shift ;;
    esac
    shift
done

# Save State
echo "DIM_VAL=$DIM_VAL" > "$STATE_FILE"
echo "WARM_VAL=$WARM_VAL" >> "$STATE_FILE"

# --- Logic using AWK ---
RES=$(awk -v d="$DIM_VAL" -v w="$WARM_VAL" 'BEGIN {
    brightness = d / 100.0;
    red = 1.0; green = 1.0; blue = 1.0;
    if (w < 6500) {
        factor = (6500 - w) / 5500.0;
        blue = 1.0 - (factor * 0.6);
        green = 1.0 - (factor * 0.2);
    }
    printf "%.3f %.3f %.3f", red * brightness, green * brightness, blue * brightness
}')

read -r R_FINAL G_FINAL B_FINAL <<< "$RES"

# Validation
[ -z "$R_FINAL" ] && R_FINAL="1.000"
[ -z "$G_FINAL" ] && G_FINAL="1.000"
[ -z "$B_FINAL" ] && B_FINAL="1.000"

# If neutral, disable shader
if [ "$DIM_VAL" -eq 100 ] && [ "$WARM_VAL" -ge 6500 ]; then
    hyprctl keyword decoration:screen_shader ""
    exit 0
fi

# ATOMIC WRITE: Write to temp first, then move
# This prevents Hyprland from reading a half-written file during rapid slider moves
cat <<EOF > "${SHADER_FILE}.tmp"
#version 300 es
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    pix.r *= $R_FINAL;
    pix.g *= $G_FINAL;
    pix.b *= $B_FINAL;
    fragColor = pix;
}
EOF

mv "${SHADER_FILE}.tmp" "$SHADER_FILE"

# Apply
hyprctl keyword decoration:screen_shader "$SHADER_FILE"
