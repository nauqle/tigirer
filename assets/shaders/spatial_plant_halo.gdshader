// spatial_plant_halo.gdshader
// FloraLab 2.5D çiftlik: parlayan (mutasyonlu) bitkinin çevresindeki ışık halesi. Toplamalı karışımla bitkinin ARKASINA
// çizilir; atlasta çizilemez çünkü toplamalı karışım saydam hedefe yazılmaz.
shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(0.35, 1.0, 0.8, 1.0);
// 0 = yok. Genetikteki parlama gücü ve büyümeye göre sahne atar.
uniform float strength : hint_range(0.0, 2.0) = 0.0;
// Bitki başına rastgele evre ve nabız hızı; hareketi azalt açıkken hız 0.
uniform float phase = 0.0;
uniform float pulse_speed = 2.4;

// Nabzın en düşük ve en yüksek çarpanı: 0.78 +- 0.22 (2D gölgelendiriciyle aynı).
const float PULSE_MIN = 0.78;
const float PULSE_RANGE = 0.22;

void fragment() {
	float d = clamp(length(UV - vec2(0.5)) * 2.0, 0.0, 1.0);
	float falloff = pow(1.0 - d, 2.2);
	highp float pulse = PULSE_MIN + PULSE_RANGE * sin(TIME * pulse_speed + phase);
	ALBEDO = glow_color.rgb * strength * pulse;
	ALPHA = falloff;
}
