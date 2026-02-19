#version 300 es
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec2 uv = v_texcoord;
    vec4 pix = texture(tex, uv);
    
    // Simple scanline effect
    float scanline = sin(uv.y * 800.0) * 0.04;
    pix.rgb -= scanline;
    
    // Slight color separation (chromatic aberration)
    float offset = 0.001;
    pix.r = texture(tex, vec2(uv.x + offset, uv.y)).r;
    pix.b = texture(tex, vec2(uv.x - offset, uv.y)).b;
    
    // Warm retro tint
    pix.rgb *= vec3(1.05, 1.0, 0.95);
    
    fragColor = vec4(pix.rgb, pix.a);
}
