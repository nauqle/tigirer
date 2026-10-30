extends TestCase
## GeneticsEngine: mutasyon. Çaprazlamada %5 olasılıkla YENİ bir mutasyon çıkar; ebeveyndeki mutasyonlar
## olasılıkla çocuğa geçer; taşıma sınırı, uyumsuzluk ve ağırlıklı seçim kuralları geçerlidir.
##
## İstatistiksel testler tohumlu RNG kullanır (deterministik); toleranslar ~3.5-4 standart sapmadır.

var _ruleset: GeneticsRuleset
var _plain_parent: PlantGene


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()
	_plain_parent = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A)


## `count` çaprazlama yapar, kaç çocuğun `predicate` koşulunu sağladığını döndürür.
func _count_children(count: int, seed_value: int, parent_a: PlantGene, parent_b: PlantGene, predicate: Callable) -> int:
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(seed_value)
	var matched: int = 0
	for i: int in count:
		var result: BreedResult = GeneticsEngine.crossbreed_detailed(parent_a, parent_b, _ruleset, rng)
		if predicate.call(result):
			matched += 1
	return matched


func test_new_mutations_appear_in_about_five_percent_of_crosses() -> void:
	# Arrange: ebeveynlerde mutasyon yok; kural setinde mutasyon olasılığı %5
	var sample_size: int = 6000

	# Act
	var mutated: int = _count_children(
		sample_size, 5150, _plain_parent, _plain_parent, func(r: BreedResult) -> bool: return r.new_mutation != &""
	)

	# Assert
	assert_almost_eq(float(mutated) / sample_size, 0.05, 0.012, "yeni mutasyon ~ %5")


func test_mutation_chance_zero_never_mutates_and_one_always_does() -> void:
	# Arrange / Act
	_ruleset.mutation_chance = 0.0
	var never: int = _count_children(500, 1, _plain_parent, _plain_parent, func(r: BreedResult) -> bool: return r.new_mutation != &"")
	_ruleset.mutation_chance = 1.0
	var always: int = _count_children(500, 1, _plain_parent, _plain_parent, func(r: BreedResult) -> bool: return r.new_mutation != &"")

	# Assert
	assert_eq(never, 0, "olasılık 0")
	assert_eq(always, 500, "olasılık 1")


func test_mutation_chance_bonus_adds_to_the_base_chance_and_is_clamped() -> void:
	# Arrange: %5 + %45 bonus = %50
	var sample_size: int = 2000
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(77)
	var with_bonus: int = 0
	var saturated: int = 0

	# Act
	for i: int in sample_size:
		if GeneticsEngine.crossbreed_detailed(_plain_parent, _plain_parent, _ruleset, rng, 0.45).new_mutation != &"":
			with_bonus += 1
		if GeneticsEngine.crossbreed_detailed(_plain_parent, _plain_parent, _ruleset, rng, 5.0).new_mutation != &"":
			saturated += 1

	# Assert
	assert_almost_eq(float(with_bonus) / sample_size, 0.5, 0.045, "%5 + bonus = %50")
	assert_eq(saturated, sample_size, "olasılık 1'e kırpılır")


func test_a_mutation_in_one_parent_passes_to_about_half_of_the_children() -> void:
	# Arrange: yeni mutasyon kapalı (yalnızca kalıtımı ölç); tek ebeveyn taşıyor
	_ruleset.mutation_chance = 0.0
	var carrier: PlantGene = _plain_parent.copy()
	carrier.mutations = [GeneticsFixtures.M_GLOW]
	var sample_size: int = 2000

	# Act
	var inherited: int = _count_children(
		sample_size, 12, carrier, _plain_parent, func(r: BreedResult) -> bool: return r.child.mutations.has(GeneticsFixtures.M_GLOW)
	)

	# Assert
	assert_almost_eq(float(inherited) / sample_size, 0.5, 0.045, "tek taşıyıcı: %50")


func test_a_mutation_in_both_parents_passes_to_about_three_quarters() -> void:
	# Arrange: iki taşıyıcı -> 1 - (1 - 0.5)^2 = 0.75
	_ruleset.mutation_chance = 0.0
	var carrier: PlantGene = _plain_parent.copy()
	carrier.mutations = [GeneticsFixtures.M_GLOW]
	var sample_size: int = 2000

	# Act
	var inherited: int = _count_children(
		sample_size, 13, carrier, carrier, func(r: BreedResult) -> bool: return r.child.mutations.has(GeneticsFixtures.M_GLOW)
	)

	# Assert
	assert_almost_eq(float(inherited) / sample_size, 0.75, 0.04, "iki taşıyıcı: %75")


func test_inherited_mutations_are_reported_in_the_result() -> void:
	# Arrange: kalıtım olasılığı 1 -> mutasyon kesin geçer
	_ruleset.mutation_chance = 0.0
	_ruleset.mutation_inherit_chance = 1.0
	var carrier: PlantGene = _plain_parent.copy()
	carrier.mutations = [GeneticsFixtures.M_GOLD]

	# Act
	var result: BreedResult = GeneticsEngine.crossbreed_detailed(carrier, _plain_parent, _ruleset, GeneticsFixtures.make_rng(1))

	# Assert
	assert_eq(result.inherited_mutations, [GeneticsFixtures.M_GOLD] as Array[StringName], "miras listesi")
	assert_eq(result.new_mutation, &"", "yeni mutasyon yok")


func test_new_mutation_is_reported_and_added_to_the_child() -> void:
	# Arrange: olasılık 1 -> kesin yeni mutasyon
	_ruleset.mutation_chance = 1.0

	# Act
	var result: BreedResult = GeneticsEngine.crossbreed_detailed(_plain_parent, _plain_parent, _ruleset, GeneticsFixtures.make_rng(4))

	# Assert
	assert_ne(result.new_mutation, &"", "yeni mutasyon bildirilmeli")
	assert_true(result.child.mutations.has(result.new_mutation), "çocuğun mutasyon listesinde olmalı")
	assert_eq(result.child.mutations.size(), 1, "tam bir mutasyon")


func test_child_never_exceeds_the_mutation_cap() -> void:
	# Arrange: sınır 1; iki ebeveyn farklı mutasyonlar taşıyor, kalıtım ve yeni mutasyon kesin
	_ruleset.max_mutations = 1
	_ruleset.mutation_chance = 1.0
	_ruleset.mutation_inherit_chance = 1.0
	var parent_a: PlantGene = _plain_parent.copy()
	parent_a.mutations = [GeneticsFixtures.M_GLOW]
	var parent_b: PlantGene = _plain_parent.copy()
	parent_b.mutations = [GeneticsFixtures.M_FAST]
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(21)

	# Act / Assert
	for i: int in 300:
		var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, _ruleset, rng)
		assert_true(child.mutations.size() <= 1, "en fazla 1 mutasyon: %s" % str(child.mutations))


func test_a_mutation_is_never_added_twice() -> void:
	# Arrange: ebeveyn glow taşıyor (kesin geçer), yeni mutasyon da kesin; glow bir daha seçilmemeli
	_ruleset.mutation_chance = 1.0
	_ruleset.mutation_inherit_chance = 1.0
	var carrier: PlantGene = _plain_parent.copy()
	carrier.mutations = [GeneticsFixtures.M_GLOW]
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(22)

	# Act / Assert
	for i: int in 300:
		var child: PlantGene = GeneticsEngine.crossbreed(carrier, _plain_parent, _ruleset, rng)
		assert_eq(child.mutations.count(GeneticsFixtures.M_GLOW), 1, "glow tam bir kez: %s" % str(child.mutations))


func test_a_mutation_never_appears_next_to_one_it_excludes() -> void:
	# Arrange: kimera altını dışlar. Ebeveyn altın taşıyor (kesin geçer), yeni mutasyon kesin.
	_ruleset.mutation_chance = 1.0
	_ruleset.mutation_inherit_chance = 1.0
	var golden: PlantGene = _plain_parent.copy()
	golden.mutations = [GeneticsFixtures.M_GOLD]
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(23)

	# Act / Assert
	for i: int in 400:
		var child: PlantGene = GeneticsEngine.crossbreed(golden, _plain_parent, _ruleset, rng)
		assert_false(child.mutations.has(GeneticsFixtures.M_CHIMERA), "altın varken kimera çıkmamalı: %s" % str(child.mutations))


func test_new_mutations_are_picked_by_weight() -> void:
	# Arrange: yalnızca iki mutasyon: yaygın (ağırlık 90) ve nadir (ağırlık 10)
	var common: MutationDef = GeneticsFixtures.make_mutation(&"common", 90.0)
	var rare: MutationDef = GeneticsFixtures.make_mutation(&"rare", 10.0)
	_ruleset.mutations = [common, rare]
	_ruleset.mutation_chance = 1.0
	var sample_size: int = 3000

	# Act
	var rare_count: int = _count_children(
		sample_size, 24, _plain_parent, _plain_parent, func(r: BreedResult) -> bool: return r.new_mutation == &"rare"
	)

	# Assert
	assert_almost_eq(float(rare_count) / sample_size, 0.10, 0.03, "nadir mutasyon ~ %10")


func test_unknown_inherited_mutation_ids_are_dropped_without_error() -> void:
	# Arrange: ebeveyn, kural setinde olmayan (eski kayıttan) bir mutasyon taşıyor
	_ruleset.mutation_chance = 0.0
	_ruleset.mutation_inherit_chance = 1.0
	var old_save: PlantGene = _plain_parent.copy()
	old_save.mutations = [&"m_silinmis"]

	# Act
	var child: PlantGene = GeneticsEngine.crossbreed(old_save, _plain_parent, _ruleset, GeneticsFixtures.make_rng(25))

	# Assert
	assert_true(child.mutations.is_empty(), "bilinmeyen mutasyon aktarılmaz")
