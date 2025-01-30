shader_type spatial;

uniform float thickness = 0.1;
uniform float radius = 0.8;

uniform vec4 color : source_color;

void fragment() {
	float outer_radius = radius + thickness * 0.5;
	float inner_radius = radius - thickness * 0.5;
	
	vec2 dist = UV - vec2(0.5);
	float distance_from_center = length(dist);
	
	float transition = 0.001;
	
	float circle_outer = 1.0 - smoothstep(outer_radius - transition, outer_radius + transition, distance_from_center * 2.0);
    float circle_inner = 1.0 - smoothstep(inner_radius - transition, inner_radius + transition, distance_from_center * 2.0);
	ALPHA = circle_outer - circle_inner;
	ALBEDO = vec3(circle_outer - circle_inner) * color.rgb;
}

