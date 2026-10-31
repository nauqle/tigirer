class_name ToggleSwitch
extends Control
## Açma/kapama anahtarı: yuvarlak topuz yaylanarak kayar, iz klorofil rengine döner. Dokunma hedefi satırın tamamıdır
## (`SettingRow` satırı da tıklanınca anahtarı çevirir). Hareketi azalt açıkken anında geçer.
##
## Uygular: design/design-language.md, "Bileşenler" (anahtar).

## Değer değişti (kullanıcı dokunuşuyla).
signal toggled(value: bool)

const _SIZE: Vector2 = Vector2(116.0, 64.0)
const _PAD: float = 7.0

var value: bool = false
var _t: float = 0.0
var _tween: Tween


func _init() -> void:
	custom_minimum_size = _SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


## Değeri ayarlar (olay yayınlamaz); `animate` doğruysa kayarak geçer.
func set_value(new_value: bool, animate: bool = true) -> void:
	value = new_value
	var target: float = 1.0 if value else 0.0
	if _tween != null:
		_tween.kill()
	if animate and not UiMotion.reduce_motion and is_inside_tree():
		_tween = create_tween()
		_tween.tween_method(_set_t, _t, target, UiTokens.DUR_BASE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_set_t(target)


func _set_t(new_t: float) -> void:
	_t = new_t
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if tapped:
		flip()
		accept_event()


## Değeri çevirir ve olay yayınlar.
func flip() -> void:
	set_value(not value, true)
	SignalBus.ui_tapped.emit()
	toggled.emit(value)


func _draw() -> void:
	var radius: float = size.y * 0.5
	var track_color: Color = UiTokens.SURFACE_4.lerp(UiTokens.ACCENT, clampf(_t, 0.0, 1.0))
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = UiTokens.with_alpha(track_color, lerpf(1.0, 0.9, _t))
	track.set_corner_radius_all(int(radius))
	draw_style_box(track, Rect2(Vector2.ZERO, size))
	var knob_radius: float = radius - _PAD
	var travel: float = size.x - size.y
	var center: Vector2 = Vector2(radius + travel * _t, radius)
	draw_circle(center + Vector2(0.0, 2.0), knob_radius, Color(0, 0, 0, 0.3))
	draw_circle(center, knob_radius, UiTokens.TEXT.lerp(UiTokens.ACCENT_DARK, clampf(_t, 0.0, 1.0)))
