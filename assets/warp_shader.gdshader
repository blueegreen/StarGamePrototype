shader_type canvas_item;

uniform float master_strength = 1.;
uniform vec2 warp_position = vec2(0.5, 0.5);
uniform float warp_radius = 0.2;
uniform float warp_width = 0.05;
uniform float warp_strength = 0.1;
uniform float aberration_strength = 0.002;
uniform vec2 light_dir = vec2(1., 0.);
uniform float light_width : hint_range(0.01, .2, 0.01) = 0.01;
uniform float light_strength : hint_range(0., 1., 0.01) = 0.3;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec2 rotate_vec2(vec2 v, float a) {
    mat2 rot = mat2(vec2(cos(a), -sin(a)), vec2(sin(a),  cos(a)));
    return rot * v;
}

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    vec2 scaled_screen_uv = vec2(
        (screen_uv.x - 0.5) * SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x,
        screen_uv.y - 0.5
    ) + vec2(0.5, 0.5);

    vec2 warp_vector = scaled_screen_uv - warp_position;
    float dist = length(warp_vector);
    vec2 dir = normalize(warp_vector);

    float mask = smoothstep(warp_radius + warp_width, warp_radius, dist)
               * smoothstep(warp_radius - warp_width, warp_radius, dist);

	float light_mask = smoothstep(warp_radius + light_width, warp_radius, dist)
               * smoothstep(warp_radius - light_width, warp_radius, dist);


    // Base warped UV
    vec2 warped_uv = mix(SCREEN_UV, scaled_screen_uv - dir * warp_strength, mask * warp_strength);

    vec2 offset = dir * aberration_strength * (warp_strength * 4.);

    float r = texture(SCREEN_TEXTURE, warped_uv + offset).r;
    float g = texture(SCREEN_TEXTURE, warped_uv).g;
    float b = texture(SCREEN_TEXTURE, warped_uv - offset).b;

	vec3 base_col = texture(SCREEN_TEXTURE, screen_uv).rgb;
	float light_intensity = length((normalize(warp_vector) - normalize(light_dir)));
	light_intensity = mix(0., light_intensity, light_mask);

	vec3 warp_col = vec3(r, g, b);
	warp_col = mix(warp_col, warp_col + vec3(light_strength) * light_intensity, mask);

	vec3 final_col = mix(base_col, warp_col, master_strength);

    COLOR = vec4(final_col, 1.0);
	//COLOR.rgb = vec3(light_mask);
}
