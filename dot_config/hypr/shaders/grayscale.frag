#version 300 es
precision mediump float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pix = texture(tex, v_texcoord);
    float avg = 0.3 * pix.r + 0.59 * pix.g + 0.11 * pix.b;
    fragColor = vec4(vec3(avg), pix.a);
}
