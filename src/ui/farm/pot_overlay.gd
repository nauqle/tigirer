class_name PotOverlay
extends Node2D
## Saksıların üstüne çizilen göstergeler: büyüme ve su çubuğu, susuzluk damlası, hasada hazır halkası ve ışıltıları, sulama
## borularında akan damlacıklar. Renkler `UiTokens` paletinden gelir (renk körlüğü kipinde değişir).
## Yalnızca okur ve çizer (durum değiştirmez); `FarmView` sahibidir ve her karede yeniden çizim ister.
##
## Uygular: design/game-brief.md, FAZ 2 (evreler, su/ışık geri bildirimi, hasada hazır işareti).

const _BAR_WIDTH: float = 104.0
const _BAR_HEIGHT: float = 6.0
const _GROWTH_Y: float = 164.0
const _WATER_Y: float = 172.0
const _BACK_COLOR: Color = Color(0.03, 0.07, 0.06, 0.85)
const _RING_RADIUS: float = 70.0
const _PIPE_Y: float = 142.0
const _FLOW_DOTS: int = 4
const _FLOW_SPEED: float = 70.0

## Hareketi azalt: akış ve ışıltı kapanır (halka sabit çizilir).
var reduce_motion: bool = false
## Palet (renk körlüğü kipi için `FarmView` günceller).
var palette: Dictionary = UiTokens.palette(false)

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
	var pulse: float = 0.5 + 0.5 * sin(seconds * 4.0) if not reduce_motion else 0.5
	var growth_color: Color = palette["good"] as Color
	var ready_color: Color = palette["gold"] as Color
	var water_color_ok: Color = palette["aqua"] as Color
	var thirst_color: Color = palette["bad"] as Color
	if not reduce_motion:
		_draw_pipe_flow(floor_state, water_color_ok, seconds)
	for pot_index: int in floor_state.pots.size():
		var pot: PotState = floor_state.pots[pot_index]
		if pot.is_empty():
			continue
		var origin: Vector2 = _view.pot_origin(pot_index)
		var bar_x: float = origin.x + (float(FarmTiles.TILE_SIZE) - _BAR_WIDTH) * 0.5
		_draw_bar(Vector2(bar_x, origin.y + _GROWTH_Y), pot.growth, ready_color if pot.is_mature() else growth_color)
		var water_color: Color = water_color_ok if pot.water > config.water_growth_threshold + config.water_growth_ramp else thirst_color
		_draw_bar(Vector2(bar_x, origin.y + _WATER_Y), pot.water, water_color)
		var base: Vector2 = origin + FarmView.POT_BASE
		if pot.is_mature():
			var ring_color: Color = ready_color
			ring_color.a = 0.35 + 0.5 * pulse
			draw_arc(base + Vector2(0.0, -70.0), _RING_RADIUS + 6.0 * pulse, 0.0, TAU, 48, ring_color, 4.0, true)
			if not reduce_motion:
				_draw_glints(base + Vector2(0.0, -70.0), pot_index, seconds, ready_color)
		elif pot.water <= config.water_growth_threshold + config.water_growth_ramp:
			_draw_drop(base + Vector2(0.0, -120.0 - 6.0 * pulse), 0.55 + 0.45 * pulse, thirst_color)


func _draw_bar(position_: Vector2, fraction: float, color: Color) -> void:
	draw_rect(Rect2(position_, Vector2(_BAR_WIDTH, _BAR_HEIGHT)), _BACK_COLOR)
	draw_rect(Rect2(position_, Vector2(_BAR_WIDTH * clampf(fraction, 0.0, 1.0), _BAR_HEIGHT)), color)


## Susuzluk damlası: tepesi sivri, altı yuvarlak.
func _draw_drop(center: Vector2, alpha: float, tint: Color) -> void:
	var color: Color = tint
	color.a = alpha
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -22.0), center + Vector2(14.0, 2.0)])
	for i: int in 9:
		var angle: float = lerpf(0.0, PI, float(i) / 8.0)
		points.append(center + Vector2(cos(angle) * 14.0, 2.0 + sin(angle) * 14.0))
	points.append(center + Vector2(-14.0, 2.0))
	draw_colored_polygon(points, color)


## Sulama borusu olan satırlarda soldan sağa akan aydınlık damlacıklar.
func _draw_pipe_flow(floor_state: FloorState, color: Color, seconds: float) -> void:
	var tile: float = float(FarmTiles.TILE_SIZE)
	var width: float = float(floor_state.cols) * tile
	for row: int in floor_state.rows:
		if not floor_state.irrigation_rows[row]:
			continue
		var y: float = float((2 * row + 1)) * tile + _PIPE_Y
		for i: int in _FLOW_DOTS:
			var x: float = fposmod(seconds * _FLOW_SPEED + float(i) * width / float(_FLOW_DOTS), width)
			var local_x: float = fposmod(x, tile)
			if local_x > 46.0 and local_x < 134.0:
				continue  # saksının arkasından geçer: görünmez
			var glow: Color = color
			glow.a = 0.55
			draw_circle(Vector2(x, y), 7.0, glow)
			draw_circle(Vector2(x, y), 3.5, Color(1, 1, 1, 0.9))


## Olgun bitkinin çevresinde yanıp sönen dört köşeli küçük ışıltılar.
func _draw_glints(center: Vector2, pot_index: int, seconds: float, color: Color) -> void:
	for i: int in 3:
		var phase: float = seconds * 1.6 + float(pot_index) * 1.7 + float(i) * 2.1
		var strength: float = maxf(sin(phase), 0.0)
		if strength <= 0.05:
			continue
		var angle: float = float(i) * 2.1 + float(pot_index)
		var at: Vector2 = center + Vector2(cos(angle) * 54.0, sin(angle) * 64.0 - 8.0)
		var size_px: float = 10.0 * strength
		var tint: Color = color.lightened(0.4)
		tint.a = strength
		draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size_px), at + Vector2(size_px * 0.3, -size_px * 0.3), at + Vector2(size_px, 0.0), at + Vector2(size_px * 0.3, size_px * 0.3), at + Vector2(0.0, size_px), at + Vector2(-size_px * 0.3, size_px * 0.3), at + Vector2(-size_px, 0.0), at + Vector2(-size_px * 0.3, -size_px * 0.3)]), tint)
