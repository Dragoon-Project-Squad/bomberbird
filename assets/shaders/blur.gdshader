shader_type canvas_item;

uniform sampler2D HINT_SCREEN_TEXTURE: hint_screen_texture;
uniform float strength: hint_range(0.0, 10);
void fragment() {
	// Called for every pixel the material is visible on.
	vec4 c = textureLod(HINT_SCREEN_TEXTURE, SCREEN_UV, strength);
	COLOR = c;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
