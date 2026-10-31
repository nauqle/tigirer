class_name PotOverlay
extends Control
## Sahnenin üstüne (ekran uzayında) çizilen göstergeler: büyüme ve su çubuğu, susuzluk damlası, hasada hazır halkası ve ışıltıları.
## Konumlar 3D sahneden izdüşürülür (`FarmStage.project`); boyutlar eski 180 piksellik karo sabitlerinin ekran ölçeğine çevrilmiş halidir,
## böylece göstergeler hep keskin 2D kalır. Renkler `UiTokens` paletinden gelir (renk körlüğü kipinde değişir).
## Yalnızca okur ve çizer (durum değiştirmez); `FarmView` sahibidir ve her karede yeniden çizim ister.
## (Sulama borusundaki akış artık sahnenin borusunda: `spatial_pipe_flow.gdshader`.)
##
## Uygular: design/game-brief.md, FAZ 2 (evreler, su/ışık geri bildirimi, hasada hazır işareti).

const _BAR_WIDTH: float = 104.0
const _BAR_HEIGHT: float = 6.0
## Çubukların saksı ön yüzünde taban noktasından aşağıda duruşu (referans piksel) ve saksının önü (derinlik, karo).
const _GROWTH_BELOW_BASE: float = 48.0
const _WATER_BELOW_BASE: float = 56.0
const _POT_FRONT_Z: float = 0.36
const _BACK_COLOR: Color = Color(0.03, 0.07, 0.06, 0.85)
const _RING_RADIUS: float = 70.0
const _DROP_ABOVE_BASE: float = 120.0

## Palet (renk körlüğü kipi için `FarmView` günceller).
var palette: Dictionary = UiTokens.palette(false)

var _view: FarmView


## Çizilecek görünümü bağlar.
func setup(view: FarmView) -> void:
	_view = view


func _draw() -> void:
	if _view == null:
		return
	var floor_state: FloorState = _view.current_floor_state()
	if floor_state == null:
		return
	var config: FarmConfig = _view.farm_config()
	var stage: FarmStage = _view.stage()
	var scale_: float = _view.tile_scale()
	var seconds: float = float(Time.get_ticks_msec()) / 1000.0
	var reduce_motion: bool = _view.reduce_motion
	var pulse: float = 0.5 + 0.5 * sin(seconds * 4.0) if not reduce_motion else 0.5
	var growth_color: Color = palette["good"] as Color
	var ready_color: Color = palette["gold"] as Color
	var water_color_ok: Color = palette["aqua"] as Color
	var thirst_color: Color = palette["bad"] as Color
	for pot_index: int in floor_state.pots.size():
		var pot: PotState = floor_state.pots[pot_index]
		if pot.is_empty():
			continue
		var base_world: Vector3 = stage.pot_base_world(pot_index)
		var front: Vector2 = stage.project(base_world + Vector3(0.0, 0.0, _POT_FRONT_Z))
		var bar_x: float = front.x - _BAR_WIDTH * 0.5 * scale_
		_draw_bar(Vector2(bar_x, front.y + _GROWTH_BELOW_BASE * scale_), pot.growth, ready_color if pot.is_mature() else growth_color, scale_)
		var water_color: Color = water_color_ok if pot.water > config.water_growth_threshold + config.water_growth_ramp else thirst_color
		_draw_bar(Vector2(bar_x, front.y + _WATER_BELOW_BASE * scale_), pot.water, water_color, scale_)
		var base: Vector2 = _view.pot_local_position(pot_index)
		var middle: Vector2 = _view.plant_center_local(pot_index)
		if pot.is_mature():
			var ring_color: Color = ready_color
			ring_color.a = 0.35 + 0.5 * pulse
			draw_arc(middle, (_RING_RADIUS + 6.0 * pulse) * scale_, 0.0, TAU, 48, ring_color, 4.0 * scale_, true)
			if not reduce_motion:
				_draw_glints(middle, pot_index, seconds, ready_color, scale_)
		elif pot.water <= config.water_growth_threshold + config.water_growth_ramp:
			_draw_drop(base + Vector2(0.0, -(_DROP_ABOVE_BASE + 6.0 * pulse) * scale_), 0.55 + 0.45 * pulse, thirst_color, scale_)


func _draw_bar(position_: Vector2, fraction: float, color: Color, scale_: float) -> void:
	var bar_size: Vector2 = Vector2(_BAR_WIDTH, _BAR_HEIGHT) * scale_
	draw_rect(Rect2(position_, bar_size), _BACK_COLOR)
	draw_rect(Rect2(position_, Vector2(bar_size.x * clampf(fraction, 0.0, 1.0), bar_size.y)), color)


## Susuzluk damlası: tepesi sivri, altı yuvarlak.
func _draw_drop(center: Vector2, alpha: float, tint: Color, scale_: float) -> void:
	var color: Color = tint
	color.a = alpha
	var points: PackedVector2Array = PackedVector2Array([center + Vector2(0.0, -22.0) * scale_, center + Vector2(14.0, 2.0) * scale_])
	for i: int in 9:
		var angle: float = lerpf(0.0, PI, float(i) / 8.0)
		points.append(center + Vector2(cos(angle) * 14.0, 2.0 + sin(angle) * 14.0) * scale_)
	points.append(center + Vector2(-14.0, 2.0) * scale_)
	draw_colored_polygon(points, color)


## Olgun bitkinin çevresinde yanıp sönen dört köşeli küçük ışıltılar.
func _draw_glints(center: Vector2, pot_index: int, seconds: float, color: Color, scale_: float) -> void:
	for i: int in 3:
		var phase: float = seconds * 1.6 + float(pot_index) * 1.7 + float(i) * 2.1
		var strength: float = maxf(sin(phase), 0.0)
		if strength <= 0.05:
			continue
		var angle: float = float(i) * 2.1 + float(pot_index)
		var at: Vector2 = center + Vector2(cos(angle) * 54.0, sin(angle) * 64.0 - 8.0) * scale_
		var size_px: float = 10.0 * strength * scale_
		var tint: Color = color.lightened(0.4)
		tint.a = strength
		draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -size_px), at + Vector2(size_px * 0.3, -size_px * 0.3), at + Vector2(size_px, 0.0), at + Vector2(size_px * 0.3, size_px * 0.3), at + Vector2(0.0, size_px), at + Vector2(-size_px * 0.3, size_px * 0.3), at + Vector2(-size_px, 0.0), at + Vector2(-size_px * 0.3, -size_px * 0.3)]), tint)
