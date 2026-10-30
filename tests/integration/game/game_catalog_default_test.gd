extends TestCase
## Gerçek oyun kataloğu (assets/data/game_catalog.tres): tutarlı, eksiksiz ve veri klasörleriyle birebir eşleşir
## (yetim veri yok: klasördeki her .tres katalogda listelenir).

const CATALOG_PATH: String = "res://assets/data/game_catalog.tres"

var _catalog: GameCatalog


func before_each() -> void:
	_catalog = load(CATALOG_PATH) as GameCatalog


func _count_resources(directory: String) -> int:
	var count: int = 0
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".tres"):
			count += 1
	return count


func test_the_catalog_loads_and_validates_clean() -> void:
	assert_not_null(_catalog)
	assert_eq(_catalog.validate(), PackedStringArray(), "tutarlılık sorunları")


func test_every_data_file_is_listed_in_the_catalog() -> void:
	assert_eq(_catalog.floors.size(), _count_resources("res://assets/data/floors"), "katlar")
	assert_eq(_catalog.equipment.size(), _count_resources("res://assets/data/equipment"), "donanım")
	assert_eq(_catalog.market_events.size(), _count_resources("res://assets/data/economy/events"), "haber olayları")
	assert_eq(_catalog.order_templates.size(), _count_resources("res://assets/data/economy/orders"), "sipariş şablonları")
	assert_eq(_catalog.starter_seeds.size(), 4, "başlangıç tohumları")
	assert_eq(_count_resources("res://assets/data/genetics/seeds"), _catalog.starter_seeds.size(), "tohum dosyaları")


func test_the_starter_kit_lets_a_new_player_plant_a_floor_and_earn_the_first_upgrade() -> void:
	var total_seeds: int = 0
	for count: int in _catalog.starter_seed_counts:
		total_seeds += count
	var first_floor: FloorDef = _catalog.floors[0]

	assert_true(total_seeds >= first_floor.cols * first_floor.rows, "ilk kat dolacak kadar tohum")
	assert_true(_catalog.economy_config.starting_credits >= _catalog.economy_config.cross_cost, "ilk çaprazlama karşılanır")


func test_validation_reports_broken_catalogs() -> void:
	var broken: GameCatalog = GameCatalog.new()
	assert_false(broken.validate().is_empty(), "boş katalog geçersiz")

	var copy: GameCatalog = load(CATALOG_PATH).duplicate() as GameCatalog
	copy.starter_seed_counts = PackedInt32Array([1])
	assert_false(copy.validate().is_empty(), "tohum/adet uyuşmazlığı yakalanır")
