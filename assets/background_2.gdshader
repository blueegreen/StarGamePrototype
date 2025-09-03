shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NOISE_TEXTURE;

uniform int num_points : hint_range(4,64) = 32;
uniform float connect_radius : hint_range(0.0, 0.5) = 0.12;
uniform float line_width : hint_range(0.0, 0.02) = 0.003; // crisp line threshold
uniform float node_size : hint_range(0.0, 0.05) = 0.008;  // crisp node radius
uniform float cluster_strength : hint_range(0.0, 1.0) = 0.15;
uniform float noise_scale1 = 2.0;
uniform float noise_scale2 = 6.0;
uniform vec2 player_uv = vec2(0.5, 0.5);
uniform float player_influence_radius : hint_range(0.0, 1.0) = 0.25;
uniform float player_influence_falloff : hint_range(0.0, 2.0) = 1.6;
uniform vec3 line_color = vec3(0.6, 0.9, 1.0);
uniform vec3 node_color = vec3(1.0, 0.9, 0.6);
uniform float connect_brightness = 1.0;

uniform float map_speed = 0.28;       // vertical fall speed
uniform float map_speed_variation = 0.45; // per-node speed variation scale (0..1)
uniform float time_wiggle = 0.01;     // small local jitter per node (0 to disable)

const vec2 RES = vec2(1920.0, 1080.0);

vec2 hash2(float n) {
	float x = fract(sin(n * 127.1) * 43758.5453);
	float y = fract(sin(n * 311.7) * 96321.3457);
	return vec2(x, y);
}

float sd_segment(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float denom = dot(ba,ba);
	if (denom == 0.0) {
		return length(p - a);
	}
	float h = clamp(dot(pa,ba) / denom, 0.0, 1.0);
	vec2 proj = a + ba * h;
	return length(p - proj);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 base = texture(SCREEN_TEXTURE, uv).rgb;

	vec3 overlay = vec3(0.0);

	// global downward scroll (we only move in Y)
	float global_down = TIME * map_speed;

	for (int i = 0; i < num_points; i++) {
		float fi = float(i) + 0.1234;
		vec2 base_pos = hash2(fi); // 0..1

		// static displacement (clustered map)
		float n1 = texture(NOISE_TEXTURE, fract(base_pos * noise_scale1)).r;
		float n2 = texture(NOISE_TEXTURE, fract(base_pos * noise_scale2)).r;
		vec2 dirnoise = texture(NOISE_TEXTURE, fract(base_pos * (noise_scale1 * 0.7))).rg - vec2(0.5);
		vec2 disp = dirnoise * (n1 * 0.6 + n2 * 0.4) * cluster_strength;

		// per-node speed variation
		vec2 h = hash2(fi * 1.618);
		float speed_scale = 0.6 + h.y * map_speed_variation; // ~0.6 .. 0.6+var

		// simple per-node wiggle (time-based small offset)
		vec2 wig = vec2(0.0);
		if (time_wiggle > 0.0) {
			vec2 tw = vec2(TIME * 0.8, TIME * 0.53);
			vec2 wn = texture(NOISE_TEXTURE, fract(base_pos * (noise_scale1 * 0.9) + tw)).rg - vec2(0.5);
			wig = wn * time_wiggle;
		}

		// compute raw pos: x static, y moves downward with per-node speed_scale
		vec2 p_raw;
		p_raw.x = base_pos.x + disp.x + wig.x;
		p_raw.y = base_pos.y + disp.y + global_down * speed_scale + wig.y;

		// wrapped display pos (loop vertically via fract)
		vec2 p = fract(p_raw);

		// crisp node: step for hard edge
		float dnode = distance(uv, p);
		float node_mask = step(dnode, node_size); // 1.0 inside radius, 0 otherwise

		// player influence (activation)
		float player_to_node = clamp(1.0 - distance(player_uv, p) / player_influence_radius, 0.0, 1.0);
		player_to_node = pow(player_to_node, player_influence_falloff);

		overlay += node_color * node_mask * player_to_node * 1.0;

		// crisp connection from node -> player (hard line)
		if (player_to_node > 0.001) {
			float dseg_p = sd_segment(uv, p, player_uv);
			float mask_p = step(dseg_p, line_width);
			float len_p = distance(p, player_uv);
			float length_fall_p = step(len_p, connect_radius); // only if within connect radius
			vec3 col_p = line_color * connect_brightness;
			overlay += col_p * mask_p * player_to_node * length_fall_p;
		}

		// pairwise crisp connections
		for (int j = i + 1; j < num_points; j++) {
			float fj = float(j) + 0.5678;
			vec2 base_pos_j = hash2(fj);

			float m1 = texture(NOISE_TEXTURE, fract(base_pos_j * noise_scale1)).r;
			float m2 = texture(NOISE_TEXTURE, fract(base_pos_j * noise_scale2)).r;
			vec2 dirnoise_j = texture(NOISE_TEXTURE, fract(base_pos_j * (noise_scale1 * 0.7))).rg - vec2(0.5);
			vec2 disp_j = dirnoise_j * (m1 * 0.6 + m2 * 0.4) * cluster_strength;

			vec2 hj = hash2(fj * 1.618);
			float speed_scale_j = 0.6 + hj.y * map_speed_variation;

			vec2 wig_j = vec2(0.0);
			if (time_wiggle > 0.0) {
				vec2 twj = vec2(TIME * 0.8, TIME * 0.53);
				vec2 wnj = texture(NOISE_TEXTURE, fract(base_pos_j * (noise_scale1 * 0.9) + twj)).rg - vec2(0.5);
				wig_j = wnj * time_wiggle;
			}

			vec2 p_raw_j;
			p_raw_j.x = base_pos_j.x + disp_j.x + wig_j.x;
			p_raw_j.y = base_pos_j.y + disp_j.y + global_down * speed_scale_j + wig_j.y;
			vec2 p_j = fract(p_raw_j);

			float pd = distance(p, p_j);
			if (pd > connect_radius) {
				continue;
			}

			float to_player_i = clamp(1.0 - distance(player_uv, p) / player_influence_radius, 0.0, 1.0);
			float to_player_j = clamp(1.0 - distance(player_uv, p_j) / player_influence_radius, 0.0, 1.0);
			float edge_activation = max(to_player_i, to_player_j);
			edge_activation = pow(edge_activation, player_influence_falloff);
			if (edge_activation < 0.01) {
				continue;
			}

			float dseg = sd_segment(uv, p, p_j);
			float mask = step(dseg, line_width); // crisp line
			float length_ok = step(pd, connect_radius);
			vec3 col = line_color * connect_brightness;

			overlay += col * mask * edge_activation * length_ok;
		}
	}

	vec3 final_col = base + overlay;
	COLOR = vec4(final_col, 1.0);
}
