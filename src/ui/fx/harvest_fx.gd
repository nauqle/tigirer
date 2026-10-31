class_name HarvestFx
extends RefCounted
## Geri bildirim efektleri için küçük yardımcılar: parçacık patlaması, yükselen yazı, su sıçraması, halka dalgası ve HUD'a uçan
## kredi sikkeleri. Düğümleri kendi ekler ve işi bitince kendi siler; durum tutmaz. Hareketi azalt: çağıran taraf bu efektleri çağırmaz.
##
## Uygular: design/game-brief.md, FAZ 2 "tatmin edici parçacık/ses efektleri" (ses AudioService'te).
##
## [codeblock]
## HarvestFx.burst(fx_layer, Vector2(300, 400), Color.GOLD, 18)
## HarvestFx.floating_text(fx_layer, "+24", Vector2(300, 400), Color.GOLD, 44, false)
## [/codeblock]

static var _dot_texture: GradientTexture2D


## Genişleyip sönen halka (olgunlaşma, ekim): `_draw` ile bir daire çizgisi.
class RingPulse:
	extends Node2D
	var color: Color = Color.WHITE
	var radius: float = 8.0
	var width: float = 5.0

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, color, width, true)


## `position` noktasında genişleyip sönen halka dalgası.
static func ring(parent: Control, position: Vector2, color: Color, max_radius: float = 90.0) -> void:
	var pulse: RingPulse = RingPulse.new()
	pulse.position = position
	pulse.color = color
	parent.add_child(pulse)
	var tween: Tween = pulse.create_tween()
	tween.set_parallel(true)
	tween.tween_method(func(value: float) -> void:
		pulse.radius = value
		pulse.queue_redraw(), 8.0, max_radius, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(pulse.queue_free)


## Saksıya su sıçraması: aşağı ve yanlara saçılan turkuaz damlalar.
static func water_splash(parent: Control, position: Vector2) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = position
	particles.texture = _get_dot_texture()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.55
	particles.explosiveness = 0.9
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 70.0
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 230.0
	particles.gravity = Vector2(0.0, 760.0)
	particles.scale_amount_min = 0.35
	particles.scale_amount_max = 0.8
	var fade: Gradient = Gradient.new()
	fade.colors = PackedColorArray([Color(UiTokens.AQUA.r, UiTokens.AQUA.g, UiTokens.AQUA.b, 1.0), Color(UiTokens.AQUA.r, UiTokens.AQUA.g, UiTokens.AQUA.b, 0.0)])
	particles.color_ramp = fade
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)


## Kredi sikkeleri `from`'dan `target`'a yay çizerek uçar ve küçülür (kazancın HUD'a aktığı hissi).
static func fly_coins(parent: Control, from: Vector2, target: Vector2, count: int) -> void:
	for i: int in count:
		var coin: TextureRect = UiKit.icon(&"credit", 34.0)
		coin.pivot_offset = Vector2(17.0, 17.0)
		coin.position = from + Vector2(randf_range(-26.0, 26.0), randf_range(-18.0, 18.0)) - Vector2(17.0, 17.0)
		coin.modulate.a = 0.0
		parent.add_child(coin)
		var tween: Tween = coin.create_tween()
		tween.tween_interval(float(i) * 0.06)
		tween.tween_property(coin, "modulate:a", 1.0, 0.08)
		tween.set_parallel(true)
		tween.tween_property(coin, "position", target - Vector2(17.0, 17.0), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(coin, "scale", Vector2.ONE * 0.45, 0.62)
		tween.chain().tween_callback(coin.queue_free)


## `position` noktasında tek seferlik renkli parçacık patlaması (yaprak/kıvılcım). `amount` parçacık sayısı.
static func burst(parent: Control, position: Vector2, color: Color, amount: int) -> void:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.position = position
	particles.texture = _get_dot_texture()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = maxi(amount, 4)
	particles.lifetime = 0.75
	particles.explosiveness = 0.95
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 85.0
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 380.0
	particles.gravity = Vector2(0.0, 640.0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	var fade: Gradient = Gradient.new()
	fade.colors = PackedColorArray([Color(color.r, color.g, color.b, 1.0), Color(color.r, color.g, color.b, 0.0)])
	particles.color_ramp = fade
	parent.add_child(particles)
	particles.finished.connect(particles.queue_free)


## `position` noktasında kısa süre yukarı süzülüp sönen yazı. `still` doğruysa hareketsiz solar (hareketi azalt).
static func floating_text(parent: Control, text: String, position: Vector2, color: Color, font_size: int, still: bool) -> void:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UiFonts.display(UiTokens.WEIGHT_DISPLAY))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 0.95))
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = position - Vector2(60.0, 30.0)
	parent.add_child(label)
	var tween: Tween = label.create_tween()
	if not still:
		tween.set_parallel(true)
		tween.tween_property(label, "position:y", label.position.y - 90.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
		tween.chain().tween_callback(label.queue_free)
	else:
		tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.25)
		tween.tween_callback(label.queue_free)


static func _get_dot_texture() -> GradientTexture2D:
	if _dot_texture == null:
		var gradient: Gradient = Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
		var texture: GradientTexture2D = GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 24
		texture.height = 24
		_dot_texture = texture
	return _dot_texture
