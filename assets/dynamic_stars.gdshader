shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float star_threshold = 0.89;
uniform vec2 speed = vec2(.5, .5);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 scaled_speed = vec2(speed.x / 3000., speed.y / 2000.);
	vec3 star_color = texture(noise_texture, mod(UV + scaled_speed * TIME, 1.)).rgb;
	star_color = step(star_threshold, star_color);
	COLOR.rgb = star_color;
	if (star_color.r < 0.9)
		discard;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
