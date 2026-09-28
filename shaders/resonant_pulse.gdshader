shader_type canvas_item;
// Resonante — brillo resonante para los fragmentos del yo.
// GDScript alimenta el uniform "pulse" en cada beat detectado (0.0 .. 2.0).

uniform vec4 base_color : source_color = vec4(1.0, 0.62, 0.25, 0.92);
uniform float pulse : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	vec3 glow = base_color.rgb * (1.0 + pulse * 1.6);
	COLOR = vec4(glow, base_color.a);
}
