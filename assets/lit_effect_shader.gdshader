shader_type canvas_item;

uniform sampler2D diffuse_tex;
uniform sampler2D normal_tex : hint_normal;

void fragment() {
    COLOR = texture(diffuse_tex, UV);
}

void light() {
    vec4 base = texture(diffuse_tex, UV);

    // Sample normal map (range [-1, 1])
    vec3 normal = texture(normal_tex, UV).rgb * 2.0 - 1.0;
    normal = normalize(normal);

    // Light direction (in 2D, z is height)
    vec3 light_dir = normalize(vec3(LIGHT_POSITION, LIGHT_HEIGHT));

    // Simple Lambert shading
    float NdotL = max(dot(normal, light_dir), 0.0);

    // Combine
    vec3 lit_color = base.rgb * LIGHT_COLOR.rgb * NdotL * LIGHT;

    // Write out final color contribution for this light
    LIGHT_COLOR = vec4(lit_color, base.a);
}
