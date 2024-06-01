shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, UV);
	COLOR = vec4(0.8, 0.0, 0.0, COLOR.a * 0.5);
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
