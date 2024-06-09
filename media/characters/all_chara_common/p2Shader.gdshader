shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = texture(TEXTURE, UV);
	COLOR = vec4(COLOR.r, COLOR.g , COLOR.b + 0.7, COLOR.a);
}

void light() {
	// Called for every pixel for every light affecting the CanvasItem.
}
