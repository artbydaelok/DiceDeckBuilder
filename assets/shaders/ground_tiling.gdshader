shader_type spatial;
render_mode specular_disabled;
// Tiling ground. Repeats an albedo texture + normal map using WORLD-space UVs
// (the XZ plane), so a single quad — or many coplanar tiles sharing this material —
// shows NO seams, and the texel density stays constant no matter how the mesh is
// scaled. Set world_tile_size to how many world units one texture repeat should span.

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform float world_tile_size = 2.0;                       // world units per texture repeat (2 = one game tile)
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform vec2 uv_offset = vec2(0.0, 0.0);                   // optional scroll/alignment offset

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = v_world.xz / world_tile_size + uv_offset;
	ALBEDO = texture(albedo_tex, uv).rgb;
	NORMAL_MAP = texture(normal_tex, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = roughness;
}
