extends Control
## FAZ 2 geliştirici sahnesi: tek katlı çiftlik. Dokunuş = ekim / sulama / hasat, sürükleme = kaydırarak toplu hasat.
## Ekran görüntüsü ve elle deneme içindir; asıl oyun sahnesi FAZ 5'te `GameSession` ile kurulur.
##
## Uygular: design/game-brief.md, FAZ 2 (hidroponik ızgara, büyüme evreleri, su/ışık, kaydırarak hasat).
##
## Komut satırı (godot ... -- seçenekler): --cols=N --rows=N, --speed=N (oyun hızı), --irrigation (tüm satırlar sulamalı),
## --uv=N (UV seviyesi), --drones=N (hasat dronu), --stages (saksılara farklı büyüme evreleri ver), --autoswipe=KARE (o karede otomatik kaydırma).
## Dev-only: kullanıcıya dönük metinler bilerek yerelleştirilmedi (src/ui kuralı bu klasörü kapsamaz).

const STARTER_PATHS: Array[String] = [
	"res://assets/data/genetics/seeds/starter_reed_berry.tres",
	"res://assets/data/genetics/seeds/starter_vine_tulip.tres",
	"res://assets/data/genetics/seeds/starter_bamboo_pod.tres",
	"res://assets/data/genetics/seeds/starter_cyber_carrier.tres",
]
## --stages: saksılardaki başlangıç büyümeleri (tohum, filiz, filiz, olgun, olgun, hazır).
const STAGE_GROWTH: Array[float] = [0.0, 0.3, 0.6, 1.0, 1.0, 1.0]

var _config: FarmConfig = preload("res://assets/data/farm/default_farm_config.tres")
var _ruleset: GeneticsRuleset = preload("res://assets/data/genetics/default_ruleset.tres")
var _automation_config: AutomationConfig = preload("res://assets/data/automation/default_automation_config.tres")
var _farm: FarmService = FarmService.new()
var _relay: FarmSignalRelay
var _drones: DroneService = DroneService.new()
var _time: TimeManager = TimeManager.new()
var _seeds: Array[PlantGene] = []
var _next_seed: int = 0
var _combo: int = 0
var _swipe_total: float = 0.0
var _earned: float = 0.0
var _view: FarmView
var _status: Label
var _autoswipe_frame: int = -1
var _frame: int = 0


func _ready() -> void:
	var options: Dictionary = _read_options()
	for path: String in STARTER_PATHS:
		_seeds.append(load(path) as PlantGene)

	var def: FloorDef = FloorDef.new()
	def.cols = int(options.get("cols", 3))
	def.rows = int(options.get("rows", 2))
	var floor_state: FloorState = FloorState.from_def(def, true, _config.water_start)
	if options.has("irrigation"):
		for r: int in def.rows:
			floor_state.irrigation_rows[r] = true
	for r: int in def.rows:
		floor_state.uv_rows[r] = int(options.get("uv", 0))
	_time.setup(_config.day_length_seconds, _config.max_speed)
	_time.set_speed(float(options.get("speed", 1.0)))
	floor_state.drones = int(options.get("drones", 0))
	_farm.setup(_config, _ruleset, [floor_state] as Array[FloorState])
	_drones.setup(_automation_config, _farm)
	var relay: FarmSignalRelay = FarmSignalRelay.new()
	relay.connect_to(_farm)
	_relay = relay
	_farm.harvested.connect(_on_harvested)

	var backdrop: CityBackdrop = CityBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	add_child(AudioService.new())
	_view = FarmView.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.offset_top = 160.0
	_view.offset_bottom = -120.0
	add_child(_view)
	_view.setup(_farm, _ruleset)
	_view.setup_drones(_drones)
	_view.pot_tapped.connect(_on_pot_tapped)
	_view.swipe_started.connect(_on_swipe_started)
	_view.harvest_requested.connect(_on_harvest_requested)
	_view.swipe_ended.connect(_on_swipe_ended)
	_view.show_floor(0)
	_build_labels()

	if options.has("stages"):
		for pot_index: int in mini(STAGE_GROWTH.size(), floor_state.pots.size()):
			_farm.plant(0, pot_index, _seeds[pot_index % _seeds.size()])
			floor_state.pots[pot_index].growth = STAGE_GROWTH[pot_index]
		floor_state.pots[1].water = 0.1
	_autoswipe_frame = int(options.get("autoswipe", -1))


func _process(delta: float) -> void:
	_frame += 1
	var game_delta: float = _time.advance(delta)
	_farm.tick(game_delta)
	_drones.tick(game_delta)
	_status.text = "Kazanç: %d   ·   hız ×%.0f   ·   gün %d" % [int(_earned), _time.speed, _time.day()]
	if _frame == _autoswipe_frame:
		_run_autoswipe()


func _build_labels() -> void:
	var title: Label = Label.new()
	title.text = "FAZ 2 · dokun: ekim/sulama/hasat · sürükle: toplu hasat"
	title.position = Vector2(0.0, 40.0)
	title.size = Vector2(1080.0, 0.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.85))
	add_child(title)
	_status = Label.new()
	_status.position = Vector2(0.0, 96.0)
	_status.size = Vector2(1080.0, 0.0)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 26)
	add_child(_status)


func _on_pot_tapped(floor_index: int, pot_index: int) -> void:
	var pot: PotState = _farm.get_pot(floor_index, pot_index)
	if pot.is_empty():
		_farm.plant(floor_index, pot_index, _seeds[_next_seed % _seeds.size()])
		_next_seed += 1
	elif pot.is_mature():
		_farm.harvest(floor_index, pot_index)
	else:
		_farm.water(floor_index, pot_index)


func _on_swipe_started() -> void:
	_combo = 0
	_swipe_total = 0.0


func _on_harvest_requested(floor_index: int, pot_index: int) -> void:
	var result: HarvestResult = _farm.harvest(floor_index, pot_index, _combo)
	if result != null:
		_combo += 1
		_swipe_total += result.total_value()


func _on_swipe_ended() -> void:
	SignalBus.harvest_swipe_finished.emit(_combo, _swipe_total)


func _on_harvested(result: HarvestResult) -> void:
	_earned += result.total_value()


## Olgun bitkilerin üstünden geçen sahte bir parmak hareketi gönderir (ekran görüntüsü ve girdi hattı denemesi).
func _run_autoswipe() -> void:
	var transform_to_window: Transform2D = get_viewport().get_final_transform()
	var path: Array[Vector2] = []
	for pot_index: int in _farm.mature_pot_indices(0):
		var target: Vector2 = _view.get_global_transform() * (_view.pot_local_position(pot_index) + Vector2(0.0, -60.0))
		path.append(target)
	if path.size() == 0:
		return
	path.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x if absf(a.y - b.y) < 60.0 else a.y < b.y)
	var points: Array[Vector2] = [path[0] + Vector2(-70.0, 0.0)]
	for target: Vector2 in path:
		points.append(target)
	points.append(path[path.size() - 1] + Vector2(70.0, 0.0))
	_push_mouse(transform_to_window * points[0], true)
	for i: int in range(1, points.size()):
		for step: int in 4:
			await get_tree().process_frame
			var from: Vector2 = points[i - 1]
			var to: Vector2 = points[i]
			_push_motion(transform_to_window * from.lerp(to, float(step + 1) / 4.0))
	await get_tree().process_frame
	_push_mouse(transform_to_window * points[points.size() - 1], false)


func _push_mouse(window_position: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = window_position
	event.global_position = window_position
	get_viewport().push_input(event)


func _push_motion(window_position: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = window_position
	event.global_position = window_position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(event)


func _read_options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var body: String = argument.substr(2)
		var split: int = body.find("=")
		if split < 0:
			options[body] = true
		else:
			options[body.substr(0, split)] = body.substr(split + 1)
	return options
