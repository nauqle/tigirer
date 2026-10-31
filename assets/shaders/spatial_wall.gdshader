// spatial_wall.gdshader
// FloraLab 2.5D çiftlik: arka duvar. Koyu yeşil-lacivert paneller, ince derz çizgileri ve alttan üste hafif aydınlanma.
// Işıktan etkilenir (UV lambaları duvarda mor ışık havuzu bırakır); `tone` gece/gündüz çarpanıdır.
shader_type spatial;
render_mode cull_back;

uniform vec2 tiles = vec2(7.0, 4.0);
uniform vec3 base_dark : source_color = vec3(0.07, 0.15, 0.15);
uniform vec3 base_light : source_color = vec3(0.13, 0.25, 0.24);
uniform vec3 seam : source_color = vec3(0.16, 0.42, 0.40);
uniform vec3 tone : source_color = vec3(1.0);

// Derzin kalınlığı (panel birimi) ve parlaklığı.
const float SEAM_WIDTH = 0.018;
const float SEAM_GLOW = 0.55;

void fragment() {
	vec2 g = fract(UV * tiles);
	vec2 edge = min(g, 1.0 - g);
	float line = 1.0 - smoothstep(0.0, SEAM_WIDTH * 2.0, min(edge.x * tiles.y / tiles.x, edge.y));
	// Ortası biraz aydınlık, kenarları koyu: sahneye derinlik verir.
	float vignette = 1.0 - smoothstep(0.35, 0.95, length((UV - vec2(0.5)) * vec2(1.0, 0.8)));
	vec3 panel = mix(base_dark, base_light, UV.y) * (0.75 + 0.55 * vignette) * tone;
	ALBEDO = panel + seam * line * SEAM_GLOW * 0.7 * tone;
	ROUGHNESS = 0.85;
	METALLIC = 0.1;
}
