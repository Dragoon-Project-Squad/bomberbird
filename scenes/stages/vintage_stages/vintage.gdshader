shader_type canvas_item;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 tex_color = texture(TEXTURE, UV);
	
	float grey = tex_color.r * 0.5 + tex_color.g * 0.4 + tex_color.b * 0.2;
	
	COLOR = vec4(vec3(grey), tex_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
