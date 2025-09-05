shader_type canvas_item;

uniform float light_height : hint_range(0.0, 1.0) = 0.3;
uniform float radius : hint_range(1.0, 2000.0) = 400.0;
uniform float falloff : hint_range(0.1, 8.0) = 2.0; // controls edge softness

uniform float time_scale = 0.5;
uniform sampler2D colour_spectrum;
uniform sampler2D noise_texture;
varying float noise_map;

vec3 rotate_vec3(vec3 v, float angle, vec3 axis) {
    axis = normalize(axis);
    float cosA = cos(angle);
    float sinA = sin(angle);

    return v * cosA
         + cross(axis, v) * sinA
         + axis * dot(axis, v) * (1.0 - cosA);
}

void fragment() {
	float n1 = texture(noise_texture, fract(UV  + vec2(0., -.5) * TIME * 0.8 * time_scale)).r;
	float n2 = texture(noise_texture, fract(UV + vec2(1., 0.5) * TIME * 1.2 * time_scale)).r;
	noise_map = mix(n1, n2, .5);
	//COLOR.rgb = vec3(mix(n1, n2, n2/n1));
}

void light() {
    vec2 frag_pos = FRAGCOORD.xy;
    vec2 light_pos = LIGHT_POSITION.xy;

    // Distance-based falloff
    float dist = length(frag_pos - light_pos);
    float atten = clamp(1.0 - dist / radius, 0.0, 1.0);
    atten = pow(atten, falloff) * LIGHT_ENERGY;

    // Proper normalized vectors
    vec2 l2d = normalize(light_pos - frag_pos);
    vec3 l = normalize(vec3(l2d, light_height));

    float ndotl = max(dot(NORMAL, l), 0.0);

    vec3 base = COLOR.rgb;
	
	vec3 light_col = LIGHT_COLOR.rgb;
	light_col.r += LIGHT_DIRECTION.x;
	light_col.g -= LIGHT_DIRECTION.y;
	light_col.b += 0.5 * (LIGHT_DIRECTION.x + LIGHT_DIRECTION.y);
	
	float angle = abs(atan(LIGHT_DIRECTION.y / LIGHT_DIRECTION.x));
	vec3 prism_col = texture(colour_spectrum, vec2(angle)).rgb;
	
	vec3 final_col = mix(light_col, prism_col, noise_map);
	
    vec3 lit = base * final_col * ndotl * atten;

    LIGHT = vec4(lit, COLOR.a);
}
