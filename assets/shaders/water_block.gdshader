// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform sampler2D noise_tex_1 : filter_nearest;
uniform sampler2D noise_tex_2 : filter_nearest;

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	// Called for every vertex the material is visible on.
	vec2 t1 = vec2(1215. + (TIME * 0.1), -1662. + (TIME * 0.145));
	VERTEX.y += texture(noise_tex_1, UV + t1).r * 0.15;
}

void fragment() {
	vec2 t1 = vec2(555. + (TIME * 0.1), -122. + (TIME * 0.225));
	vec2 t2 = vec2(242. - (TIME * 0.16), 9993. + (TIME * 0.145));
	
	vec4 noise_color_1 = texture(noise_tex_1, UV + t1);
	vec4 noise_color_2 = texture(noise_tex_2, UV + t2);
	
	vec2 base_uv = UV;
	
	vec4 albedo_tex = texture(texture_albedo, base_uv + vec2(TIME * 0.15, TIME *0.01));
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
