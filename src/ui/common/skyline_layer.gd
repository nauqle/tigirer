class_name SkylineLayer
extends Control
## Bina siluetleri katmanı (bir kez çizilir, boyut değişince yenilenir) ve üstünde titreşen pencereler. Paralaks için dışarıdan
## kaydırılır. Pencereler tek çizim çağrısında, köşe rengine kodlanmış bilgiyle `skyline_windows` gölgelendiricisinde çizilir.
##
## Uygular: design/design-language.md, "Arka plan" (derinlik katmanları).

const _WINDOW_SHADER: Shader = preload("res://assets/shaders/skyline_windows.gdshader")

## Silüet rengi.
var color: Color = Color(0.05, 0.1, 0.09)
## En yüksek bina, katman yüksekliğinin bu oranı kadardır.
var height_ratio: float = 0.6
## Her pencerenin yanık olma olasılığı.
var lit_chance: float = 0.15
var seed_value: int = 1

var _windows: Control
var _material: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_windows = Control.new()
	_windows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_windows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_material = ShaderMaterial.new()
	_material.shader = _WINDOW_SHADER
	_windows.material = _material
	_windows.draw.connect(_draw_windows)
	add_child(_windows)
	resized.connect(_redraw)


## Gündüz/gece (0..1) ve titreşim.
func set_look(night: float, motion: bool) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("night", night)
	_material.set_shader_parameter("motion", 1.0 if motion else 0.0)


func _redraw() -> void:
	queue_redraw()
	if _windows != null:
		_windows.queue_redraw()


func _draw() -> void:
	for building: Rect2 in _buildings():
		draw_rect(building, color)


func _draw_windows() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	for building: Rect2 in _buildings():
		var window_y: float = building.position.y + 18.0
		while window_y < size.y - 24.0:
			var window_x: float = building.position.x + 12.0
			while window_x < building.end.x - 18.0:
				if rng.randf() < lit_chance:
					_windows.draw_rect(Rect2(window_x, window_y, 9.0, 13.0), Color(rng.randf(), rng.randf(), rng.randf_range(0.35, 0.8), 1.0))
				window_x += 24.0
			window_y += 34.0


## Aynı tohumla her seferinde aynı bina dizisi.
func _buildings() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var x: float = -20.0
	while x < size.x + 40.0:
		var width: float = rng.randf_range(80.0, 170.0)
		var height: float = rng.randf_range(0.3, 1.0) * size.y * height_ratio
		result.append(Rect2(x, size.y - height, width, height))
		x += width + rng.randf_range(0.0, 16.0)
	return result
