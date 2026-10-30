class_name FarmView
extends Control
## Bir katın hidroponik ızgarasını çizer ve dokunuşu "niyet" sinyallerine çevirir. TileMapLayer zemini/boruları/lambaları,
## PlantInstance bitkileri, PotOverlay göstergeleri ve hasat efektlerini taşır.
## OYUN DURUMUNU DEĞİŞTİRMEZ: yalnızca `FarmService`'i okur; ekim/sulama/hasat isteklerini sinyalle bildirir,
## kararı ve değişikliği sahibi (GameSession) yapar. Sesi kendisi çalmaz (AudioService SignalBus'tan dinler).
##
## Uygular: design/game-brief.md, FAZ 2 (hidroponik ızgara, kaydırarak toplu hasat, ASMR geri bildirimi).
##
## Dokunuş: kısa dokunuş = `pot_tapped`; parmağı sürükleme = kaydırma, değdiği olgun bitkiler için `harvest_requested`.
## [codeblock]
## farm_view.setup(farm_service, ruleset)
## farm_view.pot_tapped.connect(_on_pot_tapped)
## farm_view.harvest_requested.connect(_on_harvest_requested)
## farm_view.show_floor(0)
## [/codeblock]

## Bir saksıya kısa dokunuldu.
signal pot_tapped(floor_index: int, pot_index: int)
## Parmak sürüklenmeye başladı (yeni bir kombo zinciri).
signal swipe_started
## Kaydırma, bu olgun bitkinin üzerinden geçti: hasat istenir.
signal harvest_requested(floor_index: int, pot_index: int)
## Parmak kalktı, kaydırma bitti.
signal swipe_ended

const PLANT_SCENE: PackedScene = preload("res://src/gameplay/plants/plant_instance.tscn")
## Saksı karosu içinde bitkinin tabanı (karonun sol üstüne göre).
const POT_BASE: Vector2 = Vector2(90.0, 116.0)
const PLANT_SCALE: float = 0.5
## Kaydırmanın bitkiye "değdiği" dikdörtgenin yarım genişliği, tabanın üstü ve altı (ızgara uzayında piksel).
const HIT_HALF_WIDTH: float = 62.0
const HIT_ABOVE: float = 210.0
const HIT_BELOW: float = 70.0
## Dokunuşun kaydırma sayılması için gereken en az sürükleme (piksel).
const TAP_SLOP: float = 16.0
## Izgaranın iki yanındaki süs karoları (sütun sayısı).
const MARGIN_TILES: int = 1
const MAX_FIT_SCALE: float = 1.25
const _TRAIL_SECONDS: float = 0.22
const _TRAIL_MAX_POINTS: int = 28
const _GOLD: Color = Color(1.0, 0.86, 0.35)

## Hareketi azalt: salınım, parçacık ve iz kapanır (erişilebilirlik).
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_apply_motion_setting()

var _farm: FarmService
var _ruleset: GeneticsRuleset
var _floor_index: int = 0
var _grid_root: Node2D
var _tiles: TileMapLayer
var _overlay: PotOverlay
var _drone_layer: DroneLayer
var _drones: DroneService
var _plants: Array[PlantInstance] = []
var _tile_cache: PackedInt32Array = PackedInt32Array()
var _fx_layer: Control
var _trail: Line2D
var _trail_times: PackedFloat32Array = PackedFloat32Array()
var _pressing: bool = false
var _swiping: bool = false
## Bu kaydırmada hasadı istenmiş saksılar (indeks -> true).
var _requested_pots: Dictionary = {}
var _press_position: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_grid_root = Node2D.new()
	add_child(_grid_root)
	_tiles = TileMapLayer.new()
	_tiles.tile_set = FarmTiles.make_tile_set()
	_grid_root.add_child(_tiles)
	_overlay = PotOverlay.new()
	_overlay.setup(self)
	_grid_root.add_child(_overlay)
	_drone_layer = DroneLayer.new()
	_grid_root.add_child(_drone_layer)
	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fx_layer)
	_trail = _make_trail()
	_fx_layer.add_child(_trail)
	resized.connect(_fit)
	_fit()


## Çiftlik servisini ve kural setini bağlar; hasat efektleri için `harvested` sinyalini dinler.
func setup(farm: FarmService, ruleset: GeneticsRuleset) -> void:
	_farm = farm
	_ruleset = ruleset
	_farm.harvested.connect(_on_harvested)


## Dron servisini bağlar: kattaki dronlar ve üs çizilir (salt okunur).
func setup_drones(drone_service: DroneService) -> void:
	_drones = drone_service
	_drone_layer.dock = _drones.config.dock_position


## Gösterilecek katı seçer ve ızgarayı yeniden kurar.
func show_floor(floor_index: int) -> void:
	_floor_index = floor_index
	_rebuild()


## Gösterilen katın durumu (salt okunur kullanım); yoksa null.
func current_floor_state() -> FloorState:
	if _farm == null:
		return null
	return _farm.get_floor(_floor_index)


## Çiftlik yapılandırması (göstergelerin eşikleri için).
func farm_config() -> FarmConfig:
	return _farm.config


## Saksı karosunun ızgara uzayındaki sol üst köşesi.
func pot_origin(pot_index: int) -> Vector2:
	var floor_state: FloorState = current_floor_state()
	return Vector2(float(floor_state.col_of(pot_index) * FarmTiles.TILE_SIZE), float((2 * floor_state.row_of(pot_index) + 1) * FarmTiles.TILE_SIZE))


## Saksıdaki bitki tabanının bu denetimin yerel koordinatındaki yeri (efektler ve dron hedefleri için).
func pot_local_position(pot_index: int) -> Vector2:
	return _grid_root.position + (pot_origin(pot_index) + POT_BASE) * _grid_root.scale.x


## Izgara kök düğümü (dron gibi ek katmanlar bunun altına eklenir).
func grid_root() -> Node2D:
	return _grid_root


func _process(_delta: float) -> void:
	if _farm == null or current_floor_state() == null:
		return
	_sync_plants()
	_sync_tiles()
	_update_trail()
	if _drones != null:
		_drone_layer.agents = _drones.agents_for_floor(_floor_index)
		_drone_layer.show_dock = current_floor_state().drones > 0


# ------------------------------------------------------------------ kurulum


func _rebuild() -> void:
	for plant: PlantInstance in _plants:
		plant.queue_free()
	_plants.clear()
	_tiles.clear()
	_tile_cache = PackedInt32Array()
	var floor_state: FloorState = current_floor_state()
	if floor_state == null:
		return
	for row: int in floor_state.rows:
		for col: int in range(-MARGIN_TILES, floor_state.cols + MARGIN_TILES):
			_tiles.set_cell(Vector2i(col, 2 * row), 0, FarmTiles.atlas_coords(FarmTiles.FLOOR))
			if col < 0 or col >= floor_state.cols:
				_tiles.set_cell(Vector2i(col, 2 * row + 1), 0, FarmTiles.atlas_coords(FarmTiles.FLOOR))
	_tile_cache.resize(floor_state.pots.size() + floor_state.rows)
	_tile_cache.fill(-1)
	for pot_index: int in floor_state.pots.size():
		var plant: PlantInstance = PLANT_SCENE.instantiate() as PlantInstance
		plant.ruleset = _ruleset
		plant.sway_enabled = not reduce_motion
		plant.position = pot_origin(pot_index) + POT_BASE
		plant.scale = Vector2.ONE * PLANT_SCALE
		_grid_root.add_child(plant)
		_plants.append(plant)
	_grid_root.move_child(_overlay, _grid_root.get_child_count() - 1)
	_grid_root.move_child(_drone_layer, _grid_root.get_child_count() - 1)
	_fit()
	_sync_tiles()
	_sync_plants()


func _fit() -> void:
	if _grid_root == null:
		return
	var floor_state: FloorState = current_floor_state()
	if floor_state == null:
		return
	var tile: float = float(FarmTiles.TILE_SIZE)
	var grid_width: float = float(floor_state.cols + 2 * MARGIN_TILES) * tile
	var grid_height: float = float(floor_state.rows * 2) * tile
	var fit_scale: float = minf(minf(size.x / grid_width, size.y / grid_height), MAX_FIT_SCALE)
	fit_scale = maxf(fit_scale, 0.05)
	_grid_root.scale = Vector2.ONE * fit_scale
	_grid_root.position = Vector2((size.x - grid_width * fit_scale) * 0.5 + float(MARGIN_TILES) * tile * fit_scale, (size.y - grid_height * fit_scale) * 0.5)


func _apply_motion_setting() -> void:
	for plant: PlantInstance in _plants:
		plant.sway_enabled = not reduce_motion
	if _trail != null:
		_trail.visible = not reduce_motion
	if _drone_layer != null:
		_drone_layer.reduce_motion = reduce_motion


func _make_trail() -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = 14.0
	line.default_color = Color(0.65, 1.0, 0.9, 0.85)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var curve: Curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.05))
	curve.add_point(Vector2(1.0, 1.0))
	line.width_curve = curve
	return line


# --------------------------------------------------------------- eşzamanlama


func _sync_plants() -> void:
	var floor_state: FloorState = current_floor_state()
	for pot_index: int in mini(_plants.size(), floor_state.pots.size()):
		var pot: PotState = floor_state.pots[pot_index]
		var plant: PlantInstance = _plants[pot_index]
		if plant.gene != pot.gene:
			plant.gene = pot.gene
		if absf(plant.growth - pot.growth) > 0.002 or (pot.is_empty() and plant.growth != 0.0):
			plant.growth = pot.growth


func _sync_tiles() -> void:
	var floor_state: FloorState = current_floor_state()
	var config: FarmConfig = _farm.config
	var wet_level: float = config.water_growth_threshold + config.water_growth_ramp
	for pot_index: int in floor_state.pots.size():
		var row: int = floor_state.row_of(pot_index)
		var wet: bool = floor_state.pots[pot_index].water > wet_level
		var tile: int = FarmTiles.pot_tile(wet, floor_state.irrigation_rows[row])
		if _tile_cache[pot_index] != tile:
			_tile_cache[pot_index] = tile
			_tiles.set_cell(Vector2i(floor_state.col_of(pot_index), 2 * row + 1), 0, FarmTiles.atlas_coords(tile))
	for row: int in floor_state.rows:
		var lamp_tile: int = FarmTiles.LAMP if floor_state.uv_rows[row] > 0 else FarmTiles.FLOOR
		if _tile_cache[floor_state.pots.size() + row] != lamp_tile:
			_tile_cache[floor_state.pots.size() + row] = lamp_tile
			for col: int in floor_state.cols:
				_tiles.set_cell(Vector2i(col, 2 * row), 0, FarmTiles.atlas_coords(lamp_tile))


# ------------------------------------------------------------------- girdi


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			_begin_press(button.position)
		else:
			_end_press(button.position)
		accept_event()
	elif event is InputEventMouseMotion and _pressing:
		_move_press((event as InputEventMouseMotion).position)
		accept_event()


func _begin_press(position_: Vector2) -> void:
	_pressing = true
	_swiping = false
	_requested_pots.clear()
	_press_position = position_
	_last_position = position_
	_trail.clear_points()
	_trail_times = PackedFloat32Array()


func _move_press(position_: Vector2) -> void:
	if not _swiping:
		if position_.distance_to(_press_position) <= TAP_SLOP:
			return
		_swiping = true
		swipe_started.emit()
		_check_swipe_segment(_press_position, position_)
	else:
		_check_swipe_segment(_last_position, position_)
	_add_trail_point(position_)
	_last_position = position_


func _end_press(position_: Vector2) -> void:
	if not _pressing:
		return
	_pressing = false
	if _swiping:
		_swiping = false
		swipe_ended.emit()
		return
	var pot_index: int = _pot_at(_to_grid(position_))
	if pot_index >= 0:
		pot_tapped.emit(_floor_index, pot_index)


func _to_grid(local_position: Vector2) -> Vector2:
	return (local_position - _grid_root.position) / _grid_root.scale.x


## Izgara uzayındaki bir nokta hangi saksı sütununa ve satırına düşüyor? (karo + üstündeki bitki alanı); yoksa -1.
func _pot_at(grid_position: Vector2) -> int:
	var floor_state: FloorState = current_floor_state()
	var tile: float = float(FarmTiles.TILE_SIZE)
	for pot_index: int in floor_state.pots.size():
		var origin: Vector2 = pot_origin(pot_index)
		if Rect2(origin.x, origin.y - HIT_ABOVE + POT_BASE.y, tile, HIT_ABOVE + tile - POT_BASE.y).has_point(grid_position):
			return pot_index
	return -1


func _plant_rect(pot_index: int) -> Rect2:
	var base: Vector2 = pot_origin(pot_index) + POT_BASE
	return Rect2(base.x - HIT_HALF_WIDTH, base.y - HIT_ABOVE, HIT_HALF_WIDTH * 2.0, HIT_ABOVE + HIT_BELOW)


func _check_swipe_segment(from_local: Vector2, to_local: Vector2) -> void:
	var floor_state: FloorState = current_floor_state()
	var a: Vector2 = _to_grid(from_local)
	var b: Vector2 = _to_grid(to_local)
	for pot_index: int in floor_state.pots.size():
		# Her olgun bitki, tek kaydırmada EN FAZLA BİR KEZ istenir: dinleyici reddederse (ör. depo dolu) aynı
		# bitki parmak üstündeyken her harekette yeniden istenip arayüzü boğmaz.
		if _requested_pots.has(pot_index) or not floor_state.pots[pot_index].is_mature():
			continue
		if SegmentMath.segment_hits_rect(a, b, _plant_rect(pot_index)):
			_requested_pots[pot_index] = true
			harvest_requested.emit(_floor_index, pot_index)


# --------------------------------------------------------------------- iz


func _add_trail_point(local_position: Vector2) -> void:
	if reduce_motion:
		return
	_trail.add_point(local_position)
	_trail_times.append(float(Time.get_ticks_msec()) / 1000.0)
	while _trail.get_point_count() > _TRAIL_MAX_POINTS:
		_trail.remove_point(0)
		_trail_times.remove_at(0)


func _update_trail() -> void:
	if _trail.get_point_count() == 0:
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	while _trail_times.size() > 0 and now - _trail_times[0] > _TRAIL_SECONDS:
		_trail.remove_point(0)
		_trail_times.remove_at(0)


# -------------------------------------------------------------------- efekt


func _on_harvested(result: HarvestResult) -> void:
	if result.floor_index != _floor_index or _floor_index < 0:
		return
	var at: Vector2 = pot_local_position(result.pot_index) + Vector2(0.0, -70.0) * _grid_root.scale.x
	var color: Color = Color.from_hsv(result.phenotype.fruit_hue, 0.7, 1.0)
	if not reduce_motion:
		HarvestFx.burst(_fx_layer, at, color, 14 + mini(result.combo_step, 12) * 2)
	HarvestFx.floating_text(_fx_layer, "+%d" % int(round(result.total_value())), at, _GOLD, 44, reduce_motion)
	if result.combo_step >= 1:
		HarvestFx.floating_text(_fx_layer, tr("FX_COMBO") % (result.combo_step + 1), at + Vector2(0.0, -52.0), Color(0.6, 1.0, 0.9), 34, reduce_motion)
