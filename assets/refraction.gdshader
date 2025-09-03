shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NOISE_TEXTURE; // add a noise texture
uniform float blur_radius = 4.0;
uniform float halo_strength = 0.02;
uniform float noise_scale = 6.0;
uniform float strength = 0.5;

float luminance(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 col = texture(SCREEN_TEXTURE, uv).rgb;

    // --- 1. Blurred luminance (simple sample ring for now) ---
    float lum = 0.0;
    int samples = 8;
    for (int i = 0; i < samples; i++) {
        float a = 6.2831 * float(i) / float(samples);
        vec2 offset = vec2(cos(a), sin(a)) * blur_radius / vec2(1920., 1080.);
        lum += luminance(texture(SCREEN_TEXTURE, uv + offset).rgb);
    }
    lum /= float(samples);

    // --- 2. Noise perturbation ---
    float n1 = texture(NOISE_TEXTURE, fract(uv * noise_scale + TIME * 0.1)).r;
	float n2 = texture(NOISE_TEXTURE, fract(uv * noise_scale + vec2(5.2, 1.3) + TIME * 0.1)).r;
	vec2 dir = normalize(vec2(n1 - 0.5, n2 - 0.5));
	vec2 shift = dir * lum * halo_strength;


    // --- 3. Chromatic separation ---
    vec3 halo;
    halo.r = texture(SCREEN_TEXTURE, uv + shift * 1.0).r;
    halo.g = texture(SCREEN_TEXTURE, uv + shift * 0.8).g;
    halo.b = texture(SCREEN_TEXTURE, uv + shift * 1.2).b;

    // --- 4. Mix with mask ---
    float mask = smoothstep(0.2, 0.6, lum); // stronger only on bright regions
    vec3 final_col = mix(col, halo, mask * strength);

    COLOR = vec4(final_col, 1.0);
	//COLOR.rgb = vec3(mask * (1.5 - col.r));
	//COLOR = vec4(dir.x, dir.y, 0, 1.);
}
