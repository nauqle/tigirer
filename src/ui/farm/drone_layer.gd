class_name DroneLayer
extends Node2D
## Hasat dronlarını ve üs pedini çizer. Yalnızca okur ve çizer: dronların konumu/durumu `DroneService` ve `DroneAgent`'tadır.
## Konum hücre biriminden (sütun + 0.5, satır + 0.5 = saksı merkezi) ızgara uzayına çevrilir: dron, bitkinin biraz üstünde uçar.
##
## Uygular: design/game-brief.md, FAZ 4 "hasat dronları" (görsel geri bildirim).

const _TILE: float = float(FarmTiles.TILE_SIZE)
## Dronun saksı taban noktasından yukarıdaki uçuş yüksekliği (ızgara pikseli).
const _HOVER: float = 150.0
const _BODY: Color = Color(0.25, 0.95, 0.85)
const _BODY_DARK: Color = Color(0.05, 0.25, 0.3)
const _BLADE: Color = Color(0.85, 1.0, 0.95, 0.75)
const _HARVEST_GLOW: Color = Color(1.0, 0.85, 0.3, 0.55)
const _PAD: Color = Color(0.2, 0.32, 0.42)

## Çizilecek dronlar (FarmView her karede doldurur).
var agents: Array[DroneAgent] = []
## Üs konumu (hücre birimi).
var dock: Vector2 = Vector2(-0.5, 0.2)
## Dron çizimi açık mı (üste hiç dron yokken ped de çizilmez).
var show_dock: bool = false
var reduce_motion: bool = false


func _process(_delta: float) -> void:
	if show_dock or not agents.is_empty():
		queue_redraw()


## Hücre biriminden ızgara uzayına: saksı tabanının `_HOVER` kadar üstü.
static func to_grid(cell_position: Vector2) -> Vector2:
	return Vector2(cell_position.x * _TILE, cell_position.y * 2.0 * _TILE - (_HOVER - FarmView.POT_BASE.y))


func _draw() -> void:
	var seconds: float = float(Time.get_ticks_msec()) / 1000.0
	if show_dock:
		var pad: Vector2 = to_grid(dock) + Vector2(0.0, 34.0)
		draw_rect(Rect2(pad - Vector2(46.0, 7.0), Vector2(92.0, 14.0)), _PAD)
		draw_rect(Rect2(pad - Vector2(46.0, 7.0), Vector2(92.0, 4.0)), Color(0.45, 0.8, 0.9, 0.8))
	for agent: DroneAgent in agents:
		_draw_drone(agent, seconds)


func _draw_drone(agent: DroneAgent, seconds: float) -> void:
	var center: Vector2 = to_grid(agent.position)
	if agent.state == DroneAgent.State.IDLE:
		center = to_grid(agent.position) + Vector2(0.0, 28.0)  # üste kondu
	var bob: float = 0.0 if reduce_motion else sin(seconds * 6.0 + float(agent.get_instance_id() % 7)) * 3.0
	center.y += bob
	draw_ellipse_shadow(center + Vector2(0.0, 40.0))
	if agent.state == DroneAgent.State.HARVESTING:
		draw_circle(center, 30.0, _HARVEST_GLOW)
	draw_circle(center, 15.0, _BODY_DARK)
	draw_circle(center, 12.0, _BODY)
	draw_circle(center + Vector2(0.0, -2.0), 4.0, Color(1, 1, 1, 0.9))
	var spin: float = 0.0 if reduce_motion else seconds * 40.0
	for offset: Vector2 in [Vector2(-22.0, -9.0), Vector2(22.0, -9.0)]:
		draw_line(center, center + offset, _BODY_DARK, 3.0)
		var rotor: Vector2 = center + offset
		var blade: Vector2 = Vector2(cos(spin), sin(spin)) * 13.0
		draw_line(rotor - blade, rotor + blade, _BLADE, 3.0)


func draw_ellipse_shadow(at: Vector2) -> void:
	draw_set_transform(at, 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 14.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
