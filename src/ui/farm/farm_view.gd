class_name FarmView
extends Control
## Bir katın 2.5D görünümü: `FarmStage` (3D sahne + perspektif kamera) bir `SubViewport` ile çizilir; üstünde 2D göstergeler (`PotOverlay`),
## hasat efektleri ve kaydırma izi durur. Dokunuşu "niyet" sinyallerine çevirir: ekran noktası kameradan geçen ışınla oyun düzlemine
## (z = 0, karo birimi) taşınır ve saksı/bitki dikdörtgenleriyle kesiştirilir.
## OYUN DURUMUNU DEĞİŞTİRMEZ: yalnızca `FarmService`'i okur; ekim/sulama/hasat isteklerini sinyalle bildirir,
## kararı ve değişikliği sahibi (GameSession) yapar. Sesi kendisi çalmaz (AudioService SignalBus'tan dinler).
##
## Uygular: design/game-brief.md, FAZ 2 (hidroponik ızgara, kaydırarak toplu hasat, ASMR geri bildirimi);
## docs/architecture/floralab-architecture.md, "2.5D çiftlik sahnesi" kararı.
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

## Kaydırmanın bitkiye "değdiği" dikdörtgenin yarım genişliği, tabanın üstü ve altı (karo; y yukarı).
const HIT_HALF_WIDTH: float = 0.345
const HIT_ABOVE: float = 1.17
const HIT_BELOW: float = 0.39
## Saksıya dokunma alanı: raf üstünden, saksı karosunun üstünün bu kadar (karo) yukarısına kadar.
const POT_TAP_ABOVE_TILE_TOP: float = 0.52
## Bitkinin gövde ortası: taban noktasının bu kadar (karo) üstü (efekt ve dokunuş hedefi).
const PLANT_MID_HEIGHT: float = 0.39
## Dokunuşun kaydırma sayılması için gereken en az sürükleme (piksel).
const TAP_SLOP: float = 16.0
## Efektlerin ve eski piksel sabitlerinin ölçeklendiği karo boyutu (piksel).
const REFERENCE_TILE_PIXELS: float = 180.0
const _TRAIL_SECONDS: float = 0.22
const _TRAIL_MAX_POINTS: int = 28
## Kat değiştirirken kameranın yandan süzülme mesafesi (karo).
const FLOOR_DOLLY_TILES: float = 1.4

## Hareketi azalt: salınım, kamera süzülmesi, parçacık ve iz kapanır (erişilebilirlik).
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		_apply_motion_setting()

## Renk körlüğü paleti (göstergeler için).
var colorblind: bool = false:
	set(value):
		colorblind = value
		if _overlay != null:
			_overlay.palette = UiTokens.palette(value)

var _farm: FarmService
var _ruleset: GeneticsRuleset
var _floor_index: int = 0
var _container: SubViewportContainer
var _viewport: SubViewport
var _stage: FarmStage
var _overlay: PotOverlay
var _drones: DroneService
var _fx_layer: Control
var _trail: Line2D
var _trail_times: PackedFloat32Array = PackedFloat32Array()
var _pressing: bool = false
var _swiping: bool = false
## Bu kaydırmada hasadı istenmiş saksılar (indeks -> true).
var _requested_pots: Dictionary = {}
var _press_position: Vector2 = Vector2.ZERO
var _last_position: Vector2 = Vector2.ZERO
var _dolly_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_container = SubViewportContainer.new()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.stretch = true
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_container.add_child(_viewport)
	_stage = FarmStage.new()
	_viewport.add_child(_stage)
	_overlay = PotOverlay.new()
	_overlay.setup(self)
	_overlay.palette = UiTokens.palette(colorblind)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_fx_layer = Control.new()
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fx_layer)
	_trail = _make_trail()
	_fx_layer.add_child(_trail)
	resized.connect(_on_resized)
	visibility_changed.connect(_on_visibility_changed)
	_stage.set_view_size(size)
	_apply_motion_setting()


## Çiftlik servisini ve kural setini bağlar; hasat efektleri için `harvested` sinyalini dinler.
func setup(farm: FarmService, ruleset: GeneticsRuleset) -> void:
	_farm = farm
	_ruleset = ruleset
	_stage.setup(ruleset)
	_farm.harvested.connect(_on_harvested)
	SignalBus.pot_watered.connect(_on_pot_watered)
	SignalBus.plant_matured.connect(_on_plant_matured)
	SignalBus.plant_planted.connect(_on_plant_planted)


## Dron servisini bağlar: kattaki dronlar ve üs çizilir (salt okunur).
func setup_drones(drone_service: DroneService) -> void:
	_drones = drone_service


## Gösterilecek katı seçer ve sahneyi yeniden kurar. `direction` (+1 sağa, -1 sola) verilirse yeni kat o yönden süzülerek girer.
func show_floor(floor_index: int, direction: int = 0) -> void:
	_floor_index = floor_index
	var floor_state: FloorState = current_floor_state()
	if floor_state == null:
		return
	_stage.set_view_size(size)
	_stage.build_floor(floor_state)
	_stage.sync(floor_state, _farm.config, _agents(), _show_dock(), _dock())
	if _dolly_tween != null:
		_dolly_tween.kill()
	_stage.set_dolly(0.0)
	_overlay.modulate.a = 1.0
	if direction != 0 and not reduce_motion and is_inside_tree():
		_stage.set_dolly(-float(direction) * FLOOR_DOLLY_TILES)
		_overlay.modulate.a = 0.0
		_dolly_tween = create_tween()
		_dolly_tween.set_parallel(true)
		_dolly_tween.tween_method(_stage.set_dolly, -float(direction) * FLOOR_DOLLY_TILES, 0.0, UiTokens.DUR_BASE * 1.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_dolly_tween.tween_property(_overlay, "modulate:a", 1.0, UiTokens.DUR_BASE)


## Günün karanlık oranı (0 gündüz, 1 gece): sahnenin ışığına ve tonuna yansır; UV lambaları etkilenmez.
func set_night(night: float) -> void:
	if _stage != null:
		_stage.set_night(night)


## Gösterilen katın durumu (salt okunur kullanım); yoksa null.
func current_floor_state() -> FloorState:
	if _farm == null:
		return null
	return _farm.get_floor(_floor_index)


## Çiftlik yapılandırması (göstergelerin eşikleri için).
func farm_config() -> FarmConfig:
	return _farm.config


## 3D sahne (test ve göstergeler için; durumu değiştirmeyin).
func stage() -> FarmStage:
	return _stage


## Saksıdaki bitki tabanının bu denetimin yerel (piksel) koordinatındaki yeri (efektler, göstergeler ve dron hedefleri için).
func pot_local_position(pot_index: int) -> Vector2:
	return _stage.project(_stage.pot_base_world(pot_index))


## Bitkinin gövde ortasının yerel koordinatı (hasat efekti ve dokunuş hedefi).
func plant_center_local(pot_index: int) -> Vector2:
	return _stage.project(_stage.pot_base_world(pot_index) + Vector3(0.0, PLANT_MID_HEIGHT, 0.0))


## Düzlemde bir karonun ekrandaki piksel boyutu.
func pixels_per_tile() -> float:
	return _stage.pixels_per_tile()


## Eski piksel sabitlerini (180 piksellik karoya göre yazılmış) ekran ölçeğine çeviren çarpan.
func tile_scale() -> float:
	return pixels_per_tile() / REFERENCE_TILE_PIXELS


func _process(delta: float) -> void:
	var floor_state: FloorState = current_floor_state()
	if _farm == null or floor_state == null:
		return
	_stage.advance(delta)
	_stage.sync(floor_state, _farm.config, _agents(), _show_dock(), _dock())
	_update_trail()
	_overlay.queue_redraw()


func _agents() -> Array[DroneAgent]:
	var list: Array[DroneAgent] = []
	if _drones != null:
		list = _drones.agents_for_floor(_floor_index)
	return list


func _show_dock() -> bool:
	return _drones != null and current_floor_state().drones > 0


func _dock() -> Vector2:
	return _drones.config.dock_position if _drones != null else Vector2(-0.5, 0.2)


func _on_resized() -> void:
	if _stage != null:
		_stage.set_view_size(size)


func _on_visibility_changed() -> void:
	if _stage != null and _stage.atlas() != null:
		_stage.atlas().set_active(is_visible_in_tree())
	set_process(is_visible_in_tree())


func _apply_motion_setting() -> void:
	if _stage != null:
		_stage.reduce_motion = reduce_motion
	if _trail != null:
		_trail.visible = not reduce_motion


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
	var pot_index: int = _pot_at(_stage.plane_point(position_))
	if pot_index >= 0:
		pot_tapped.emit(_floor_index, pot_index)


## Oyun düzlemindeki (karo birimi, y yukarı) bir nokta hangi saksıya düşüyor? (karo + üstündeki bitki alanı); yoksa -1.
func _pot_at(plane: Vector2) -> int:
	var floor_state: FloorState = current_floor_state()
	for pot_index: int in floor_state.pots.size():
		var col: int = floor_state.col_of(pot_index)
		var row: int = floor_state.row_of(pot_index)
		var tile_top: float = -float(2 * row + 1)
		var slab_top: float = -float(2 * row + 2)
		var rect: Rect2 = Rect2(float(col), slab_top, 1.0, tile_top + POT_TAP_ABOVE_TILE_TOP - slab_top)
		if rect.has_point(plane):
			return pot_index
	return -1


## Bitkinin kaydırmayla "değdiği" dikdörtgen (düzlem uzayı: karo, y yukarı).
func _plant_rect(pot_index: int) -> Rect2:
	var base: Vector3 = _stage.pot_base_world(pot_index)
	return Rect2(base.x - HIT_HALF_WIDTH, base.y - HIT_BELOW, HIT_HALF_WIDTH * 2.0, HIT_ABOVE + HIT_BELOW)


func _check_swipe_segment(from_local: Vector2, to_local: Vector2) -> void:
	var floor_state: FloorState = current_floor_state()
	var a: Vector2 = _stage.plane_point(from_local)
	var b: Vector2 = _stage.plane_point(to_local)
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
	var at: Vector2 = plant_center_local(result.pot_index)
	var color: Color = Color.from_hsv(result.phenotype.fruit_hue, 0.7, 1.0)
	if not reduce_motion:
		HarvestFx.burst(_fx_layer, at, color, 14 + mini(result.combo_step, 12) * 2)
	HarvestFx.floating_text(_fx_layer, "+%s" % UiFormat.number(int(round(result.total_value()))), at, UiTokens.palette(colorblind)["gold"] as Color, 44, reduce_motion)
	if not reduce_motion:
		HarvestFx.fly_coins(_fx_layer, at, Vector2(120.0, -230.0), clampi(int(result.total_value() / 12.0), 1, 4))
	if result.combo_step >= 1:
		HarvestFx.floating_text(_fx_layer, tr("FX_COMBO") % (result.combo_step + 1), at + Vector2(0.0, -52.0), UiTokens.palette(colorblind)["aqua"] as Color, 34, reduce_motion)


func _on_pot_watered(floor_index: int, pot_index: int) -> void:
	if reduce_motion or floor_index != _floor_index or _fx_layer == null:
		return
	HarvestFx.water_splash(_fx_layer, pot_local_position(pot_index) + Vector2(0.0, -30.0) * tile_scale())


func _on_plant_matured(floor_index: int, pot_index: int) -> void:
	if reduce_motion or floor_index != _floor_index or _fx_layer == null:
		return
	HarvestFx.ring(_fx_layer, plant_center_local(pot_index), UiTokens.palette(colorblind)["gold"] as Color, 80.0 * tile_scale())


func _on_plant_planted(floor_index: int, pot_index: int) -> void:
	if reduce_motion or floor_index != _floor_index or _fx_layer == null:
		return
	HarvestFx.ring(_fx_layer, pot_local_position(pot_index) + Vector2(0.0, -10.0) * tile_scale(), UiTokens.palette(colorblind)["good"] as Color, 46.0 * tile_scale())
