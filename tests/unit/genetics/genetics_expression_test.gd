extends TestCase
## GeneticsEngine.express: genotipten fenotipe. Baskın/çekinik parçalar, sayısal özelliklerin
## ifadesi, ton karışımı, mutasyon etkileri ve tohum kütüphanesi imzası.

const EPSILON: float = 0.00001

var _ruleset: GeneticsRuleset


func before_each() -> void:
	_ruleset = GeneticsFixtures.make_ruleset()


func _gene_with_stem(first: StringName, second: StringName) -> PlantGene:
	var gene: PlantGene = GeneticsFixtures.make_gene(GeneticsFixtures.STEM_A, GeneticsFixtures.LEAF_A, GeneticsFixtures.FRUIT_A)
	gene.stem_alleles = [first, second]
	return gene


# ---------------------------------------------------------------- baskınlık


func test_dominant_part_hides_the_recessive_one_in_either_order() -> void:
	# Arrange / Act
	var dominant_first: PlantPhenotype = GeneticsEngine.express(
		_gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_R), _ruleset
	)
	var dominant_second: PlantPhenotype = GeneticsEngine.express(
		_gene_with_stem(GeneticsFixtures.STEM_R, GeneticsFixtures.STEM_A), _ruleset
	)

	# Assert
	assert_eq(dominant_first.stem_id, GeneticsFixtures.STEM_A, "baskın önde")
	assert_eq(dominant_second.stem_id, GeneticsFixtures.STEM_A, "sıra önemsiz")


func test_recessive_part_shows_only_when_both_alleles_are_recessive() -> void:
	var phenotype: PlantPhenotype = GeneticsEngine.express(
		_gene_with_stem(GeneticsFixtures.STEM_R, GeneticsFixtures.STEM_R), _ruleset
	)

	assert_eq(phenotype.stem_id, GeneticsFixtures.STEM_R)


func test_equal_dominance_picks_the_alphabetically_smaller_id_in_either_order() -> void:
	# Arrange: iki parçanın baskınlığı eşit
	_ruleset.parts.append(GeneticsFixtures.make_part(&"stem_c", PlantPartDef.Layer.STEM, 2))
	_ruleset.rebuild_index()

	# Act
	var forward: PlantPhenotype = GeneticsEngine.express(_gene_with_stem(GeneticsFixtures.STEM_A, &"stem_c"), _ruleset)
	var backward: PlantPhenotype = GeneticsEngine.express(_gene_with_stem(&"stem_c", GeneticsFixtures.STEM_A), _ruleset)

	# Assert: "stem_a" < "stem_c"
	assert_eq(forward.stem_id, GeneticsFixtures.STEM_A)
	assert_eq(backward.stem_id, GeneticsFixtures.STEM_A)


func test_unknown_part_id_loses_to_a_known_one() -> void:
	# Eski bir kayıttan kalan, kural setinde olmayan bir parça kimliği
	var phenotype: PlantPhenotype = GeneticsEngine.express(_gene_with_stem(&"stem_silinmis", GeneticsFixtures.STEM_R), _ruleset)

	assert_eq(phenotype.stem_id, GeneticsFixtures.STEM_R, "bilinen çekinik bile bilinmeyeni yener")


func test_recessive_trait_reappears_in_a_quarter_of_carrier_offspring() -> void:
	# Arrange: taşıyıcı x taşıyıcı (Aa x Aa) -> çekinik ifade olasılığı 1/4
	var carrier: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_R)
	var rng: RandomNumberGenerator = GeneticsFixtures.make_rng(31337)
	var sample_size: int = 4000
	var recessive_shown: int = 0

	# Act
	for i: int in sample_size:
		var child: PlantGene = GeneticsEngine.crossbreed(carrier, carrier, _ruleset, rng)
		if GeneticsEngine.express(child, _ruleset).stem_id == GeneticsFixtures.STEM_R:
			recessive_shown += 1

	# Assert: iki ebeveyn de çekinik özelliği GÖRÜNMEDEN taşıyor, çocukların ~%25'inde ortaya çıkıyor
	assert_almost_eq(float(recessive_shown) / sample_size, 0.25, 0.03, "çekinik ~ 1/4")


# ---------------------------------------------------------- sayısal özellikler


func test_quantitative_traits_blend_by_the_dominance_setting() -> void:
	# Arrange
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.growth_alleles = PackedFloat32Array([1.0, 2.0])

	# Act / Assert: 0.5 = ortalama, 1.0 = büyük alel baskın, 0.0 = küçük alel baskın
	_ruleset.quant_dominance = 0.5
	assert_almost_eq(GeneticsEngine.express(gene, _ruleset).growth_speed, 1.5, EPSILON, "eklemeli")
	_ruleset.quant_dominance = 1.0
	assert_almost_eq(GeneticsEngine.express(gene, _ruleset).growth_speed, 2.0, EPSILON, "büyük baskın")
	_ruleset.quant_dominance = 0.0
	assert_almost_eq(GeneticsEngine.express(gene, _ruleset).growth_speed, 1.0, EPSILON, "küçük baskın")


func test_market_value_is_fruit_base_value_times_the_value_gene() -> void:
	# Arrange: meyve a'nın taban değeri 10; değer geni 1.5 ve 2.5 -> ortalama 2.0 -> 20
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.value_alleles = PackedFloat32Array([1.5, 2.5])

	# Act
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	# Assert
	assert_almost_eq(phenotype.market_value, 20.0, EPSILON)


func test_neutral_genotype_has_neutral_traits() -> void:
	var phenotype: PlantPhenotype = GeneticsEngine.express(_gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A), _ruleset)

	assert_almost_eq(phenotype.growth_speed, 1.0, EPSILON, "büyüme")
	assert_almost_eq(phenotype.water_use, 1.0, EPSILON, "su")
	assert_false(phenotype.is_luminous(), "parlama yok")
	assert_almost_eq(phenotype.shimmer, 0.0, EPSILON, "parıltı yok")
	assert_almost_eq(phenotype.tint_override.a, 0.0, EPSILON, "renk zorlaması yok")


# --------------------------------------------------------------------- renk


func test_hue_of_alleles_across_the_seam_averages_the_short_way() -> void:
	# Arrange: 0.95 ve 0.05 iki kırmızıya yakın ton; ortalama camgöbeği (0.5) OLMAMALI
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.hue_alleles = PackedFloat32Array([0.95, 0.05])

	# Act
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	# Assert
	assert_almost_eq(ColorMath.hue_distance(phenotype.hue, 0.0), 0.0, 0.0001, "kırmızı civarı")


# ---------------------------------------------------------------- mutasyonlar


func test_mutation_multipliers_multiply_with_each_other_and_with_the_genes() -> void:
	# Arrange: değer: meyve 10 x gen 1.0 x glow 1.5 x gold 3.0 = 45
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.mutations = [GeneticsFixtures.M_GLOW, GeneticsFixtures.M_GOLD, GeneticsFixtures.M_FAST]

	# Act
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	# Assert
	assert_almost_eq(phenotype.market_value, 45.0, EPSILON, "değer çarpanları çarpılır")
	assert_almost_eq(phenotype.growth_speed, 1.6, EPSILON, "hızlı büyüme çarpanı")


func test_visual_mutation_effects_come_from_the_strongest_source() -> void:
	# Arrange
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.mutations = [GeneticsFixtures.M_GLOW, GeneticsFixtures.M_GOLD, GeneticsFixtures.M_CHIMERA]

	# Act
	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	# Assert
	assert_true(phenotype.is_luminous(), "parlayan mutasyon var")
	assert_almost_eq(phenotype.glow_strength, 1.0, EPSILON, "parlama gücü")
	assert_almost_eq(phenotype.shimmer, 0.6, EPSILON, "parıltı altından")
	assert_almost_eq(phenotype.tint_override.a, 1.0, EPSILON, "altın rengi zorlar")
	assert_almost_eq(
		ColorMath.hue_distance(phenotype.fruit_hue, ColorMath.wrap_hue(phenotype.hue + 0.5)), 0.0, 0.0001, "kimera tamamlayıcı ton"
	)


func test_unknown_mutation_ids_are_ignored_without_error() -> void:
	# Eski bir kayıttan kalan, kural setinde olmayan mutasyon
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	gene.mutations = [&"m_silinmis", GeneticsFixtures.M_FAST]

	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	assert_eq(phenotype.mutations, [GeneticsFixtures.M_FAST] as Array[StringName], "yalnızca bilinen mutasyon kalır")
	assert_almost_eq(phenotype.growth_speed, 1.6, EPSILON)


# ------------------------------------------------------------------- imza


func test_genotypes_with_the_same_visible_traits_share_a_signature() -> void:
	# Arrange: AA ve Aa (A baskın) aynı görünür; imza fenotipten türetilir, genotipten değil
	var homozygous: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	var carrier: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_R)

	# Assert
	assert_eq(
		GeneticsEngine.express(homozygous, _ruleset).signature,
		GeneticsEngine.express(carrier, _ruleset).signature,
		"aynı görünüm = aynı imza"
	)


func test_signature_changes_with_parts_hue_slice_and_mutation_set() -> void:
	# Arrange
	var base: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	var other_part: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_B, GeneticsFixtures.STEM_B)
	var other_hue: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	other_hue.hue_alleles = PackedFloat32Array([0.8, 0.8])
	var mutated: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	mutated.mutations = [GeneticsFixtures.M_GLOW]
	var base_signature: StringName = GeneticsEngine.express(base, _ruleset).signature

	# Assert
	assert_ne(GeneticsEngine.express(other_part, _ruleset).signature, base_signature, "farklı parça")
	assert_ne(GeneticsEngine.express(other_hue, _ruleset).signature, base_signature, "farklı ton dilimi")
	assert_ne(GeneticsEngine.express(mutated, _ruleset).signature, base_signature, "farklı mutasyon")


func test_signature_ignores_mutation_order_and_tiny_hue_differences_inside_a_slice() -> void:
	# Arrange
	var first: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	first.mutations = [GeneticsFixtures.M_GLOW, GeneticsFixtures.M_FAST]
	first.hue_alleles = PackedFloat32Array([0.300, 0.300])
	var second: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_A, GeneticsFixtures.STEM_A)
	second.mutations = [GeneticsFixtures.M_FAST, GeneticsFixtures.M_GLOW]
	second.hue_alleles = PackedFloat32Array([0.305, 0.305])

	# Assert: 24 dilimde 0.300 ve 0.305 aynı dilimde
	assert_eq(GeneticsEngine.express(first, _ruleset).signature, GeneticsEngine.express(second, _ruleset).signature)


func test_morph_id_names_only_the_three_parts() -> void:
	var gene: PlantGene = _gene_with_stem(GeneticsFixtures.STEM_B, GeneticsFixtures.STEM_B)
	gene.mutations = [GeneticsFixtures.M_GLOW]

	var phenotype: PlantPhenotype = GeneticsEngine.express(gene, _ruleset)

	assert_eq(phenotype.morph_id, &"stem_b|leaf_a|fruit_a", "şekil: ton ve mutasyon içermez")
