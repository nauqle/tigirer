class_name NightBackdrop
extends Control
## Terk edilmiş gökdelenin dışındaki manzara: oyun saatine bağlı gün-gece döngüsü (şafak, gündüz, alacakaranlık, gece), hareket eden
## ay/güneş, yıldızlar, iki katman paralaks siluet, titreşen pencereler, alçak sis, kıvılcım böcekleri ve kenar karartması.
## Süstür: oyun durumuna dokunmaz, fareyi yakalamaz. Gökyüzü en çok yarım saniyede bir yenilenir. Hareketi azalt açıkken paralaks,
## titreşim ve böcekler kapanır (gökyüzü yine döngüyü izler; yavaş ve sakin bir renk geçişidir).
##
## Uygular: design/design-language.md, "Arka plan"; design/game-brief.md, "Art & audio direction".

const _SEED: int = 20240117
## Evre anahtarları: (evre, gökyüzü üstü, gökyüzü altı, gece oranı). 0 = şafak öncesi gece.
const _PHASES: Array[float] = [0.0, 0.16, 0.36, 0.62, 0.8, 1.0]
const _TOP: Array[Color] = [Color("050a09"), Color("12303a"), Color("123037"), Color("1b1233"), Color("050a09"), Color("050a09")]
const _BOTTOM: Array[Color] = [Color("0d211d"), Color("5e5440"), Color("2a5e52"), Color("763c52"), Color("0d211d"), Color("0d211d")]
const _NIGHT: Array[float] = [1.0, 0.5, 0.0, 0.5, 1.0, 1.0]
const _STAR_COUNT: int = 70

var _phase: float = 0.0
var _motion: bool = true
var _stars: PackedVector3Array = PackedVector3Array()
var _orb: TextureRect
var _far: SkylineLayer
var _near: SkylineLayer
var _fog: TextureRect
var _vignette: TextureRect
var _flies: CPUParticles2D
var _drift: Tween


## Evrenin (0..1) gündüz mü olduğu (HUD simgesi bununla aynı kuralı kullanır).
static func is_daytime(phase: float) -> bool:
	return night_factor(phase) < 0.5


## 0 = tam gündüz, 1 = tam gece.
static func night_factor(phase: float) -> float:
	return _lerp_keys(phase, _NIGHT)


## Gökyüzü üst ve alt renkleri.
static func sky_colors(phase: float) -> Array[Color]:
	var result: Array[Color] = [_color_keys(phase, _TOP), _color_keys(phase, _BOTTOM)]
	return result


static func _segment(phase: float) -> int:
	var wrapped: float = clampf(phase, 0.0, 1.0)
	for i: int in range(_PHASES.size() - 1):
		if wrapped <= _PHASES[i + 1]:
			return i
	return _PHASES.size() - 2


static func _t(phase: float, index: int) -> float:
	var span: float = _PHASES[index + 1] - _PHASES[index]
	return clampf((clampf(phase, 0.0, 1.0) - _PHASES[index]) / maxf(span, 0.0001), 0.0, 1.0)


static func _lerp_keys(phase: float, values: Array[float]) -> float:
	var i: int = _segment(phase)
	return lerpf(values[i], values[i + 1], smoothstep(0.0, 1.0, _t(phase, i)))


static func _color_keys(phase: float, values: Array[Color]) -> Color:
	var i: int = _segment(phase)
	return values[i].lerp(values[i + 1], smoothstep(0.0, 1.0, _t(phase, i)))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_stars()
	_orb = _glow_rect(Vector2(260.0, 260.0))
	add_child(_orb)
	_far = _make_layer(Color("0a1814"), 0.5, 0.12, _SEED)
	_near = _make_layer(Color("060d0b"), 0.34, 0.2, _SEED + 99)
	_fog = TextureRect.new()
	_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fog.texture = _vertical_gradient(Color(0.3, 0.55, 0.45, 0.0), Color(0.3, 0.55, 0.45, 0.22))
	_fog.stretch_mode = TextureRect.STRETCH_SCALE
	_fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_fog)
	_flies = _make_fireflies()
	add_child(_flies)
	_vignette = TextureRect.new()
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.texture = _radial_gradient(Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62), 0.55)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_vignette)
	resized.connect(_layout)
	_layout()
	set_phase(_phase)


## Günün evresini (0..1) ayarlar: gökyüzü, ay/güneş, yıldız ve pencere görünümü güncellenir.
func set_phase(phase: float) -> void:
	_phase = clampf(phase, 0.0, 1.0)
	if _orb == null:
		return
	var night: float = night_factor(_phase)
	var daytime: bool = night < 0.5
	_orb.modulate = Color(1.0, 0.88, 0.55, 0.9) if daytime else Color(0.78, 0.9, 1.0, 0.85)
	var edge_fade: float = minf(smoothstep(0.0, 0.07, _phase), smoothstep(1.0, 0.93, _phase))
	_orb.modulate.a *= edge_fade
	_orb.position = Vector2(lerpf(0.1, 0.9, _phase) * size.x - _orb.size.x * 0.5, size.y * 0.2 - sin(_phase * PI) * size.y * 0.09 - _orb.size.y * 0.5)
	_far.set_look(lerpf(0.25, 1.0, night), _motion)
	_near.set_look(lerpf(0.25, 1.0, night), _motion)
	_fog.modulate = Color(1, 1, 1, lerpf(0.55, 1.0, night))
	_flies.modulate.a = lerpf(0.3, 1.0, night)
	queue_redraw()


## Hareketli ögeleri (paralaks, titreşim, böcekler) açar/kapatır.
func set_motion(enabled: bool) -> void:
	_motion = enabled
	if _flies != null:
		_flies.emitting = enabled
	if _drift != null:
		_drift.kill()
		_drift = null
	if enabled and is_inside_tree() and _far != null:
		_drift = create_tween().set_loops()
		_drift.set_parallel(true)
		_drift.tween_property(_far, "position:x", -16.0, 38.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_drift.tween_property(_near, "position:x", -34.0, 38.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_drift.chain().set_parallel(true)
		_drift.tween_property(_far, "position:x", 0.0, 38.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_drift.tween_property(_near, "position:x", 0.0, 38.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	elif _far != null:
		_far.position.x = 0.0
		_near.position.x = 0.0
	set_phase(_phase)


func _draw() -> void:
	var colors: Array[Color] = sky_colors(_phase)
	var corners: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
	draw_polygon(corners, PackedColorArray([colors[0], colors[0], colors[1], colors[1]]))
	var star_alpha: float = smoothstep(0.35, 1.0, night_factor(_phase))
	if star_alpha > 0.01:
		for star: Vector3 in _stars:
			draw_circle(Vector2(star.x * size.x, star.y * size.y * 0.6), star.z, Color(0.85, 0.95, 1.0, star_alpha * 0.8))


func _layout() -> void:
	_far.size = Vector2(size.x + 80.0, size.y)
	_far.position = Vector2(0.0, 0.0)
	_near.size = Vector2(size.x + 80.0, size.y)
	_near.position = Vector2(0.0, 0.0)
	_fog.position = Vector2(0.0, size.y * 0.45)
	_fog.size = Vector2(size.x, size.y * 0.55)
	_vignette.size = size
	_flies.position = size * 0.5
	_flies.emission_rect_extents = size * 0.5
	set_phase(_phase)


func _build_stars() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _SEED
	_stars.clear()
	for i: int in _STAR_COUNT:
		_stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.8, 2.0)))


func _make_layer(color: Color, height_ratio: float, lit_chance: float, seed_value: int) -> SkylineLayer:
	var layer: SkylineLayer = SkylineLayer.new()
	layer.color = color
	layer.height_ratio = height_ratio
	layer.lit_chance = lit_chance
	layer.seed_value = seed_value
	add_child(layer)
	return layer


func _make_fireflies() -> CPUParticles2D:
	var flies: CPUParticles2D = CPUParticles2D.new()
	flies.amount = 26
	flies.lifetime = 7.0
	flies.preprocess = 7.0
	flies.local_coords = true
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(540.0, 960.0)
	flies.direction = Vector2(0.0, -1.0)
	flies.spread = 40.0
	flies.gravity = Vector2.ZERO
	flies.initial_velocity_min = 8.0
	flies.initial_velocity_max = 26.0
	flies.scale_amount_min = 0.16
	flies.scale_amount_max = 0.42
	flies.texture = _radial_gradient(Color(0.65, 1.0, 0.45, 1.0), Color(0.65, 1.0, 0.45, 0.0), 0.5, 64)
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 0.9))
	ramp.add_point(0.75, Color(1, 1, 1, 0.9))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	flies.color_ramp = ramp
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flies.material = additive
	return flies


## Ay/güneş için yumuşak radyal parıltı.
func _glow_rect(rect_size: Vector2) -> TextureRect:
	var glow: TextureRect = TextureRect.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = _radial_gradient(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, 128)
	glow.size = rect_size
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	return glow


static func _radial_gradient(inner: Color, outer: Color, radius: float, texture_size: int = 128) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, inner)
	gradient.set_color(1, outer)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.5 - radius)
	texture.width = texture_size
	texture.height = texture_size
	return texture


static func _vertical_gradient(top: Color, bottom: Color) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, top)
	gradient.set_color(1, bottom)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 4
	texture.height = 256
	return texture
