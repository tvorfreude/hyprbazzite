#version 300 es
// Night light for the swaync quick-settings toggle: warms the whole screen by
// scaling blue (and a little green) down. Applied via decoration:screen_shader,
// so it needs no extra package (hyprsunset/gammastep).
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 c = texture(tex, v_texcoord);
    c.rgb *= vec3(1.0, 0.86, 0.68);
    fragColor = c;
}
