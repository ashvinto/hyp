#version 300 es
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    pix.r *= 1.000;
    pix.g *= 1.000;
    pix.b *= 1.000;
    fragColor = pix;
}
