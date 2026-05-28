shader_type canvas_item;

uniform vec4 color : source_color;
uniform float theta;
uniform vec4 up_color : source_color;
uniform vec4 down_color : source_color;

float lerp(float val, float a, float b) {
	return a + val*(b-a);
}

vec4 lerp_col(float val, vec4 a, vec4 b) {
	return vec4(lerp(val, a.r, b.r), lerp(val, a.g, b.g), lerp(val, a.b, b.b), lerp(val, a.a, b.a));
}

void fragment() {
	vec2 central_uv = (UV-vec2(0.5,0.5))*2.0;
	central_uv *= 0.5; // fov
	vec3 point = vec3(sin(theta)-cos(theta)*central_uv.y, cos(theta)+sin(theta)*central_uv.y, central_uv.x);
	vec3 on_sphere = normalize(point);
	float angle = acos(on_sphere.y);
	float lerp_val = (angle / PI);
	COLOR = lerp_col(lerp_val, down_color, up_color) * color;
}