extends TestCase
## FarmStage eşzamanlaması: oyun durumu (bitki, sulama, UV, dron) 3D sahneye doğru yansır; sahne durumu değiştirmez.

const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const SEED_PATH: String = "res://assets/data/genetics/seeds/starter_reed_berry.tres"

var _ruleset: GeneticsRuleset
var _farm: FarmService
var _stage: FarmStage
var _floor: FloorState


func before_each() -> void:
	_ruleset = load(RULESET_PATH) as GeneticsRuleset
	_floor = FarmFixtures.make_floor(3, 2, true, 0)
	var floors: Array[FloorState] = [_floor]
	_farm = FarmService.new()
	_farm.setup(FarmFixtures.make_config(), _ruleset, floors)
	_stage = FarmStage.new()
	add_to_tree(_stage)
	_stage.setup(_ruleset)
	_stage.set_view_size(Vector2(1030.0, 1000.0))
	_stage.build_floor(_floor)


func _sync(agents: Array[DroneAgent] = [], show_dock: bool = false) -> void:
	_stage.sync(_floor, _farm.config, agents, show_dock, Vector2(-0.5, 0.2))


func _seed() -> PlantGene:
	return load(SEED_PATH) as PlantGene


func test_only_occupied_pots_show_a_plant() -> void:
	_farm.plant(0, 1, _seed())
	_farm.get_pot(0, 1).growth = 0.6

	_sync()

	for pot_index: int in 6:
		assert_eq(_stage.plant_visible(pot_index), pot_index == 1, "saksı %d" % pot_index)


func test_a_harvested_pot_loses_its_plant_in_the_next_sync() -> void:
	_farm.plant(0, 4, _seed())
	_farm.get_pot(0, 4).growth = 1.0
	_sync()
	assert_true(_stage.plant_visible(4))

	_farm.harvest(0, 4)
	_sync()

	assert_false(_stage.plant_visible(4), "hasattan sonra boş saksı")


func test_irrigation_rows_show_their_pipe_and_lamps_light_only_when_powered() -> void:
	_floor.irrigation_rows[1] = true
	_floor.uv_rows[0] = 2

	_sync()

	assert_false(_stage.pipe_visible(0))
	assert_true(_stage.pipe_visible(1), "sulamalı satırda boru görünür")
	assert_true(_stage.lamp_powered(0), "UV seviyesi olan satırın lambası yanar")
	assert_false(_stage.lamp_powered(1), "UV'siz satırın lambası sönük")


func test_the_lamp_goes_dark_again_when_the_level_drops_to_zero() -> void:
	_floor.uv_rows[0] = 1
	_sync()
	assert_true(_stage.lamp_powered(0))

	_floor.uv_rows[0] = 0
	_sync()

	assert_false(_stage.lamp_powered(0))


func test_a_luminous_mutation_gets_a_halo_and_an_ordinary_plant_does_not() -> void:
	var glowing: PlantGene = _seed().duplicate() as PlantGene
	glowing.mutations = [&"luminescent"] as Array[StringName]
	_farm.plant(0, 0, glowing)
	_farm.get_pot(0, 0).growth = 1.0
	_farm.plant(0, 1, _seed())
	_farm.get_pot(0, 1).growth = 1.0

	_sync()

	assert_true(_stage.halo_visible(0), "parlayan bitkinin halosu var")
	assert_false(_stage.halo_visible(1), "sıradan bitkinin halosu yok")


func test_drones_appear_and_disappear_with_the_agent_list() -> void:
	var one: DroneAgent = DroneAgent.new()
	one.position = Vector2(1.5, 0.5)
	var two: DroneAgent = DroneAgent.new()
	two.position = Vector2(0.5, 1.5)

	_sync([one, two] as Array[DroneAgent], true)
	assert_eq(_stage.visible_drone_count(), 2)

	_sync([one] as Array[DroneAgent], true)
	assert_eq(_stage.visible_drone_count(), 1, "kaldırılan dron gizlenir")

	_sync([] as Array[DroneAgent], false)
	assert_eq(_stage.visible_drone_count(), 0)


func test_rebuilding_a_larger_floor_creates_one_plant_cell_per_pot() -> void:
	_stage.build_floor(FarmFixtures.make_floor(4, 4, true, 1))

	assert_true(_stage.atlas().capacity() >= 16, "atlas 16 saksıya yetecek kadar hücre taşır (%d)" % _stage.atlas().capacity())
	assert_false(_stage.plant_visible(15), "yeni katın saksıları boş başlar")


func test_syncing_never_changes_the_farm_state() -> void:
	_farm.plant(0, 2, _seed())
	_farm.get_pot(0, 2).growth = 0.4
	var before: Dictionary = _floor.to_dict()

	_sync()
	_sync()

	assert_eq(_floor.to_dict(), before, "sahne yalnızca okur")
