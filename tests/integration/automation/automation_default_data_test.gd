extends TestCase
## Gerçek otomasyon verisi: katlar sıralı ve artan maliyetli, donanım tanımları eksiksiz, dron ayarı makul.

const FLOORS_DIR: String = "res://assets/data/floors"
const EQUIPMENT_DIR: String = "res://assets/data/equipment"
const CONFIG_PATH: String = "res://assets/data/automation/default_automation_config.tres"

var _floors: Array[FloorDef] = []
var _equipment: Array[EquipmentDef] = []


func before_each() -> void:
	_floors.clear()
	_equipment.clear()
	var floor_files: PackedStringArray = DirAccess.get_files_at(FLOORS_DIR)
	floor_files.sort()
	for file_name: String in floor_files:
		if file_name.ends_with(".tres"):
			_floors.append(load(FLOORS_DIR.path_join(file_name)) as FloorDef)
	for file_name: String in DirAccess.get_files_at(EQUIPMENT_DIR):
		if file_name.ends_with(".tres"):
			_equipment.append(load(EQUIPMENT_DIR.path_join(file_name)) as EquipmentDef)


func test_floors_are_sequential_start_unlocked_and_get_pricier_and_bigger() -> void:
	assert_true(_floors.size() >= 3, "en az üç kat")
	for i: int in _floors.size():
		assert_eq(_floors[i].index, i, "kat sırası")
		assert_true(_floors[i].display_name != "")
		assert_true(_floors[i].cols >= 1 and _floors[i].rows >= 1)
	assert_eq(_floors[0].unlock_cost, 0, "zemin kat baştan açık")
	for i: int in range(1, _floors.size()):
		assert_true(_floors[i].unlock_cost > _floors[i - 1].unlock_cost, "maliyet artar")
		assert_true(_floors[i].cols * _floors[i].rows >= _floors[i - 1].cols * _floors[i - 1].rows, "kat küçülmez")


func test_every_equipment_kind_exists_exactly_once_with_sane_numbers() -> void:
	var kinds: Dictionary = {}
	for def: EquipmentDef in _equipment:
		assert_not_null(def)
		assert_false(kinds.has(def.kind), "tür yinelenmez: %s" % def.id)
		kinds[def.kind] = true
		assert_true(def.cost > 0 and def.max_level >= 1 and def.cost_growth >= 1.0)
		assert_true(def.display_name != "" and def.description != "")
		if def.kind == EquipmentDef.Kind.LAB_UV:
			assert_true(def.mutation_bonus_per_level > 0.0, "UV odası mutasyon bonusu verir")
	assert_eq(kinds.size(), EquipmentDef.Kind.size(), "her tür tanımlı")


func test_the_drone_config_is_sane() -> void:
	var config: AutomationConfig = load(CONFIG_PATH) as AutomationConfig

	assert_not_null(config)
	assert_true(config.drone_speed > 0.0 and config.drone_harvest_seconds > 0.0 and config.drone_idle_seconds > 0.0)
	assert_true(config.offline_drone_cycle_seconds >= config.drone_harvest_seconds, "çevrimdışı döngü, biçme süresinden kısa olamaz")
