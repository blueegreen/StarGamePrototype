shader_type canvas_item;

uniform sampler2D noise_texture;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float time_scale = 0.;
uniform float refraction_strength = 0.02;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	screen_uv = fract(screen_uv + TIME * time_scale);
	vec3 n1 = texture(noise_texture, screen_uv * 0.9).rgb;
	vec3 n2 = texture(noise_texture, screen_uv * 1.1).rgb;
	vec3 noise_map = pow(mix(n1, n2, .7), vec3(1.4));
	
	vec2 shift = vec2(1., 0.);
	vec3 halo;
    halo.r = texture(SCREEN_TEXTURE, screen_uv + shift * refraction_strength * noise_map.r * 1.0).r;
    halo.g = texture(SCREEN_TEXTURE, screen_uv + shift * refraction_strength * noise_map.r * 0.5).g;
    halo.b = texture(SCREEN_TEXTURE, screen_uv - shift * refraction_strength * noise_map.r * 1.2).b;
	
	vec3 screen_col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 refracted_col = mix(screen_col, halo, length(halo));
	
	COLOR.rgb = refracted_col;
	
	
	
	
	
	
	
	//vec3 noise_map = mix(n1, n2, length(n2));
	//vec2 refracted_uv = fract(screen_uv + vec2(1., 0.) * noise_map.r * refraction_strength);
	//vec3 refracted_screen_col = texture(SCREEN_TEXTURE, refracted_uv).rgb + vec3(pow(noise_map.r, 5.));
	//COLOR = vec4(refracted_screen_col, 1.);
	
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
