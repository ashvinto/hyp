#version 300 es
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    pix.r *= 1.000;
    pix.g *= 0.998;
    pix.b *= 0.994;
    fragColor = pix;
}
