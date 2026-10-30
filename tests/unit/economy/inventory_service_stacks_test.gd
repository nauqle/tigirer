extends TestCase
## InventoryService: tohum yığınları (uid), ürün yığınları (imza), değer ortalaması, kayıt.

const EPSILON: float = 0.0001

var _ruleset: GeneticsRuleset
var _inventory: InventoryService


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_inventory = EconomyFixtures.make_inventory(_ruleset)


func _gene(fruit: StringName, uid: String, generation: int = 0) -> PlantGene:
	var gene: PlantGene = FarmFixtures.make_gene(fruit, uid)
	gene.generation = generation
	return gene


func _result(gene: PlantGene, quantity: int, unit_value: float) -> HarvestResult:
	return EconomyFixtures.make_result(gene, quantity, unit_value, _ruleset)


# ------------------------------------------------------------------- tohum


func test_seeds_with_the_same_uid_merge_into_one_stack() -> void:
	var gene: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "a")

	_inventory.add_seed(gene, 2)
	_inventory.add_seed(gene, 3)

	assert_eq(_inventory.seed_count("a"), 5)
	assert_eq(_inventory.seeds().size(), 1, "tek yığın")
	assert_eq(_inventory.seed_total(), 5)


func test_taking_a_seed_spends_one_and_removes_an_empty_stack() -> void:
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "a"), 2)

	var first: PlantGene = _inventory.take_seed("a")
	var second: PlantGene = _inventory.take_seed("a")
	var third: PlantGene = _inventory.take_seed("a")

	assert_not_null(first)
	assert_not_null(second)
	assert_null(third, "tohum bitti")
	assert_eq(_inventory.seeds().size(), 0, "boş yığın kalkar")


func test_peeking_a_seed_does_not_spend_it() -> void:
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "a"), 1)

	assert_not_null(_inventory.peek_seed("a"))
	assert_eq(_inventory.seed_count("a"), 1)
	assert_null(_inventory.peek_seed("zzz"))


func test_seed_list_is_ordered_by_generation_then_uid() -> void:
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "z", 0))
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "b", 2))
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "a", 2))

	var uids: Array[String] = []
	for item: SeedItem in _inventory.seeds():
		uids.append(item.gene.uid)

	assert_eq(uids, ["z", "a", "b"] as Array[String])


func test_adding_nothing_or_a_non_positive_count_changes_nothing() -> void:
	var count: Dictionary = {"n": 0}
	_inventory.changed.connect(func() -> void: count["n"] += 1)

	_inventory.add_seed(null, 3)
	_inventory.add_seed(_gene(GeneticsFixtures.FRUIT_A, "a"), 0)

	assert_eq(count["n"], 0)
	assert_eq(_inventory.seed_total(), 0)


# -------------------------------------------------------------------- ürün


func test_produce_of_the_same_signature_merges_and_averages_the_value() -> void:
	var gene: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "a")

	_inventory.add_produce(_result(gene, 3, 10.0))
	_inventory.add_produce(_result(gene, 3, 12.0))

	assert_eq(_inventory.stacks().size(), 1)
	var stack: ProduceStack = _inventory.stacks()[0]
	assert_eq(stack.count, 6)
	assert_almost_eq(stack.total_value, 66.0, EPSILON)
	assert_almost_eq(stack.average_value(), 11.0, EPSILON)
	assert_eq(stack.fruit_id(), GeneticsFixtures.FRUIT_A)
	assert_eq(_inventory.produce_count(), 6)
	assert_almost_eq(_inventory.produce_value(), 66.0, EPSILON)


func test_different_mutation_sets_make_different_stacks_ordered_by_value() -> void:
	var plain: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "a")
	var glowing: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "b")
	glowing.mutations = [GeneticsFixtures.M_GLOW]

	_inventory.add_produce(_result(plain, 3, 10.0))
	_inventory.add_produce(_result(glowing, 3, 30.0))

	var stacks: Array[ProduceStack] = _inventory.stacks()
	assert_eq(stacks.size(), 2)
	assert_true(stacks[0].average_value() > stacks[1].average_value(), "değerli yığın önce")


func test_removing_produce_returns_the_average_value_and_drops_empty_stacks() -> void:
	var gene: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "a")
	_inventory.add_produce(_result(gene, 6, 11.0))
	var signature: StringName = _inventory.stacks()[0].signature

	var removed_value: float = _inventory.remove_produce(signature, 2)

	assert_almost_eq(removed_value, 22.0, EPSILON)
	assert_eq(_inventory.stack(signature).count, 4)
	assert_almost_eq(_inventory.stack(signature).total_value, 44.0, EPSILON)

	var rest: float = _inventory.remove_produce(signature, 99)

	assert_almost_eq(rest, 44.0, EPSILON, "yalnızca kalanı çıkarır")
	assert_null(_inventory.stack(signature), "boş yığın kalkar")
	assert_almost_eq(_inventory.remove_produce(signature, 1), 0.0, EPSILON, "olmayan yığın")


func test_changes_announce_themselves() -> void:
	var count: Dictionary = {"n": 0}
	_inventory.changed.connect(func() -> void: count["n"] += 1)
	var gene: PlantGene = _gene(GeneticsFixtures.FRUIT_A, "a")

	_inventory.add_seed(gene)
	_inventory.take_seed("a")
	_inventory.add_produce(_result(gene, 1, 5.0))
	_inventory.remove_produce(_inventory.stacks()[0].signature, 1)

	assert_eq(count["n"], 4)


# -------------------------------------------------------------------- kayıt


func test_the_inventory_survives_a_round_trip_through_json() -> void:
	var gene: PlantGene = _gene(GeneticsFixtures.FRUIT_B, "keep", 3)
	_inventory.add_seed(gene, 4)
	_inventory.add_produce(_result(gene, 5, 20.0))

	var text: String = JSON.stringify(_inventory.to_dict())
	var restored: InventoryService = EconomyFixtures.make_inventory(_ruleset)
	restored.load_dict(JSON.parse_string(text) as Dictionary)

	assert_eq(restored.seed_count("keep"), 4)
	assert_eq(restored.peek_seed("keep").generation, 3)
	assert_eq(restored.produce_count(), 5)
	assert_almost_eq(restored.produce_value(), 100.0, EPSILON)
	assert_eq(restored.stacks()[0].signature, _inventory.stacks()[0].signature, "imza yeniden hesaplandı")


func test_corrupt_entries_are_skipped_on_load() -> void:
	var data: Dictionary = {"seeds": [{"gene": {"stem": ["x"]}, "count": 2}, 5], "produce": [{"gene": 3}]}

	_inventory.load_dict(data)

	assert_eq(_inventory.seed_total(), 0)
	assert_eq(_inventory.produce_count(), 0)
