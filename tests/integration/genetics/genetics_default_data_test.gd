extends TestCase
## Gerçek veri dosyalarının bütünlüğü: assets/data/genetics altındaki kural seti, parçalar, mutasyonlar ve
## başlangıç tohumları yüklenebilir, tutarlı ve tasarım niyetine uygun mu? (Birim testleri koddan kurulan
## küçük bir kural seti kullanır; bu dosya GERÇEK veriyi denetler. Entegrasyon testi.)

const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const SEEDS_DIRECTORY: String = "res://assets/data/genetics/seeds"

var _ruleset: GeneticsRuleset


func before_each() -> void:
	_ruleset = load(RULESET_PATH) as GeneticsRuleset


func _load_seeds() -> Array[PlantGene]:
	var seeds: Array[PlantGene] = []
	for file_name: String in DirAccess.get_files_at(SEEDS_DIRECTORY):
		if file_name.ends_with(".tres"):
			seeds.append(load(SEEDS_DIRECTORY.path_join(file_name)) as PlantGene)
	return seeds


func test_default_ruleset_loads_and_has_no_consistency_problems() -> void:
	assert_not_null(_ruleset, "kural seti yüklenmeli")
	assert_eq(_ruleset.validate(), PackedStringArray(), "tutarsızlık olmamalı")
	assert_eq(_ruleset.parts.size(), 15, "15 parça")
	assert_eq(_ruleset.mutations.size(), 6, "6 mutasyon")


func test_default_mutation_chance_matches_the_design_brief() -> void:
	# design/game-brief.md ve proje konsepti: çaprazlamada %5 mutasyon olasılığı
	assert_almost_eq(_ruleset.mutation_chance, 0.05, 0.00001)


func test_every_part_has_a_texture_and_its_anchor_lies_inside_it() -> void:
	for part: PlantPartDef in _ruleset.parts:
		assert_not_null(part.texture, "%s dokusu" % part.id)
		if part.texture == null:
			continue
		var size: Vector2 = part.texture.get_size()
		assert_true(
			part.anchor.x >= 0.0 and part.anchor.x <= size.x and part.anchor.y >= 0.0 and part.anchor.y <= size.y,
			"%s çapası %s dokunun (%s) içinde olmalı" % [part.id, str(part.anchor), str(size)]
		)


func test_every_stem_has_leaf_mounts_and_a_fruit_mount_above_its_base() -> void:
	var stems: Array[PlantPartDef] = _ruleset.get_parts_for_layer(PlantPartDef.Layer.STEM)
	assert_eq(stems.size(), 4, "4 gövde")
	for stem: PlantPartDef in stems:
		assert_false(stem.leaf_mounts.is_empty(), "%s yaprak bağlantısı" % stem.id)
		for mount: Vector2 in stem.leaf_mounts:
			assert_true(mount.y < 0.0, "%s yaprak bağlantısı tabanın üstünde olmalı: %s" % [stem.id, str(mount)])
		assert_true(stem.fruit_mount.y < 0.0, "%s meyve bağlantısı tabanın üstünde olmalı" % stem.id)


func test_only_fruit_parts_carry_a_base_value() -> void:
	for part: PlantPartDef in _ruleset.parts:
		if part.layer == PlantPartDef.Layer.FRUIT:
			assert_true(part.base_value > 0.0, "%s taban değeri pozitif olmalı" % part.id)
		else:
			assert_almost_eq(part.base_value, 0.0, 0.00001, "%s meyve değil, taban değeri 0 olmalı" % part.id)


func test_every_layer_has_dominant_and_recessive_parts() -> void:
	# Mendel oyununun çekirdeği: her katmanda baskınlık sıralaması var ve en az bir çekinik parça var
	for layer: int in PlantPartDef.Layer.values():
		var parts: Array[PlantPartDef] = _ruleset.get_parts_for_layer(layer as PlantPartDef.Layer)
		var lowest: int = parts[0].dominance
		var highest: int = parts[0].dominance
		for part: PlantPartDef in parts:
			lowest = mini(lowest, part.dominance)
			highest = maxi(highest, part.dominance)
		assert_true(highest > lowest, "%s katmanında baskınlık farkı olmalı" % PlantPartDef.Layer.keys()[layer])
		assert_eq(lowest, 0, "%s katmanının en çekinik parçası 0 olmalı" % PlantPartDef.Layer.keys()[layer])


func test_part_ids_carry_the_prefix_of_their_layer() -> void:
	for part: PlantPartDef in _ruleset.parts:
		var id: String = String(part.id)
		match part.layer:
			PlantPartDef.Layer.STEM:
				assert_true(id.begins_with("stem_"), "%s gövde öneki" % id)
			PlantPartDef.Layer.LEAF:
				assert_true(id.begins_with("leaf_"), "%s yaprak öneki" % id)
			PlantPartDef.Layer.FRUIT:
				assert_true(id.begins_with("fruit_") or id.begins_with("flower_"), "%s meyve/çiçek öneki" % id)


func test_every_mutation_has_a_positive_weight_and_a_real_effect() -> void:
	for mutation: MutationDef in _ruleset.mutations:
		assert_true(mutation.weight > 0.0, "%s ağırlığı pozitif olmalı" % mutation.id)
		var changes_something: bool = (
			not is_equal_approx(mutation.growth_multiplier, 1.0)
			or not is_equal_approx(mutation.water_multiplier, 1.0)
			or not is_equal_approx(mutation.value_multiplier, 1.0)
			or mutation.glow_strength > 0.0
			or mutation.shimmer > 0.0
			or mutation.tint_override.a > 0.0
			or not is_zero_approx(mutation.fruit_hue_shift)
		)
		assert_true(changes_something, "%s hiçbir şeyi değiştirmiyor" % mutation.id)


func test_starter_seeds_are_valid_generation_zero_genotypes() -> void:
	var seeds: Array[PlantGene] = _load_seeds()
	assert_eq(seeds.size(), 4, "4 başlangıç tohumu")
	for gene: PlantGene in seeds:
		assert_not_null(gene, "tohum yüklenmeli")
		if gene == null:
			continue
		assert_eq(GeneticsEngine.validate(gene, _ruleset), PackedStringArray(), "%s geçerli olmalı" % gene.uid)
		assert_eq(gene.generation, 0, "%s nesil 0" % gene.uid)
		assert_ne(gene.uid, "", "kimliği olmalı")


func test_cyber_carrier_hides_its_recessive_parts_but_passes_them_on() -> void:
	# Arrange: "Siber Taşıyıcı" çekinik siber parçaları GİZLİ taşır
	var carrier: PlantGene = load(SEEDS_DIRECTORY.path_join("starter_cyber_carrier.tres")) as PlantGene
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(2026)

	# Act
	var shown: PlantPhenotype = GeneticsEngine.express(carrier, _ruleset)
	var cyber_stems: int = 0
	var sample_size: int = 2000
	for i: int in sample_size:
		var child: PlantGene = GeneticsEngine.crossbreed(carrier, carrier, _ruleset, rng)
		if GeneticsEngine.express(child, _ruleset).stem_id == &"stem_cyber":
			cyber_stems += 1

	# Assert
	assert_eq(shown.stem_id, &"stem_vine", "taşıyıcının kendisi baskın gövdeyi gösterir")
	assert_eq(shown.leaf_id, &"leaf_fern")
	assert_eq(shown.fruit_id, &"flower_star")
	assert_almost_eq(float(cyber_stems) / sample_size, 0.25, 0.03, "çocukların ~1/4'ü siber gövde gösterir")


func test_every_pair_of_starter_seeds_yields_valid_children() -> void:
	# Arrange: gerçek veriyle tüm ebeveyn çiftleri (kendisiyle dahil), her biri 25 kez
	var seeds: Array[PlantGene] = _load_seeds()
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(123)
	var invalid_found: int = 0
	var made: int = 0

	# Act
	for parent_a: PlantGene in seeds:
		for parent_b: PlantGene in seeds:
			for i: int in 25:
				var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, _ruleset, rng)
				made += 1
				if not GeneticsEngine.validate(child, _ruleset).is_empty():
					invalid_found += 1

	# Assert
	assert_eq(made, 400, "16 çift x 25 çaprazlama")
	assert_eq(invalid_found, 0, "hiçbir çocuk kural setine aykırı olmamalı (aralık, parça, mutasyon)")
