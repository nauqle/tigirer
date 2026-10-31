extends TestCase
## PlantAtlas: bitkileri tek saydam 2D pencerede dizer; hücreler ayrık ve [0,1] içindedir, bitkiler halo çizmez.

const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const SEED_PATH: String = "res://assets/data/genetics/seeds/starter_reed_berry.tres"


func _atlas(capacity: int) -> PlantAtlas:
	var atlas: PlantAtlas = PlantAtlas.new()
	add_to_tree(atlas)
	atlas.setup(load(RULESET_PATH) as GeneticsRuleset, capacity)
	return atlas


func test_the_atlas_grows_its_texture_to_fit_the_cells() -> void:
	var atlas: PlantAtlas = _atlas(6)

	assert_eq(atlas.capacity(), 6)
	assert_eq(atlas.size.x, PlantAtlas.COLUMNS * PlantAtlas.CELL_SIZE.x)
	assert_eq(atlas.size.y, 2 * PlantAtlas.CELL_SIZE.y, "6 hücre 4 sütunda iki satır")

	atlas.ensure_capacity(16)
	assert_eq(atlas.size.y, 4 * PlantAtlas.CELL_SIZE.y, "16 hücre dört satır")


func test_capacity_never_shrinks() -> void:
	var atlas: PlantAtlas = _atlas(12)

	atlas.ensure_capacity(3)

	assert_eq(atlas.capacity(), 12)


func test_cell_regions_are_disjoint_and_inside_the_unit_square() -> void:
	var atlas: PlantAtlas = _atlas(16)
	var unit: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)

	for i: int in 16:
		var region: Rect2 = atlas.cell_region(i)
		assert_true(unit.encloses(region.grow(-0.0001)), "hücre %d [0,1] içinde: %s" % [i, str(region)])
		for j: int in range(i + 1, 16):
			assert_false(region.grow(-0.0001).intersects(atlas.cell_region(j)), "hücre %d ve %d çakışmaz" % [i, j])


func test_each_plant_stands_at_the_base_point_of_its_own_cell() -> void:
	var atlas: PlantAtlas = _atlas(6)

	for i: int in 6:
		var expected: Vector2 = atlas.cell_origin(i) + PlantAtlas.BASE_IN_CELL
		assert_eq(atlas.plant_at(i).position, expected, "hücre %d" % i)


func test_syncing_a_pot_sets_the_gene_and_growth_of_that_cell_only() -> void:
	var atlas: PlantAtlas = _atlas(4)
	var gene: PlantGene = load(SEED_PATH) as PlantGene

	atlas.sync_pot(2, gene, 0.7)

	assert_eq(atlas.plant_at(2).gene, gene)
	assert_almost_eq(atlas.plant_at(2).growth, 0.7, 0.001)
	assert_null(atlas.plant_at(1).gene, "diğer hücreler boş")


func test_atlas_plants_do_not_draw_their_own_halo() -> void:
	var atlas: PlantAtlas = _atlas(2)

	assert_false(atlas.plant_at(0).halo_enabled, "halo sahnede ayrı çizilir (toplamalı karışım saydam hedefe yazılamaz)")


func test_sway_follows_the_motion_setting() -> void:
	var atlas: PlantAtlas = _atlas(3)

	atlas.set_sway(false)
	for i: int in 3:
		assert_false(atlas.plant_at(i).sway_enabled)

	atlas.set_sway(true)
	for i: int in 3:
		assert_true(atlas.plant_at(i).sway_enabled)
