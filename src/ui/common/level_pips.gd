class_name LevelPips
extends Control
## Seviye noktaları: dolu (alınmış) ve boş (alınabilir) küçük daireler. Yükseltme satırlarında "UV 1/2", "Dron 3/4" gibi seviye
## göstergesi; metin yerine şekil. Yalnızca çizer.
##
## Uygular: design/design-language.md, "Bileşenler" (seviye noktaları).

const _DOT: float = 14.0
const _GAP: float = 8.0

var filled: int = 0
var total: int = 0
var color: Color = UiTokens.ACCENT


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## Dolu ve toplam nokta sayısını verir.
func set_levels(filled_count: int, total_count: int, tint: Color = UiTokens.ACCENT) -> void:
	filled = clampi(filled_count, 0, maxi(total_count, 0))
	total = maxi(total_count, 0)
	color = tint
	custom_minimum_size = Vector2(float(total) * (_DOT + _GAP) - _GAP, _DOT + 4.0)
	queue_redraw()


func _draw() -> void:
	for i: int in total:
		var center: Vector2 = Vector2(_DOT * 0.5 + float(i) * (_DOT + _GAP), size.y * 0.5)
		if i < filled:
			draw_circle(center, _DOT * 0.5, color)
		else:
			draw_arc(center, _DOT * 0.5 - 1.5, 0.0, TAU, 20, UiTokens.TEXT_DIM, 2.5, true)
