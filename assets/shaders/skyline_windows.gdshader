// Gökdelen pencereleri: tek çizim çağrısında yüzlerce pencere, her biri kendi hızında hafifçe titreşir.
// Pencere başına bilgi köşe rengine kodlanır: r = tohum (0..1), g = palet seçimi, b = taban saydamlık.
// `night` gündüz soldurur; `motion` = 0 ise titreşim kapanır (hareketi azalt).
shader_type canvas_item;

uniform vec4 cool : source_color = vec4(0.45, 0.95, 0.8, 1.0);
uniform vec4 warm : source_color = vec4(1.0, 0.82, 0.45, 1.0);
uniform vec4 violet : source_color = vec4(0.7, 0.55, 1.0, 1.0);
uniform float night : hint_range(0.0, 1.0) = 1.0;
uniform float motion : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float seed = COLOR.r;
	float pick = COLOR.g;
	float base = COLOR.b;
	vec4 tint = pick < 0.34 ? cool : (pick < 0.67 ? warm : violet);
	float twinkle = mix(1.0, 0.6 + 0.4 * sin(TIME * (0.5 + seed * 1.7) + seed * 53.0), motion);
	COLOR = vec4(tint.rgb, base * twinkle * night);
}
