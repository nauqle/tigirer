// canvas_plant_tint.gdshader
// FloraLab (FAZ 1). Yazar: proje ekibi. Amaç: gri tonlu bitki parçalarına GENETİK parlama ve parıltı eklemek.
// Genetik RENK `modulate` ile gelir (COLOR); bu gölgelendirici onunla çarpar, üstüne mutasyon etkilerini bindirir.
//
// Hedef platform: Android, OpenGL ES 3 (Godot "Compatibility" oluşturucusu).
// Karmaşıklık bütçesi: parça başına 1 doku okuması, dallanma yok (smoothstep/mix).
// Duyarlık: renk hesabı `mediump`; ZAMANA bağlı hesaplar `highp` (TIME büyür, fp16'da sin() bozulur).
// Varyant yok: tek dosya, tek program. Bitki başına bir ShaderMaterial örneği (parametre farkı için).
shader_type canvas_item;

group_uniforms genetics;
// Mutasyonun parlama rengi ve gücü. 0 = parlama yok (sıradan bitki).
uniform vec4 glow_color : source_color = vec4(0.35, 1.0, 0.8, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.0;
// Yüzeyde gezinen parlak bant yoğunluğu (kristal etkisi). 0 = yok.
uniform float shimmer : hint_range(0.0, 1.0) = 0.0;

group_uniforms animation;
// Bitki başına rastgele evre: tüm bitkiler aynı anda nabız atmasın.
uniform float phase = 0.0;
// Parlama nabzının hızı (radyan/saniye).
uniform float pulse_speed = 2.4;
// Parıltı bandının hızı (doku birimi/saniye).
uniform float shimmer_speed = 0.45;

// Parlamanın, dokunun parlaklığından bağımsız kalan tabanı: koyu yüzeyler de biraz parlasın.
const float GLOW_FLOOR = 0.35;
// Nabzın en düşük ve en yüksek çarpanı: 0.78 +- 0.22.
const float PULSE_MIN = 0.78;
const float PULSE_RANGE = 0.22;
// Parıltı bandı: doku koordinatındaki çapraz eğim ve genişlik (0..1 sarmal içinde).
const vec2 SHIMMER_DIRECTION = vec2(0.9, 0.6);
const float SHIMMER_EDGE = 0.08;
const float SHIMMER_WIDTH = 0.2;
// Parıltının beyaz eklemesinin en büyük şiddeti.
const float SHIMMER_GAIN = 0.55;

void fragment() {
	mediump vec4 tex = texture(TEXTURE, UV);
	// COLOR burada modulate'i (genetik rengi) taşır; doku ile çarpılır.
	mediump vec3 rgb = tex.rgb * COLOR.rgb;

	// Parlama: doku parlaklığıyla ağırlıklı, nabız atan emisyon.
	mediump float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	highp float pulse = PULSE_MIN + PULSE_RANGE * sin(TIME * pulse_speed + phase);
	rgb += glow_color.rgb * glow_strength * pulse * (GLOW_FLOOR + (1.0 - GLOW_FLOOR) * luma);

	// Parıltı: çapraz giden dar bir parlak bant (dallanmasız, smoothstep farkıyla).
	highp float band = fract(dot(UV, SHIMMER_DIRECTION) - TIME * shimmer_speed + phase * 0.1);
	mediump float streak = smoothstep(0.0, SHIMMER_EDGE, band) * (1.0 - smoothstep(SHIMMER_EDGE, SHIMMER_WIDTH, band));
	rgb += vec3(1.0) * shimmer * streak * SHIMMER_GAIN;

	COLOR = vec4(rgb, tex.a * COLOR.a);
}
