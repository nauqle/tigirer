// spatial_plant_billboard.gdshader
// FloraLab 2.5D çiftlik: ortak bitki atlasının (PlantAtlas) bir hücresini düz bir dörtgene çizer. Bitkinin kendi görünümü
// (genetik renk, parlama, parıltı) atlasta 2D gölgelendiriciyle zaten üretilmiştir; burada yalnızca SAHNENİN ışığı eklenir:
// gece/gündüz tonu ve UV lambasının morumsu ışığı.
//
// Hedef platform: Android, OpenGL ES 3 (Compatibility). Dallanma yok, parça başına 1 doku okuması.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

// Atlas bir ViewportTexture: gösterim (sRGB) değerlerini taşır. Compatibility oluşturucusunda gölgelendirilmemiş (unshaded) ALBEDO
// doğrudan gösterim değeri olarak yazıldığından hiçbir renk uzayı çevirisi yapılmaz: atlastaki renk ekrandaki renktir.
uniform sampler2D atlas : filter_linear;
// Atlasta bu bitkinin hücresi: x, y, genişlik, yükseklik (0..1 doku uzayı).
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
// Gün/gece ton çarpanı.
uniform vec3 tone : source_color = vec3(1.0);
// UV lambasının ışığı: renk ve miktar (0 = lamba yok).
uniform vec3 uv_color : source_color = vec3(0.62, 0.40, 1.0);
uniform float uv_amount : hint_range(0.0, 1.0) = 0.0;
// Genel görünürlük çarpanı (ekimde belirme).
uniform float visibility : hint_range(0.0, 1.0) = 1.0;

// UV ışığının bitkinin tabanındaki en düşük payı (tepede tam).
const float UV_BASE_SHARE = 0.35;
// UV ışığı altında renk çarpanı (hafif morlaşma) ve üst yarıya eklenen mor ışık payı.
const vec3 UV_DARKEN = vec3(0.96, 0.92, 1.04);
const float UV_TINT_GAIN = 0.10;

void fragment() {
	vec2 uv = region.xy + UV * region.zw;
	vec4 tex = texture(atlas, uv);
	vec3 rgb = tex.rgb * tone;
	float top = 1.0 - UV.y;
	float wash = uv_amount * (UV_BASE_SHARE + (1.0 - UV_BASE_SHARE) * top);
	rgb = rgb * mix(vec3(1.0), UV_DARKEN, wash) + uv_color * UV_TINT_GAIN * wash * top;
	ALBEDO = rgb;
	ALPHA = tex.a * visibility;
}
