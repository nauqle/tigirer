// spatial_glass.gdshader
// FloraLab 2.5D çiftlik: çiftliği örten cam. Çok hafif diyagonal parlama şeritleri ve kenar ışığı; `shift` kameranın yatay
// konumuna bağlı kaydırılır, böylece kamera süzülürken yansıma camın üstünde kayar (derinlik ipucu).
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform float shift = 0.0;
uniform vec3 sheen : source_color = vec3(0.75, 1.0, 0.95);
uniform float sheen_alpha : hint_range(0.0, 0.5) = 0.10;
uniform float edge_alpha : hint_range(0.0, 1.0) = 0.35;
uniform float edge_width : hint_range(0.001, 0.2) = 0.02;

void fragment() {
	float band = fract(UV.x * 1.3 + UV.y * 0.55 + shift);
	float streak = smoothstep(0.0, 0.08, band) * (1.0 - smoothstep(0.08, 0.30, band));
	float wide = smoothstep(0.55, 0.62, band) * (1.0 - smoothstep(0.62, 0.78, band));
	float edge = 1.0 - smoothstep(0.0, edge_width, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	ALBEDO = sheen;
	ALPHA = sheen_alpha * (streak + 0.45 * wide) + edge_alpha * edge;
}
