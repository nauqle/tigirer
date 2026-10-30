extends TestCase
## GeneCodec: genotip <-> sözlük dönüşümü, JSON'dan geçse bile bozulmaz; bozuk veri null verir.

const EPSILON: float = 0.0001


func _sample_gene() -> PlantGene:
	var gene: PlantGene = PlantGene.new()
	gene.uid = "abc123"
	gene.display_name = "Deneme"
	gene.generation = 4
	gene.parent_uids = PackedStringArray(["p1", "p2"])
	gene.stem_alleles = [&"stem_a", &"stem_r"]
	gene.leaf_alleles = [&"leaf_b", &"leaf_b"]
	gene.fruit_alleles = [&"fruit_r", &"fruit_a"]
	gene.growth_alleles = PackedFloat32Array([1.25, 0.75])
	gene.water_alleles = PackedFloat32Array([0.9, 1.1])
	gene.value_alleles = PackedFloat32Array([2.5, 3.0])
	gene.hue_alleles = PackedFloat32Array([0.52, 0.93])
	gene.mutations = [&"m_glow", &"m_fast"]
	return gene


func test_a_gene_survives_a_round_trip_through_a_dictionary() -> void:
	var original: PlantGene = _sample_gene()

	var restored: PlantGene = GeneCodec.from_dict(GeneCodec.to_dict(original))

	assert_not_null(restored)
	assert_eq(restored.uid, "abc123")
	assert_eq(restored.display_name, "Deneme")
	assert_eq(restored.generation, 4)
	assert_eq(restored.parent_uids, PackedStringArray(["p1", "p2"]))
	assert_eq(restored.stem_alleles, [&"stem_a", &"stem_r"] as Array[StringName])
	assert_eq(restored.fruit_alleles, [&"fruit_r", &"fruit_a"] as Array[StringName])
	assert_eq(restored.mutations, [&"m_glow", &"m_fast"] as Array[StringName])
	assert_almost_eq(restored.growth_alleles[0], 1.25, EPSILON)
	assert_almost_eq(restored.value_alleles[1], 3.0, EPSILON)
	assert_almost_eq(restored.hue_alleles[1], 0.93, EPSILON)


func test_a_gene_survives_a_round_trip_through_json_text() -> void:
	# Kayıt dosyası JSON metnidir: tamsayılar ondalığa dönse bile genotip aynı kalmalı
	var original: PlantGene = _sample_gene()

	var text: String = JSON.stringify(GeneCodec.to_dict(original))
	var parsed: Variant = JSON.parse_string(text)
	var restored: PlantGene = GeneCodec.from_dict(parsed as Dictionary)

	assert_not_null(restored)
	assert_eq(restored.generation, 4, "nesil tamsayı kalır")
	assert_eq(restored.stem_alleles, original.stem_alleles)
	assert_almost_eq(restored.hue_alleles[0], 0.52, EPSILON)


func test_a_restored_gene_is_independent_of_the_original() -> void:
	var original: PlantGene = _sample_gene()
	var restored: PlantGene = GeneCodec.from_dict(GeneCodec.to_dict(original))

	restored.stem_alleles[0] = &"changed"
	restored.growth_alleles[0] = 9.0

	assert_eq(original.stem_alleles[0], &"stem_a", "asıl gen değişmez")
	assert_almost_eq(original.growth_alleles[0], 1.25, EPSILON)


func test_malformed_data_returns_null() -> void:
	var data: Dictionary = GeneCodec.to_dict(_sample_gene())
	data["stem"] = ["stem_a"]  # tek alel: bozuk

	assert_null(GeneCodec.from_dict(data), "eksik alel")
	assert_null(GeneCodec.from_dict({}), "boş sözlük")
