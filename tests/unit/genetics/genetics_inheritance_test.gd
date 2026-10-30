extends TestCase
## GeneticsEngine.crossbreed: Mendel kalıtımı. Her ebeveyn çocuğa iki aleinden BİRİNİ verir (ayrışma),
## lokuslar birbirinden bağımsız dağılır, sayısal alellere küçük sapma eklenir, soy bilgisi doğru tutulur.
##
## İstatistiksel testler tohumlu RNG kullanır: sonuç her çalıştırmada aynıdır (deterministik), ama
## toleranslar tohum seçiminden bağımsız olacak genişlikte tutulmuştur (~3.5 standart sapma).

const EPSILON: float = 0.00001
const SAMPLE_SIZE: int = 4000


func _heterozygous(stem_pair: Array[StringName], leaf_pair: Array[StringName]) -> PlantGene:
	var gene: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	gene.stem_alleles = stem_pair
	gene.leaf_alleles = leaf_pair
	return gene


func test_each_child_allele_comes_from_the_matching_parent() -> void:
	# Arrange: ebeveynler homozigot ve farklı; çocuk tam olarak [anne aleli, baba aleli] olmalı
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var parent_a: PlantGene = GeneticsFixtures.make_gene(
		GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a"
	)
	var parent_b: PlantGene = GeneticsFixtures.make_gene(
		GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_B, GeneticsFixtures.FRUIT_B, "b"
	)

	# Act
	var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, GeneticsFixtures.make_rng(1))

	# Assert
	assert_not_null(child, "çocuk üretilmeli")
	assert_eq(child.stem_alleles, [GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_B] as Array[StringName], "gövde")
	assert_eq(child.leaf_alleles, [GeneticsFixtures.LEAF_A, GeneticsFixtures.LEAF_B] as Array[StringName], "yaprak")
	assert_eq(child.fruit_alleles, [GeneticsFixtures.FRUIT_A, GeneticsFixtures.FRUIT_B] as Array[StringName], "meyve")


func test_heterozygous_cross_segregates_one_to_two_to_one() -> void:
	# Arrange: Aa x Aa -> AA : Aa : aa = 1 : 2 : 1 (Mendel'in ayrışma yasası)
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var heterozygote: PlantGene = _heterozygous(
		[GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_B] as Array[StringName],
		[GeneticsFixtures.LEAF_A, GeneticsFixtures.LEAF_A] as Array[StringName]
	)
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(20240601)
	var both_a: int = 0
	var mixed: int = 0
	var both_b: int = 0

	# Act
	for i: int in SAMPLE_SIZE:
		var child: PlantGene = GeneticsEngine.crossbreed(heterozygote, heterozygote, ruleset, rng)
		var a_count: int = child.stem_alleles.count(GeneticsFixtures.STEM_A)
		if a_count == 2:
			both_a += 1
		elif a_count == 1:
			mixed += 1
		else:
			both_b += 1

	# Assert
	assert_almost_eq(float(both_a) / SAMPLE_SIZE, 0.25, 0.03, "AA ~ 1/4")
	assert_almost_eq(float(mixed) / SAMPLE_SIZE, 0.50, 0.03, "Aa ~ 1/2")
	assert_almost_eq(float(both_b) / SAMPLE_SIZE, 0.25, 0.03, "aa ~ 1/4")


func test_different_loci_assort_independently() -> void:
	# Arrange: iki lokusta da heterozigot ebeveynler; çocuğun İKİ lokusta da çift-A olma olasılığı
	# (1/4) x (1/4) = 1/16 olmalı. Bağımlı olsaydı 1/4'e yaklaşırdı.
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var dihybrid: PlantGene = _heterozygous(
		[GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_B] as Array[StringName],
		[GeneticsFixtures.LEAF_A, GeneticsFixtures.LEAF_B] as Array[StringName]
	)
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(7)
	var double_a: int = 0

	# Act
	for i: int in SAMPLE_SIZE:
		var child: PlantGene = GeneticsEngine.crossbreed(dihybrid, dihybrid, ruleset, rng)
		if child.stem_alleles.count(GeneticsFixtures.STEM_A) == 2 and child.leaf_alleles.count(GeneticsFixtures.LEAF_A) == 2:
			double_a += 1

	# Assert
	assert_almost_eq(float(double_a) / SAMPLE_SIZE, 1.0 / 16.0, 0.015, "iki lokus bağımsız: 1/16")


func test_quantitative_alleles_pass_unchanged_when_drift_is_zero() -> void:
	# Arrange
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.quant_drift = 0.0
	var parent_a: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_a.growth_alleles = PackedFloat32Array([0.8, 1.2])
	var parent_b: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_b.growth_alleles = PackedFloat32Array([1.5, 2.0])
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(3)

	# Act / Assert: ilk alel anneden, ikinci alel babadan gelmeli
	for i: int in 200:
		var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, rng)
		var from_a: bool = is_equal_approx(child.growth_alleles[0], 0.8) or is_equal_approx(child.growth_alleles[0], 1.2)
		var from_b: bool = is_equal_approx(child.growth_alleles[1], 1.5) or is_equal_approx(child.growth_alleles[1], 2.0)
		assert_true(from_a and from_b, "alel ebeveyn çiftinden gelmeli: %s" % str(child.growth_alleles))


func test_quantitative_alleles_segregate_evenly_between_the_two_parent_alleles() -> void:
	# Arrange: sapma kapalı. Her ebeveynin İKİ aleli de çocuğa ~yarı yarıya geçmeli (ayrışma yasası),
	# yalnızca "ebeveynin alellerinden biri" olması yetmez: hep aynı alelin geçmesi de bunu sağlar.
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.quant_drift = 0.0
	var parent_a: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_a.growth_alleles = PackedFloat32Array([0.8, 1.2])
	var parent_b: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_b.growth_alleles = PackedFloat32Array([1.5, 2.0])
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(9001)
	var low_from_a: int = 0
	var low_from_b: int = 0

	# Act
	for i: int in SAMPLE_SIZE:
		var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, rng)
		if is_equal_approx(child.growth_alleles[0], 0.8):
			low_from_a += 1
		if is_equal_approx(child.growth_alleles[1], 1.5):
			low_from_b += 1

	# Assert
	assert_almost_eq(float(low_from_a) / SAMPLE_SIZE, 0.5, 0.03, "anne: küçük alel ~ yarı yarıya")
	assert_almost_eq(float(low_from_b) / SAMPLE_SIZE, 0.5, 0.03, "baba: küçük alel ~ yarı yarıya")


func test_hue_alleles_segregate_evenly_between_the_two_parent_alleles() -> void:
	# Arrange: ton sapması kapalı; iki ebeveynin ton alelleri farklı
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.hue_drift = 0.0
	var parent_a: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_a.hue_alleles = PackedFloat32Array([0.1, 0.2])
	var parent_b: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	parent_b.hue_alleles = PackedFloat32Array([0.6, 0.7])
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(9002)
	var first_from_a: int = 0
	var first_from_b: int = 0

	# Act
	for i: int in SAMPLE_SIZE:
		var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, rng)
		if is_equal_approx(child.hue_alleles[0], 0.1):
			first_from_a += 1
		if is_equal_approx(child.hue_alleles[1], 0.6):
			first_from_b += 1

	# Assert
	assert_almost_eq(float(first_from_a) / SAMPLE_SIZE, 0.5, 0.03, "anne: 0.1 aleli ~ yarı yarıya")
	assert_almost_eq(float(first_from_b) / SAMPLE_SIZE, 0.5, 0.03, "baba: 0.6 aleli ~ yarı yarıya")


func test_quantitative_drift_creates_variation_but_stays_inside_the_range() -> void:
	# Arrange: büyük sapma; yine de hiçbir alel aralığın dışına çıkmamalı
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.quant_drift = 0.5
	var parent: PlantGene = GeneticsFixtures.make_gene(&"x", &"x", GeneticsFixtures.FRUIT_A)
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(11)
	var varied: bool = false

	# Act
	for i: int in 500:
		var child: PlantGene = GeneticsEngine.crossbreed(parent, parent, ruleset, rng)
		for allele: float in child.growth_alleles:
			assert_between(allele, ruleset.growth_range.x, ruleset.growth_range.y, "büyüme aleli aralıkta")
			if not is_equal_approx(allele, 1.0):
				varied = true
		for allele: float in child.water_alleles:
			assert_between(allele, ruleset.water_range.x, ruleset.water_range.y, "su aleli aralıkta")
		for allele: float in child.value_alleles:
			assert_between(allele, ruleset.value_range.x, ruleset.value_range.y, "değer aleli aralıkta")

	# Assert
	assert_true(varied, "sapma açıkken en az bir alel 1.0'dan farklı olmalı")


func test_hue_alleles_are_inherited_and_stay_on_the_unit_circle() -> void:
	# Arrange: ton sapması açık; sonuç hep [0, 1) içinde kalmalı (dikişi aşan sapmalar sarılır)
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.hue_drift = 0.2
	var parent: PlantGene = PlantGene.homozygous(&"x", &"x", GeneticsFixtures.FRUIT_A, 0.99)
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(5)

	# Act / Assert
	for i: int in 300:
		var child: PlantGene = GeneticsEngine.crossbreed(parent, parent, ruleset, rng)
		for hue: float in child.hue_alleles:
			assert_true(hue >= 0.0 and hue < 1.0, "ton [0,1) içinde olmalı: %s" % str(hue))


func test_child_records_generation_and_parents() -> void:
	# Arrange
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var parent_a: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "uid-a")
	parent_a.generation = 2
	var parent_b: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_B, GeneticsFixtures.FRUIT_B, "uid-b")
	parent_b.generation = 5

	# Act
	var child: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, GeneticsFixtures.make_rng(2))

	# Assert
	assert_eq(child.generation, 6, "nesil = en büyük ebeveyn + 1")
	assert_eq(child.parent_uids, PackedStringArray(["uid-a", "uid-b"]), "soy kaydı")
	assert_ne(child.uid, "", "çocuğun kimliği olmalı")
	assert_ne(child.uid, "uid-a", "ebeveynin kimliğini taşımamalı")


func test_two_children_of_the_same_parents_get_different_uids() -> void:
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var parent: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "p")
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(99)
	var seen: Dictionary = {}

	for i: int in 500:
		var child: PlantGene = GeneticsEngine.crossbreed(parent, parent, ruleset, rng)
		seen[child.uid] = true

	assert_eq(seen.size(), 500, "500 çocuğun 500 farklı kimliği olmalı")


func test_crossbreed_does_not_modify_the_parents() -> void:
	# Arrange
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.quant_drift = 0.2
	var parent_a: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a")
	var parent_b: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_B, GeneticsFixtures.FRUIT_B, "b")
	parent_a.mutations = [GeneticsFixtures.M_GLOW]
	var snapshot_a: PlantGene = parent_a.copy()
	var snapshot_b: PlantGene = parent_b.copy()
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(8)

	# Act
	for i: int in 100:
		GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, rng)

	# Assert
	assert_eq(parent_a.stem_alleles, snapshot_a.stem_alleles, "A gövde")
	assert_eq(parent_a.growth_alleles, snapshot_a.growth_alleles, "A büyüme")
	assert_eq(parent_a.mutations, snapshot_a.mutations, "A mutasyonlar")
	assert_eq(parent_a.generation, snapshot_a.generation, "A nesil")
	assert_eq(parent_b.fruit_alleles, snapshot_b.fruit_alleles, "B meyve")
	assert_eq(parent_b.hue_alleles, snapshot_b.hue_alleles, "B ton")


func test_same_seed_produces_an_identical_child() -> void:
	# Arrange
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	ruleset.quant_drift = 0.1
	ruleset.hue_drift = 0.05
	var parent_a: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A, "a")
	var parent_b: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_B, GeneticsFixtures.LEAF_B, GeneticsFixtures.FRUIT_B, "b")

	# Act
	var first: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, GeneticsFixtures.make_rng(424242))
	var second: PlantGene = GeneticsEngine.crossbreed(parent_a, parent_b, ruleset, GeneticsFixtures.make_rng(424242))

	# Assert
	assert_eq(first.uid, second.uid, "uid")
	assert_eq(first.stem_alleles, second.stem_alleles, "gövde")
	assert_eq(first.growth_alleles, second.growth_alleles, "büyüme")
	assert_eq(first.hue_alleles, second.hue_alleles, "ton")
	assert_eq(first.mutations, second.mutations, "mutasyonlar")


func test_crossbreed_returns_null_for_missing_or_malformed_input() -> void:
	# Arrange
	var ruleset: GeneticsRuleset = GeneticsFixtures.make_ruleset()
	var valid: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A)
	var malformed: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A)
	malformed.stem_alleles = [GeneticsFixtures.STEM_A]
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(1)

	# Assert: hata verip çökmek yerine null döner (push_error ile bildirilir)
	assert_null(GeneticsEngine.crossbreed(null, valid, ruleset, rng), "boş ebeveyn A")
	assert_null(GeneticsEngine.crossbreed(valid, null, ruleset, rng), "boş ebeveyn B")
	assert_null(GeneticsEngine.crossbreed(valid, valid, null, rng), "boş kural seti")
	assert_null(GeneticsEngine.crossbreed(malformed, valid, ruleset, rng), "bozuk ebeveyn")
