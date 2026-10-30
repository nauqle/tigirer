extends TestCase
## PlantGene veri sınıfının testleri: kopya bağımsızlığı, yapısal sağlamlık, homozigot üretici.

const EPSILON: float = 0.00001


func test_homozygous_sets_both_alleles_of_every_part_locus_and_hue() -> void:
	# Act
	var gene: PlantGene = PlantGene.homozygous(&"s", &"l", &"f", 0.8)

	# Assert
	assert_eq(gene.stem_alleles, [&"s", &"s"] as Array[StringName], "gövde")
	assert_eq(gene.leaf_alleles, [&"l", &"l"] as Array[StringName], "yaprak")
	assert_eq(gene.fruit_alleles, [&"f", &"f"] as Array[StringName], "meyve")
	assert_almost_eq(gene.hue_alleles[0], 0.8, EPSILON, "ton 0")
	assert_almost_eq(gene.hue_alleles[1], 0.8, EPSILON, "ton 1")
	assert_eq(gene.generation, 0, "başlangıç tohumu nesil 0")


func test_homozygous_leaves_quantitative_alleles_neutral() -> void:
	var gene: PlantGene = PlantGene.homozygous(&"s", &"l", &"f")

	assert_almost_eq(gene.growth_alleles[0], 1.0, EPSILON)
	assert_almost_eq(gene.water_alleles[1], 1.0, EPSILON)
	assert_almost_eq(gene.value_alleles[0], 1.0, EPSILON)


func test_copy_is_independent_of_the_original() -> void:
	# Arrange
	var original: PlantGene = GeneticsFixtures.make_gene(&"s", &"l", &"f", "orig")
	original.generation = 3
	original.parent_uids = PackedStringArray(["p1", "p2"])
	original.mutations = [&"m_glow"]

	# Act: kopyayı her alanda değiştir
	var clone: PlantGene = original.copy()
	clone.uid = "klon"
	clone.generation = 9
	clone.parent_uids[0] = "x"
	clone.stem_alleles[0] = &"degisti"
	clone.leaf_alleles[1] = &"degisti"
	clone.fruit_alleles[0] = &"degisti"
	clone.growth_alleles[0] = 2.0
	clone.water_alleles[1] = 2.0
	clone.value_alleles[0] = 2.0
	clone.hue_alleles[1] = 0.9
	clone.mutations.append(&"m_fast")

	# Assert: asıl genotip hiçbir alanda etkilenmemeli
	assert_eq(original.uid, "orig", "uid")
	assert_eq(original.generation, 3, "nesil")
	assert_eq(original.parent_uids[0], "p1", "ebeveyn kimliği")
	assert_eq(original.stem_alleles[0], &"s", "gövde aleli")
	assert_eq(original.leaf_alleles[1], &"l", "yaprak aleli")
	assert_eq(original.fruit_alleles[0], &"f", "meyve aleli")
	assert_almost_eq(original.growth_alleles[0], 1.0, EPSILON, "büyüme")
	assert_almost_eq(original.water_alleles[1], 1.0, EPSILON, "su")
	assert_almost_eq(original.value_alleles[0], 1.0, EPSILON, "değer")
	assert_almost_eq(original.hue_alleles[1], 0.3, EPSILON, "ton")
	assert_eq(original.mutations.size(), 1, "mutasyon listesi")


func test_copy_preserves_every_field() -> void:
	var original: PlantGene = GeneticsFixtures.make_gene(&"s", &"l", &"f", "orig")
	original.display_name = "Deneme"
	original.generation = 4
	original.parent_uids = PackedStringArray(["a", "b"])
	original.growth_alleles = PackedFloat32Array([0.7, 1.9])
	original.mutations = [&"m_gold", &"m_glow"]

	var clone: PlantGene = original.copy()

	assert_eq(clone.uid, "orig")
	assert_eq(clone.display_name, "Deneme")
	assert_eq(clone.generation, 4)
	assert_eq(clone.parent_uids, original.parent_uids)
	assert_almost_eq(clone.growth_alleles[0], 0.7, EPSILON)
	assert_almost_eq(clone.growth_alleles[1], 1.9, EPSILON)
	assert_eq(clone.mutations, [&"m_gold", &"m_glow"] as Array[StringName])


func test_is_well_formed_accepts_a_complete_genotype() -> void:
	assert_true(GeneticsFixtures.make_gene(&"s", &"l", &"f").is_well_formed())


func test_is_well_formed_rejects_a_locus_without_exactly_two_alleles() -> void:
	# Arrange: her lokusu tek tek boz
	var broken_stem: PlantGene = GeneticsFixtures.make_gene(&"s", &"l", &"f")
	broken_stem.stem_alleles = [&"s"]
	var broken_growth: PlantGene = GeneticsFixtures.make_gene(&"s", &"l", &"f")
	broken_growth.growth_alleles = PackedFloat32Array([1.0, 1.0, 1.0])
	var broken_hue: PlantGene = GeneticsFixtures.make_gene(&"s", &"l", &"f")
	broken_hue.hue_alleles = PackedFloat32Array()

	# Assert
	assert_false(broken_stem.is_well_formed(), "tek gövde aleli")
	assert_false(broken_growth.is_well_formed(), "üç büyüme aleli")
	assert_false(broken_hue.is_well_formed(), "ton aleli yok")
