extends TestCase
## SeedDex: tür ve varyant keşfi, en değerli örnek, tamamlanma oranı, sıralama ve kayıt.
## Kural seti (GeneticsFixtures): 3 gövde x 3 yaprak x 3 meyve = 27 tür.

const EPSILON: float = 0.0001

var _ruleset: GeneticsRuleset
var _dex: SeedDex


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_dex = SeedDex.new()


func _gene(stem: StringName, leaf: StringName, fruit: StringName, uid: String, hue: float = 0.3) -> PlantGene:
	var gene: PlantGene = PlantGene.homozygous(stem, leaf, fruit, hue)
	gene.uid = uid
	return gene


func _record(gene: PlantGene, day: int = 1) -> SeedDex.Discovery:
	return _dex.record(gene, GeneticsEngine.express(gene, _ruleset), day)


func test_the_first_sight_of_a_species_is_a_new_species_and_a_new_variant() -> void:
	var found: SeedDex.Discovery = _record(_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a"))

	assert_true(found.new_species)
	assert_true(found.new_variant)
	assert_eq(found.morph_id, &"stem_a|leaf_a|fruit_a")
	assert_eq(_dex.species_count(), 1)
	assert_eq(_dex.variant_count(), 1)
	assert_true(_dex.has_species(found.morph_id))


func test_seeing_the_exact_same_signature_again_discovers_nothing_but_counts_the_sighting() -> void:
	var gene: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a")
	_record(gene)

	var again: SeedDex.Discovery = _record(gene)

	assert_false(again.new_species)
	assert_false(again.new_variant)
	assert_eq(_dex.entry(again.morph_id).times_seen, 2)
	assert_eq(_dex.variant_count(), 1)


func test_a_new_hue_or_mutation_of_a_known_species_is_only_a_new_variant() -> void:
	var plain: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "plain", 0.1)
	var other_hue: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "hue", 0.6)
	var glowing: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "glow", 0.1)
	glowing.mutations = [GeneticsFixtures.M_GLOW]
	_record(plain)

	var hue_found: SeedDex.Discovery = _record(other_hue)
	var mutation_found: SeedDex.Discovery = _record(glowing)

	assert_false(hue_found.new_species)
	assert_true(hue_found.new_variant, "ton dilimi farklı")
	assert_false(mutation_found.new_species)
	assert_true(mutation_found.new_variant, "mutasyon kümesi farklı")
	assert_eq(_dex.species_count(), 1)
	assert_eq(_dex.variant_count(), 3)


func test_the_entry_keeps_the_most_valuable_sample_and_its_value() -> void:
	var cheap: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_B, "cheap")
	var rich: PlantGene = _gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_B, "rich")
	rich.value_alleles = PackedFloat32Array([3.0, 3.0])
	_record(cheap)

	_record(rich)

	var entry: SeedDex.Entry = _dex.entry(&"stem_a|leaf_a|fruit_b")
	assert_eq(entry.sample.uid, "rich", "değerli örnek temsil eder")
	assert_almost_eq(entry.best_value, 60.0, EPSILON, "FRUIT_B 20 x 3.0")


func test_completion_is_discovered_over_total_species() -> void:
	assert_eq(_dex.total_species(_ruleset), 27)
	assert_almost_eq(_dex.completion(_ruleset), 0.0, EPSILON)

	_record(_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a"))
	_record(_gene(GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "b"))
	_record(_gene(GeneticsFixtures.STEM_R, GeneticsFixtures.LEAF_R, GeneticsFixtures.FRUIT_R, "c"))

	assert_almost_eq(_dex.completion(_ruleset), 3.0 / 27.0, EPSILON)


func test_entries_are_sorted_by_species_id_and_remember_the_first_day() -> void:
	_record(_gene(GeneticsFixtures.STEM_R, GeneticsFixtures.LEAF_R, GeneticsFixtures.FRUIT_R, "z"), 5)
	_record(_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a"), 2)

	var ids: Array[String] = []
	for entry: SeedDex.Entry in _dex.entries():
		ids.append(String(entry.morph_id))

	assert_eq(ids, ["stem_a|leaf_a|fruit_a", "stem_r|leaf_r|fruit_r"] as Array[String])
	assert_eq(_dex.entry(&"stem_r|leaf_r|fruit_r").first_day, 5)


func test_the_dex_survives_a_json_round_trip_and_clear_empties_it() -> void:
	var glowing: PlantGene = _gene(GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_B, GeneticsFixtures.FRUIT_B, "g")
	glowing.mutations = [GeneticsFixtures.M_GLOW]
	_record(glowing, 3)
	_record(_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a"), 4)
	var restored: SeedDex = SeedDex.new()

	restored.load_dict(JSON.parse_string(JSON.stringify(_dex.to_dict())) as Dictionary)

	assert_eq(restored.species_count(), 2)
	assert_eq(restored.variant_count(), 2)
	assert_eq(restored.entry(&"stem_b|leaf_b|fruit_b").first_day, 3)
	assert_eq(restored.entry(&"stem_b|leaf_b|fruit_b").sample.mutations, [GeneticsFixtures.M_GLOW] as Array[StringName])
	var again: SeedDex.Discovery = restored.record(glowing, GeneticsEngine.express(glowing, _ruleset), 9)
	assert_false(again.new_variant, "yüklenen imzalar hatırlanır")

	restored.clear()
	assert_eq(restored.species_count(), 0)
	assert_eq(restored.variant_count(), 0)


func test_corrupt_entries_are_skipped_on_load() -> void:
	_dex.load_dict({"entries": [{"morph": "", "sample": {}}, {"morph": "x", "sample": {"stem": ["a"]}}, 7]})

	assert_eq(_dex.species_count(), 0)
