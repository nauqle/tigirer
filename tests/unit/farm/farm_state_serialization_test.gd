extends TestCase
## PotState ve FloorState: sözlüğe ve JSON metnine yazılıp geri okunur; eski/bozuk kayıt ızgarayı bozmaz.

const EPSILON: float = 0.0001

var _ruleset: GeneticsRuleset


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()


func test_a_planted_pot_survives_json_and_rebuilds_its_phenotype() -> void:
	var pot: PotState = PotState.new()
	pot.gene = FarmFixtures.make_gene(GeneticsFixtures.FRUIT_B, "g1")
	pot.phenotype = GeneticsEngine.express(pot.gene, _ruleset)
	pot.growth = 0.6
	pot.water = 0.4
	pot.overgrowth_seconds = 12.0

	var text: String = JSON.stringify(pot.to_dict())
	var restored: PotState = PotState.from_dict(JSON.parse_string(text) as Dictionary, _ruleset)

	assert_false(restored.is_empty())
	assert_eq(restored.gene.uid, "g1")
	assert_almost_eq(restored.growth, 0.6, EPSILON)
	assert_almost_eq(restored.water, 0.4, EPSILON)
	assert_almost_eq(restored.overgrowth_seconds, 12.0, EPSILON)
	assert_almost_eq(restored.phenotype.market_value, 20.0, 0.001, "fenotip yüklemede yeniden hesaplandı")


func test_an_empty_pot_keeps_its_water_and_stays_empty() -> void:
	var pot: PotState = PotState.new()
	pot.water = 0.35

	var restored: PotState = PotState.from_dict(pot.to_dict(), _ruleset)

	assert_true(restored.is_empty())
	assert_almost_eq(restored.water, 0.35, EPSILON)


func test_a_corrupt_gene_in_a_pot_leaves_the_pot_empty_instead_of_crashing() -> void:
	var data: Dictionary = {"growth": 0.5, "water": 0.5, "gene": {"stem": ["only_one"]}}

	var restored: PotState = PotState.from_dict(data, _ruleset)

	assert_true(restored.is_empty())


func test_a_floor_round_trips_its_grid_equipment_and_plants() -> void:
	var def: FloorDef = FarmFixtures.make_def(2, 3, 2, 500)
	var floor_state: FloorState = FloorState.from_def(def, true)
	floor_state.irrigation_rows[1] = true
	floor_state.uv_rows[0] = 2
	floor_state.drones = 3
	floor_state.pots[4].gene = FarmFixtures.make_gene()
	floor_state.pots[4].phenotype = GeneticsEngine.express(floor_state.pots[4].gene, _ruleset)
	floor_state.pots[4].growth = 0.8

	var text: String = JSON.stringify(floor_state.to_dict())
	var restored: FloorState = FloorState.from_dict(JSON.parse_string(text) as Dictionary, def, _ruleset)

	assert_true(restored.unlocked)
	assert_eq(restored.pots.size(), 6, "3x2 ızgara")
	assert_eq(restored.irrigation_rows, [false, true] as Array[bool])
	assert_eq(restored.uv_rows, [2, 0] as Array[int])
	assert_eq(restored.drones, 3)
	assert_almost_eq(restored.pots[4].growth, 0.8, EPSILON)
	assert_true(restored.pots[0].is_empty())


func test_a_save_from_a_smaller_grid_is_padded_and_one_from_a_larger_grid_is_trimmed() -> void:
	var small_def: FloorDef = FarmFixtures.make_def(0, 2, 1, 0)
	var small: FloorState = FloorState.from_def(small_def, true)
	small.pots[1].gene = FarmFixtures.make_gene()
	small.uv_rows[0] = 1
	var data: Dictionary = small.to_dict()

	var bigger_def: FloorDef = FarmFixtures.make_def(0, 3, 2, 0)
	var grown: FloorState = FloorState.from_def(small_def, true)
	var padded: FloorState = FloorState.from_dict(data, bigger_def, _ruleset)
	var trimmed: FloorState = FloorState.from_dict(padded.to_dict(), small_def, _ruleset)

	assert_eq(padded.pots.size(), 6, "büyütülmüş ızgara boşla tamamlandı")
	assert_eq(padded.uv_rows.size(), 2)
	assert_eq(trimmed.pots.size(), 2, "küçültülmüş ızgara kırpıldı")
	assert_eq(grown.pots.size(), 2)


func test_grid_helpers_map_between_pot_index_and_column_row() -> void:
	var floor_state: FloorState = FarmFixtures.make_floor(3, 2)

	assert_eq(floor_state.row_of(4), 1)
	assert_eq(floor_state.col_of(4), 1)
	assert_true(floor_state.pot_at(2, 1) == floor_state.pots[5], "sütun 2 satır 1 = indeks 5")
	assert_null(floor_state.pot_at(3, 0), "sınır dışı")
	assert_null(floor_state.pot_at(0, -1), "sınır dışı")
