shader_type canvas_item;

uniform vec2 warp_position = vec2(0.5, 0.5);
uniform float warp_radius = 0.2;
uniform float warp_width = 0.05;
uniform float warp_strength = 0.1;
uniform float aberration_strength = 0.002; // tweak for stronger/weaker RGB split
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    screen_uv = vec2(
        (screen_uv.x - 0.5) * SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x,
        screen_uv.y - 0.5
    ) + vec2(0.5, 0.5);

    vec2 warp_vector = screen_uv - warp_position;
    float dist = length(warp_vector);
    vec2 dir = normalize(warp_vector);

    float mask = smoothstep(warp_radius + warp_width, warp_radius, dist)
               * smoothstep(warp_radius - warp_width, warp_radius, dist);

    // Base warped UV
    vec2 warped_uv = mix(SCREEN_UV, screen_uv - dir * warp_strength, mask * warp_strength);

    // Chromatic aberration offsets
    vec2 offset = dir * aberration_strength * (warp_strength * 4.);

    float r = texture(SCREEN_TEXTURE, warped_uv + offset).r;
    float g = texture(SCREEN_TEXTURE, warped_uv).g;
    float b = texture(SCREEN_TEXTURE, warped_uv - offset).b;

    COLOR = vec4(r, g, b, 1.0);
}
