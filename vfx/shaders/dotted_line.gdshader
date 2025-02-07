shader_type spatial;
render_mode unshaded;

uniform float dot_size : hint_range(0.0, 1.0) = 0.2;  // Size of each dot (0.0 to 1.0)
uniform float spacing = 2.0;   // Space between dots
uniform float speed = 1.0;
uniform vec4 dot_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Color of the dots
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0); // Transparent background

void fragment() {
    vec2 scaled_uv = UV * spacing; // Ensure the pattern tiles correctly with object scale
	float time_offset = TIME * speed;

    float pattern = fract(scaled_uv.x - time_offset); // Create repeating dots along the X-axis

    // Step function creates dots based on the threshold
    float mask = step(pattern, dot_size);

    // Final color mixing
    vec4 final_color = mix(background_color, dot_color, mask);

    if (final_color.a < 0.1) {
        discard;  // Remove background pixels for transparency
    }

    ALBEDO = final_color.rgb;
	ALPHA = dot_color.a;
}