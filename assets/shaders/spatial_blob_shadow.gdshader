// spatial_blob_shadow.gdshader
// FloraLab 2.5D çiftlik: saksının rafa düşen yumuşak temas gölgesi. Gerçek gölge haritası yerine ucuz, radyal saydamlık
// (mobilde gölge geçişi yok).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform float darkness : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	float d = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	ALBEDO = vec3(0.0);
	ALPHA = darkness * pow(1.0 - d, 1.6);
}
