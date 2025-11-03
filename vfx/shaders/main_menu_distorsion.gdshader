shader_type canvas_item;

uniform sampler2D noise_tex : source_color, repeat_enable;

void fragment() {
	vec2 time_offset = vec2(TIME * 0.01, TIME * 0.005);
	float noise1 = texture(noise_tex, UV + time_offset).r;
	float noise2 = texture(noise_tex, UV - time_offset).r;
	vec4 final_val = texture(TEXTURE, UV + vec2(noise1, noise2));
	COLOR.rgb = final_val.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
