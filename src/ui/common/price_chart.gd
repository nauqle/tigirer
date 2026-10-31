class_name PriceChart
extends Control
## Mini fiyat grafiği (sparkline): son örneklerden çizgi, altında yumuşak dolgu, nötr çizgisi (1.0) ve son değerde nokta. Aralık
## veriye göre ayarlanır ama nötr çizgiyi her zaman kapsar; böylece yükseliş/düşüş gerçek büyüklüğüyle görünür. Yalnızca çizer.
##
## Uygular: design/design-language.md, "Bileşenler" (grafik); design/game-brief.md, FAZ 3 (dinamik borsa).

## Eksenin en az kapsayacağı sapma (nötr çizginin altı/üstü).
const MIN_SPAN: float = 0.25

var samples: PackedFloat32Array = PackedFloat32Array()
var line_color: Color = UiTokens.ACCENT


## Örnekleri ve çizgi rengini verir.
func set_data(values: PackedFloat32Array, color: Color) -> void:
	samples = values
	line_color = color
	queue_redraw()


## Örnekleri `rect_size` içindeki noktalara çevirir (y aşağı doğru büyür; büyük değer yukarıdadır). Saf fonksiyon: test edilir.
static func points_for(values: PackedFloat32Array, rect_size: Vector2, pad: float = 6.0) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	if values.is_empty():
		return points
	var low: float = minf(1.0 - MIN_SPAN, values[0])
	var high: float = maxf(1.0 + MIN_SPAN, values[0])
	for value: float in values:
		low = minf(low, value)
		high = maxf(high, value)
	var span: float = maxf(high - low, 0.0001)
	var usable: Vector2 = rect_size - Vector2.ONE * pad * 2.0
	for i: int in values.size():
		var x: float = pad if values.size() == 1 else pad + usable.x * float(i) / float(values.size() - 1)
		var y: float = pad + usable.y * (1.0 - (values[i] - low) / span)
		points.append(Vector2(x, y))
	return points


## Nötr (1.0) çizgisinin dikey konumu.
static func neutral_y(values: PackedFloat32Array, rect_size: Vector2, pad: float = 6.0) -> float:
	var extended: PackedFloat32Array = values.duplicate()
	extended.append(1.0)
	var points: PackedVector2Array = points_for(extended, rect_size, pad)
	return points[points.size() - 1].y


func _draw() -> void:
	if samples.size() < 1 or size.x < 4.0:
		return
	var points: PackedVector2Array = points_for(samples, size)
	var baseline: float = neutral_y(samples, size)
	# Nötr çizgi (kesikli)
	var x: float = 0.0
	while x < size.x:
		draw_line(Vector2(x, baseline), Vector2(minf(x + 8.0, size.x), baseline), UiTokens.HAIRLINE_STRONG, 2.0)
		x += 16.0
	if points.size() == 1:
		draw_circle(points[0], 5.0, line_color)
		return
	# Altı yumuşak dolgu
	var fill: PackedVector2Array = points.duplicate()
	fill.append(Vector2(points[points.size() - 1].x, size.y))
	fill.append(Vector2(points[0].x, size.y))
	var colors: PackedColorArray = PackedColorArray()
	for point: Vector2 in points:
		colors.append(UiTokens.with_alpha(line_color, 0.22 * (1.0 - point.y / maxf(size.y, 1.0)) + 0.04))
	colors.append(UiTokens.with_alpha(line_color, 0.0))
	colors.append(UiTokens.with_alpha(line_color, 0.0))
	draw_polygon(fill, colors)
	draw_polyline(points, line_color, 3.5, true)
	var last: Vector2 = points[points.size() - 1]
	draw_circle(last, 8.0, UiTokens.with_alpha(line_color, 0.3))
	draw_circle(last, 4.5, line_color)
