extends TestCase
## FarmView girdisi: kısa dokunuş saksı sinyali verir, sürükleme yalnızca değdiği OLGUN bitkiler için hasat ister.
## Gerçek sahne, gerçek bitki sahneleri ve gerçek veri; fare olayları doğrudan `_gui_input`'a verilir.

const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const SEED_PATH: String = "res://assets/data/genetics/seeds/starter_reed_berry.tres"

var _farm: FarmService
var _view: FarmView
var _tapped: Array[String] = []
var _requested: Array[String] = []
var _events: Array[String] = []


func before_each() -> void:
	var ruleset: GeneticsRuleset = load(RULESET_PATH) as GeneticsRuleset
	var floors: Array[FloorState] = [FarmFixtures.make_floor(3, 2, true, 0)]
	_farm = FarmService.new()
	_farm.setup(FarmFixtures.make_config(), ruleset, floors)
	_view = FarmView.new()
	add_to_tree(_view)
	_view.size = Vector2(1080.0, 1500.0)
	_view.setup(_farm, ruleset)
	_view.show_floor(0)
	_tapped.clear()
	_requested.clear()
	_events.clear()
	_view.pot_tapped.connect(func(floor_index: int, pot_index: int) -> void: _tapped.append("%d:%d" % [floor_index, pot_index]))
	_view.harvest_requested.connect(func(floor_index: int, pot_index: int) -> void: _requested.append("%d:%d" % [floor_index, pot_index]))
	_view.swipe_started.connect(func() -> void: _events.append("start"))
	_view.swipe_ended.connect(func() -> void: _events.append("end"))


func _seed() -> PlantGene:
	return load(SEED_PATH) as PlantGene


func _plant_mature(pot_index: int) -> void:
	_farm.plant(0, pot_index, _seed())
	_farm.get_pot(0, pot_index).growth = 1.0


## Bitkinin gövde ortasına denk gelen yerel nokta.
func _plant_center(pot_index: int) -> Vector2:
	return _view.plant_center_local(pot_index)


func _press(position_: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position_
	_view._gui_input(event)


func _release(position_: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = position_
	_view._gui_input(event)


func _move(position_: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = position_
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_view._gui_input(event)


func test_a_short_tap_on_a_pot_reports_that_pot() -> void:
	var point: Vector2 = _view.pot_local_position(4)

	_press(point)
	_release(point + Vector2(3.0, 2.0))

	assert_eq(_tapped, ["0:4"] as Array[String], "dokunulan saksı")
	assert_eq(_requested.size(), 0, "dokunuş hasat istemez")
	assert_eq(_events.size(), 0, "kaydırma başlamadı")


func test_a_tiny_jitter_during_a_tap_still_counts_as_a_tap() -> void:
	var point: Vector2 = _view.pot_local_position(0)
	_plant_mature(0)

	_press(point)
	_move(point + Vector2(5.0, 4.0))
	_release(point + Vector2(5.0, 4.0))

	assert_eq(_tapped, ["0:0"] as Array[String], "eşik altı sürükleme dokunuştur")
	assert_eq(_requested.size(), 0, "kaydırma sayılmadı")
	assert_eq(_events.size(), 0)


func test_a_swipe_that_stays_clear_of_the_plants_requests_nothing() -> void:
	for pot_index: int in 3:
		_plant_mature(pot_index)
	var above: float = _plant_center(0).y - 600.0

	_press(Vector2(40.0, above))
	_move(Vector2(1000.0, above))
	_release(Vector2(1000.0, above))

	assert_eq(_requested.size(), 0, "bitkilerin çok üstünden geçen kaydırma")
	assert_eq(_events, ["start", "end"] as Array[String])


func test_a_new_swipe_may_request_the_same_plant_again() -> void:
	_plant_mature(1)
	var center: Vector2 = _plant_center(1)

	for round_index: int in 2:
		_press(center + Vector2(-120.0, 0.0))
		_move(center + Vector2(120.0, 0.0))
		_release(center + Vector2(120.0, 0.0))

	assert_eq(_requested, ["0:1", "0:1"] as Array[String], "her kaydırma kendi sayımını tutar")


func test_only_the_left_button_starts_a_gesture() -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = _view.pot_local_position(0)
	_view._gui_input(event)
	event.pressed = false
	_view._gui_input(event)

	assert_eq(_tapped.size(), 0, "sağ tuş dokunuş sayılmaz")


func test_a_tap_outside_every_pot_reports_nothing() -> void:
	_press(Vector2(5.0, 5.0))
	_release(Vector2(5.0, 5.0))

	assert_eq(_tapped.size(), 0)


func test_a_swipe_across_a_mature_plant_requests_its_harvest_once() -> void:
	_plant_mature(1)
	var center: Vector2 = _plant_center(1)

	_press(center + Vector2(-120.0, 0.0))
	_move(center + Vector2(-40.0, 0.0))
	_move(center + Vector2(40.0, 0.0))
	_move(center + Vector2(120.0, 0.0))
	_release(center + Vector2(120.0, 0.0))

	assert_eq(_requested, ["0:1"] as Array[String], "yalnızca o bitki, bir kez")
	assert_eq(_events, ["start", "end"] as Array[String], "kaydırma başladı ve bitti")
	assert_eq(_tapped.size(), 0, "kaydırma dokunuş sayılmaz")


func test_a_swipe_over_an_immature_plant_requests_nothing() -> void:
	_farm.plant(0, 1, _seed())
	var center: Vector2 = _plant_center(1)

	_press(center + Vector2(-120.0, 0.0))
	_move(center + Vector2(120.0, 0.0))
	_release(center + Vector2(120.0, 0.0))

	assert_eq(_requested.size(), 0, "olgun değil: hasat istenmez")


func test_a_swipe_through_a_row_requests_every_mature_plant_in_path_order() -> void:
	for pot_index: int in 3:
		_plant_mature(pot_index)
	var y: float = _plant_center(0).y
	var left: float = _plant_center(0).x - 120.0
	var right: float = _plant_center(2).x + 120.0
	# Dinleyici sonuçları işlemez; bu yüzden bitkiler olgun kalır ve her segmentte yeniden istenir. Tek dilimlik
	# hamle: tek `_move`, ama tüm sırayı keser.
	_press(Vector2(left, y))

	_move(Vector2(right, y))
	_release(Vector2(right, y))

	assert_eq(_requested, ["0:0", "0:1", "0:2"] as Array[String], "soldan sağa sıra")


func test_once_a_listener_harvests_the_plant_the_next_segments_do_not_request_it_again() -> void:
	_plant_mature(1)
	_view.harvest_requested.connect(func(floor_index: int, pot_index: int) -> void: _farm.harvest(floor_index, pot_index))
	var center: Vector2 = _plant_center(1)

	_press(center + Vector2(-120.0, 0.0))
	_move(center + Vector2(-40.0, 0.0))
	_move(center + Vector2(40.0, 0.0))
	_move(center + Vector2(120.0, 0.0))
	_release(center + Vector2(120.0, 0.0))

	assert_eq(_requested.size(), 1, "hasattan sonra saksı boşaldı, yeniden istenmedi")
	assert_true(_farm.get_pot(0, 1).is_empty())


func test_plants_follow_the_farm_state_every_frame() -> void:
	_farm.plant(0, 2, _seed())
	_farm.get_pot(0, 2).growth = 0.5

	_view._process(0.016)

	var atlas: PlantAtlas = _view.stage().atlas()
	var found: int = 0
	for index: int in atlas.capacity():
		var plant: PlantInstance = atlas.plant_at(index)
		if plant.gene != null:
			found += 1
			assert_eq(index, 2, "bitki dolu saksının hücresinde")
			assert_almost_eq(plant.growth, 0.5, 0.01, "bitki saksının büyümesini izler")
	assert_eq(found, 1, "yalnızca dolu saksıda bitki çizilir")
