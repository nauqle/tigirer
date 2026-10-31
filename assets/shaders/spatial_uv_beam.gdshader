// spatial_uv_beam.gdshader
// FloraLab 2.5D çiftlik: UV lambasının aşağı doğru yayılan mor ışık huzmesi. Toplamalı karışım; tepede parlak, dipte yok olur.
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec3 beam_color : source_color = vec3(0.62, 0.40, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Koni ağında UV.y = 0 tepe (lamba), 1 taban.
	float along = 1.0 - UV.y;
	ALBEDO = beam_color * strength * along * along;
	ALPHA = along;
}
