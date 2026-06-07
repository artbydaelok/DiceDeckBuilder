shader_type spatial;
// A green rim sheen, rendered as a material_overlay on top of the enemy mesh.
// Pulses softly so a modified enemy reads as "different" at a glance.
render_mode blend_mix, cull_back, unshaded, depth_draw_opaque;

uniform vec4 poison_color : source_color = vec4(0.4, 1.0, 0.35, 1.0);
uniform float rim_power : hint_range(0.5, 6.0) = 2.5;
uniform float strength : hint_range(0.0, 1.0) = 0.7;
uniform float pulse_speed = 3.0;

void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0), rim_power);
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed);
	ALBEDO = poison_color.rgb;
	ALPHA = clamp(fresnel * strength * pulse, 0.0, 1.0);
}
