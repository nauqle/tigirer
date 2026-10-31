class_name ProgressRing
extends Control
## Dairesel ilerleme göstergesi (Seed-Dex tamamlanma, hedefler): arka halka + klorofil yay, ortada yüzde. Değer değişince yay
## kayarak ilerler (hareketi azalt: anında). Yalnızca çizer.
##
## Uygular: design/design-language.md, "Bileşenler" (ilerleme halkası).

var ratio: float = 0.0
var ring_color: Color = UiTokens.ACCENT
var thickness: float = 14.0

var _shown: float = 0.0
var _label: Label
var _tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(150.0, 150.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiKit.label("", &"HeadingLabel", false, HORIZONTAL_ALIGNMENT_CENTER)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_label)


## Oranı (0..1) ayarlar; `animate` doğruysa halka kayarak ilerler.
func set_ratio(value: float, animate: bool = true) -> void:
	ratio = clampf(value, 0.0, 1.0)
	_label.text = UiFormat.percent(ratio)
	if _tween != null:
		_tween.kill()
	if animate and not UiMotion.reduce_motion and is_inside_tree():
		_tween = create_tween()
		_tween.tween_method(_set_shown, _shown, ratio, UiTokens.DUR_SLOW * 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_set_shown(ratio)


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - thickness
	draw_arc(center, radius, 0.0, TAU, 64, UiTokens.SURFACE_3, thickness, true)
	if _shown > 0.001:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * _shown, 64, ring_color, thickness, true)
		var tip: Vector2 = center + Vector2.from_angle(-PI * 0.5 + TAU * _shown) * radius
		draw_circle(tip, thickness * 0.5, ring_color)
