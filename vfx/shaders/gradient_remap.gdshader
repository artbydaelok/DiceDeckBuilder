shader_type spatial;

uniform sampler2D tex;
uniform sampler2D gradient;

void fragment() {
	vec4 texture_color = texture(tex, UV);
	float average = (texture_color.r +
					texture_color.g +
					texture_color.b) / 3.0;

	vec2 sample_coords = vec2(average);
	vec4 gradient_color = texture(gradient, sample_coords);

	ALBEDO = gradient_color.rgb;
	ALPHA = texture_color.a;
}
