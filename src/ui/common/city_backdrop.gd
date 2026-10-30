class_name CityBackdrop
extends Control
## Terk edilmiş gökdelenin dışındaki gece manzarası: degrade gökyüzü ve ışıklı pencereli bina siluetleri.
## Süstür: oyun durumuna dokunmaz, fareyi yakalamaz. Boyut değişince bir kez çizilir (kare başına değil).
##
## Uygular: design/game-brief.md, "Art & audio direction" (koyu gökdelen arka planı, neon-cyber).

const _SEED: int = 20240117
const _SKY_TOP: Color = Color(0.02, 0.04, 0.10)
const _SKY_BOTTOM: Color = Color(0.05, 0.16, 0.20)
const _FAR_COLOR: Color = Color(0.05, 0.10, 0.16)
const _NEAR_COLOR: Color = Color(0.035, 0.07, 0.11)
const _WINDOW_COLORS: Array[Color] = [Color(0.45, 0.95, 0.85, 0.55), Color(1.0, 0.85, 0.45, 0.45), Color(0.7, 0.55, 1.0, 0.45)]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var colors: PackedColorArray = PackedColorArray([_SKY_TOP, _SKY_TOP, _SKY_BOTTOM, _SKY_BOTTOM])
	var corners: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)])
	draw_polygon(corners, colors)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _SEED
	_draw_layer(rng, _FAR_COLOR, 0.55, 0.12)
	_draw_layer(rng, _NEAR_COLOR, 0.85, 0.2)


func _draw_layer(rng: RandomNumberGenerator, color: Color, height_ratio: float, lit_chance: float) -> void:
	var x: float = -20.0
	while x < size.x + 40.0:
		var width: float = rng.randf_range(80.0, 170.0)
		var height: float = rng.randf_range(0.25, 1.0) * size.y * height_ratio * 0.7
		draw_rect(Rect2(x, size.y - height, width, height), color)
		var window_y: float = size.y - height + 18.0
		while window_y < size.y - 24.0:
			var window_x: float = x + 12.0
			while window_x < x + width - 18.0:
				if rng.randf() < lit_chance:
					draw_rect(Rect2(window_x, window_y, 9.0, 13.0), _WINDOW_COLORS[rng.randi() % _WINDOW_COLORS.size()])
				window_x += 24.0
			window_y += 34.0
		x += width + rng.randf_range(0.0, 20.0)
