shader_type spatial;

uniform sampler2D albedo_tex : source_color;
uniform float scroll_speed = 0.25;

uniform bool flash = true;

void fragment() {
    if (flash) {
        ALBEDO = vec3(1.0);
    } else {
        vec2 uv = UV;
        uv.y += TIME * scroll_speed;
        ALBEDO = texture(albedo_tex, uv).rgb;
    }
}