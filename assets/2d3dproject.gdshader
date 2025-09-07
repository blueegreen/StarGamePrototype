shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D viewport_texture;

void vertex() {
	VERTEX.y += sqrt((0.707 - distance(UV, vec2(0.5, 0.5)))) * 200.;
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(viewport_texture, UV).rgb;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
