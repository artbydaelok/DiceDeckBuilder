shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float line_len = 100.0;
uniform vec4 grid_color : source_color;
uniform bool is_perspective = true;
varying vec3 model_pos;
uniform vec3 center_pos;

void vertex() {
	model_pos = VERTEX;
}

void fragment() {
	ALBEDO = grid_color.rgb;
	float relative_center_dis = length(model_pos)/line_len;
	float rel_center_dis_with_min = min(max(relative_center_dis - 0.2, 0.001), 1.0);

	float center_dist = max(1.0, length(model_pos)-(line_len/2.5));

	float dist_with_min = 20.0 * rel_center_dis_with_min;
	if(is_perspective) {
		float rel_eye_dist = max(0.2*length(VERTEX)/log(line_len), 1.0);
		dist_with_min = center_dist * rel_eye_dist; // bigger means more transparent
	}
	ALPHA = clamp(1.0 / (dist_with_min) - 0.2, 0.0, 1.0) * grid_color.a;
}
