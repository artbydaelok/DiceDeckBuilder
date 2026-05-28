shader_type spatial;
render_mode unshaded, cull_disabled;


uniform vec3 color : source_color = vec3(1.0);
uniform float alpha = 1.0;
uniform vec2 checker_alpha = vec2(0.3, 0.6);
uniform float checker_size = 1.0;
uniform vec2 checker_offset = vec2(0.0, 0.0);

vec4 get_vector_rotation(vec3 from, vec3 to) {
	float fdott = dot(from, to);

	// quaternion identity
	vec3 axis = vec3(0.0);
	float angle = 1.0;

	if (fdott < 1.0 - 0.01) {
		if (fdott < -(1.0 - 0.01)) {
			axis = normalize(cross(vec3(1.0, 0.0, 0.0), from));
			if (dot(axis, axis) < 0.1) {
				axis = normalize(cross(vec3(0.0, 1.0, 0.0), from));
			}
		    angle = 0.0;
		}
		else {
			axis = cross(from, to);
			angle = 1.0 + fdott;
		}
	}
	return normalize(vec4(axis, angle));
}

vec4 quatmul(vec4 p, vec4 q) {
	vec3 axis = (p.w * q.xyz) + (q.w * p.xyz) + cross(p.xyz, q.xyz);
	float scalar = p.w * q.w - dot(p.xyz, q.xyz);
	return vec4(axis, scalar);
}

vec3 rotate(vec4 vector, vec4 q) {
	vec4 inv_q = vec4(-q.xyz, q.w);
	return quatmul(quatmul(q, vector), inv_q).xyz;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);


	vec4 q = get_vector_rotation(world_normal, vec3(0.0, 1.0, 0.0));
	// Rotate the placement position by q
	vec3 p_rot = rotate(vec4(world_pos, 1.0), q).xyz;

	// Get point s_rot that is on same plane as p_rot but with snapped x and z
	vec3 offset = vec3(checker_offset.x, 0, checker_offset.y);
	vec3 p_rot_offset = p_rot - offset;

	float x = sign(cos((p_rot_offset.x) * TAU / (checker_size * 2.0)));
	float y = sign(cos((p_rot_offset.z) * TAU / (checker_size * 2.0)));

	// Same shader in local space:
	// scale-free basis vectors
	//vec3 right = normalize(MODEL_MATRIX[0].xyz);
	//vec3 up = normalize(MODEL_MATRIX[1].xyz);
	//vec3 back = normalize(MODEL_MATRIX[2].xyz);
	//vec3 origin = MODEL_MATRIX[3].xyz;
	// optional to make this shader work for any surface normal
	//vec3 tangent = abs(dot(world_normal, right)) > 0.9 ? up : right;
	//right = normalize(cross(tangent, world_normal));
	//up = normalize(cross(right, world_normal));
	// Position in rotated-but-not-scaled local space
	//vec3 local;
	//local.x = dot(world_pos - origin, right);
	//local.y = dot(world_pos - origin, up);

	//float x = sign(cos((local.x - checker_offset.x) * TAU / (checker_size * 2.0)));
	//float y = sign(cos((local.y - checker_offset.y) * TAU / (checker_size * 2.0)));

	float center_dist = length(UV*2.0-1.0);

	ALBEDO = color;
	ALPHA = alpha * checker_alpha[int(step(x*y, 0.0))] * sqrt(max(1.0 - center_dist, 0.0));
}
