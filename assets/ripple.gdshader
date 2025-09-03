shader_type canvas_item;

uniform vec2 player_uv = vec2(0.5, 0.5);
uniform vec2 player_velocity = vec2(0.0, 0.0);
uniform float time_scale = 1.0;
uniform float ripple_frequency = 30.0; // wave density
uniform float ripple_speed = 1.5;      // wave propagation speed
uniform float ripple_strength = 0.02;  // distortion strength
uniform int ripple_count = 6;          // how many trailing ripples to emit

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
	uv = vec2(
        (uv.x - 0.5) * SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x,
        uv.y - 0.5
    ) + vec2(0.5, 0.5);
    vec2 tex_uv = uv;

    float t = TIME * time_scale;

    float wave = 0.0;

    // Emit multiple ripple sources behind the player based on velocity
    for (int i = 0; i < ripple_count; i++) {
        // Offset each emission backwards along velocity direction
        float offset = float(i) * 0.1; 
        vec2 source = player_uv - player_velocity * offset;

        // Distance from current pixel to this ripple source
        float d = distance(uv, source);

        // Wave equation: sin(k*d - ωt)
        wave += sin(d * ripple_frequency - (t - offset) * ripple_speed);
    }

    // Normalize interference intensity
    wave /= float(ripple_count);

    // Use wave as distortion for sampling screen
    tex_uv += normalize(uv - player_uv) * wave * ripple_strength;

    COLOR = texture(SCREEN_TEXTURE, tex_uv);
}
