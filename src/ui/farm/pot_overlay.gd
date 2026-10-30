class_name PotOverlay
extends Node2D
## Saksıların üstüne çizilen göstergeler: büyüme ve su çubuğu, susuzluk damlası, hasada hazır halkası.
## Yalnızca okur ve çizer (durum değiştirmez); `FarmView` sahibidir ve her karede yeniden çizim ister.
##
## Uygular: design/game-brief.md, FAZ 2 (evreler, su/ışık geri bildirimi, hasada hazır işareti).

const _BAR_WIDTH: float = 104.0
const _BAR_HEIGHT: float = 6.0
const _GROWTH_Y: float = 164.0
const _WATER_Y: float = 172.0
const _BACK_COLOR: Color = Color(0.03, 0.07, 0.1, 0.85)
const _GROWTH_COLOR: Color = Color(0.45, 0.95, 0.55)
const _READY_COLOR: Color = Color(1.0, 0.85, 0.3)
const _WATER_COLOR: Color = Color(0.3, 0.75, 1.0)
const _THIRST_COLOR: Color = Color(1.0, 0.55, 0.25)
const _RING_RADIUS: float = 70.0

var _view: FarmView


## Çizilecek görünümü bağlar.
func setup(view: FarmView) -> void:
	_view = view


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _view == null:
		return
	var floor_state: FloorState = _view.current_floor_state()
	if floor_state == null:
		return
	var config: FarmConfig = _view.farm_config()
	var seconds: float = float(Time.get_ticks_msec()) / 1000.0
	var pulse: float = 0.5 + 0.5 * sin(seconds * 4.0)
	for pot_index: int in floor_state.pots.size():
		var pot: PotState = floor_state.pots[pot_index]
		if pot.is_empty():
			continue
		var origin: Vector2 = _view.pot_origin(pot_index)
		var bar_x: float = origin.x + (float(FarmTiles.TILE_SIZE) - _BAR_WIDTH) * 0.5
		_draw_bar(Vector2(bar_x, origin.y + _GROWTH_Y), pot.growth, _READY_COLOR if pot.is_mature() else _GROWTH_COLOR)
		var water_color: Color = _WATER_COLOR if pot.water > config.water_growth_threshold + config.water_growth_ramp else _THIRST_COLOR
		_draw_bar(Vector2(bar_x, origin.y + _WATER_Y), pot.water, water_color)
		var base: Vector2 = origin + FarmView.POT_BASE
		if pot.is_mature():
			var ring_color: Color = _READY_COLOR
			ring_color.a = 0.35 + 0.5 * pulse
			draw_arc(base + Vector2(0.0, -70.0), _RING_RADIUS + 6.0 * pulse, 0.0, TAU, 48, ring_color, 4.0, true)
		elif pot.water <= config.water_growth_threshold + config.water_growth_ramp:
			_draw_drop(base + Vector2(0.0, -120.0 - 6.0 * pulse), 0.55 + 0.45 * pulse)


func _draw_bar(position_: Vector2, fraction: float, color: Color) -> void:
	draw_rect(Rect2(position_, Vector2(_BAR_WIDTH, _BAR_HEIGHT)), _BACK_COLOR)
	draw_rect(Rect2(position_, Vector2(_BAR_WIDTH * clampf(fraction, 0.0, 1.0), _BAR_HEIGHT)), color)


## Susuzluk damlası: tepesi sivri, altı yuvarlak.
func _draw_drop(center: Vector2, alpha: float) -> void:
	var color: Color = _THIRST_COLOR
	color.a = alpha
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -22.0), center + Vector2(14.0, 2.0)])
	for i: int in 9:
		var angle: float = lerpf(0.0, PI, float(i) / 8.0)
		points.append(center + Vector2(cos(angle) * 14.0, 2.0 + sin(angle) * 14.0))
	points.append(center + Vector2(-14.0, 2.0))
	draw_colored_polygon(points, color)
