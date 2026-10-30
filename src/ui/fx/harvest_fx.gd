class_name HarvestFx
extends RefCounted
## Hasat geri bildirimi için küçük efekt yardımcıları: parçacık patlaması ve yükselen yazı.
## Düğümleri kendi ekler ve işi bitince kendi siler; durum tutmaz.
##
## Uygular: design/game-brief.md, FAZ 2 "tatmin edici parçacık/ses efektleri" (ses AudioService'te).
##
## [codeblock]
## HarvestFx.burst(fx_layer, Vector2(300, 400), Color.GOLD, 18)
## HarvestFx.floating_text(fx_layer, "+24", Vector2(300, 400), Color.GOLD, 44, false)
## [/codeblock]

static var _dot_texture: GradientTexture2D


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
