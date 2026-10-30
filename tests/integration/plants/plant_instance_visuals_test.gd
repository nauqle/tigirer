extends TestCase
## PlantInstance: bir genotipi katmanlı sprite'lara çizer. Entegrasyon testi: gerçek sahne, gerçek kural seti
## ve gerçek SVG dokuları kullanılır (sahne ağacına eklenir, test bitince serbest bırakılır).

const SCENE_PATH: String = "res://src/gameplay/plants/plant_instance.tscn"
const RULESET_PATH: String = "res://assets/data/genetics/default_ruleset.tres"
const EPSILON: float = 0.001

var _ruleset: GeneticsRuleset
var _scene: PackedScene


func before_each() -> void:
	_ruleset = load(RULESET_PATH) as GeneticsRuleset
	_scene = load(SCENE_PATH) as PackedScene


## Sahneyi kurar, salınımı kapatır (deterministik), geni verir ve ağaca ekler.
func _spawn(gene: PlantGene, growth_value: float = 1.0) -> PlantInstance:
	var plant: PlantInstance = _scene.instantiate() as PlantInstance
	plant.sway_enabled = false
	plant.growth = growth_value
	plant.gene = gene
	add_to_tree(plant)
	return plant


func _homozygous(stem: StringName, leaf: StringName, fruit: StringName, hue: float = 0.97) -> PlantGene:
	var gene: PlantGene = PlantGene.homozygous(stem, leaf, fruit, hue)
	gene.uid = "test"
	return gene


func _leaf_sprites(plant: PlantInstance) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for child: Node in plant.get_node("%Leaves").get_children():
		if child is Sprite2D and (child as Sprite2D).visible:
			sprites.append(child as Sprite2D)
	return sprites


func _texture_of(id: StringName) -> Texture2D:
	return _ruleset.get_part(id).texture


# ------------------------------------------------------------------ katmanlar


func test_each_layer_uses_the_texture_of_the_expressed_part() -> void:
	# Arrange / Act
	var plant: PlantInstance = _spawn(_homozygous(&"stem_vine", &"leaf_fern", &"flower_tulip"))

	# Assert
	assert_eq((plant.get_node("%Stem") as Sprite2D).texture, _texture_of(&"stem_vine"), "gövde dokusu")
	assert_eq((plant.get_node("%Fruit") as Sprite2D).texture, _texture_of(&"flower_tulip"), "çiçek dokusu")
	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_false(leaves.is_empty(), "yaprak olmalı")
	for leaf: Sprite2D in leaves:
		assert_eq(leaf.texture, _texture_of(&"leaf_fern"), "yaprak dokusu")


func test_one_leaf_is_placed_at_every_mount_point_of_the_stem() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_bamboo", &"leaf_oval", &"fruit_pod"))

	var mounts: PackedVector2Array = _ruleset.get_part(&"stem_bamboo").leaf_mounts
	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_eq(leaves.size(), mounts.size(), "yaprak sayısı = bağlantı noktası sayısı")
	for i: int in leaves.size():
		assert_almost_eq(leaves[i].position.y, mounts[i].y, EPSILON, "yaprak %d dikey konumu bağlantıda" % i)


func test_leaves_alternate_between_the_two_sides_of_the_stem() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_true(leaves.size() >= 3, "en az üç yaprak")
	assert_true(leaves[0].scale.x > 0.0, "ilk yaprak sağa")
	assert_true(leaves[1].scale.x < 0.0, "ikinci yaprak sola (yatay çevrilmiş)")
	assert_true(leaves[2].scale.x > 0.0, "üçüncü yaprak yine sağa")


func test_leaves_fan_out_at_rising_alternating_angles() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_eq(leaves.size(), 3, "sınama koşulu: üç yaprak")
	for i: int in leaves.size():
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var expected: float = -side * deg_to_rad(plant.leaf_base_angle_degrees + plant.leaf_angle_step_degrees * float(i))
		assert_almost_eq(leaves[i].rotation, expected, EPSILON, "yaprak %d açısı" % i)


func test_each_leaf_higher_up_the_stem_is_smaller_by_the_falloff() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_eq(leaves.size(), 3, "sınama koşulu: üç yaprak")
	for i: int in leaves.size():
		var expected: float = 1.0 - plant.leaf_size_falloff * float(i)
		assert_almost_eq(absf(leaves[i].scale.y), expected, EPSILON, "yaprak %d boyutu" % i)


func test_every_layer_is_shifted_by_the_anchor_of_its_part() -> void:
	# Çapa: dokunun gövdeye oturan noktası. Sprite çapa kadar kaydırılır ki o nokta düğümün başlangıcına gelsin.
	var plant: PlantInstance = _spawn(_homozygous(&"stem_vine", &"leaf_fern", &"flower_star"))

	var stem_anchor: Vector2 = _ruleset.get_part(&"stem_vine").anchor
	var leaf_anchor: Vector2 = _ruleset.get_part(&"leaf_fern").anchor
	var fruit_anchor: Vector2 = _ruleset.get_part(&"flower_star").anchor
	assert_true(stem_anchor != Vector2.ZERO and leaf_anchor != Vector2.ZERO and fruit_anchor != Vector2.ZERO, "sınama koşulu: çapalar sıfır değil")
	assert_eq((plant.get_node("%Stem") as Sprite2D).offset, -stem_anchor, "gövde çapası")
	assert_eq((plant.get_node("%Fruit") as Sprite2D).offset, -fruit_anchor, "meyve çapası")
	for leaf: Sprite2D in _leaf_sprites(plant):
		assert_eq(leaf.offset, -leaf_anchor, "yaprak çapası")


func test_every_part_combination_renders_with_textures_on_every_layer() -> void:
	# 4 gövde x 5 yaprak x 6 meyve = 120 homozigot bitki; hiçbirinde boş doku olmamalı
	var stems: Array[PlantPartDef] = _ruleset.get_parts_for_layer(PlantPartDef.Layer.STEM)
	var leaves: Array[PlantPartDef] = _ruleset.get_parts_for_layer(PlantPartDef.Layer.LEAF)
	var fruits: Array[PlantPartDef] = _ruleset.get_parts_for_layer(PlantPartDef.Layer.FRUIT)
	var rendered: int = 0
	for stem: PlantPartDef in stems:
		for leaf: PlantPartDef in leaves:
			for fruit: PlantPartDef in fruits:
				var plant: PlantInstance = _spawn(_homozygous(stem.id, leaf.id, fruit.id))
				var complete: bool = (
					(plant.get_node("%Stem") as Sprite2D).texture != null
					and (plant.get_node("%Fruit") as Sprite2D).texture != null
					and not _leaf_sprites(plant).is_empty()
				)
				assert_true(complete, "%s + %s + %s eksik katman" % [stem.id, leaf.id, fruit.id])
				rendered += 1
				plant.free()
	assert_eq(rendered, 120)


# --------------------------------------------------------------------- renk


func test_the_fruit_takes_the_genetic_hue_and_leaves_are_pulled_toward_it() -> void:
	# Arrange: ton 0.80 (mor); yapraklar yeşilden (0.36) bu tona doğru `leaf_hue_pull` oranında çekilmeli
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.80))

	# Act
	var fruit_hue: float = (plant.get_node("%Fruit") as Sprite2D).modulate.h
	var leaf_hue: float = _leaf_sprites(plant)[0].modulate.h
	var stem_hue: float = (plant.get_node("%Stem") as Sprite2D).modulate.h

	# Assert: kesin beklenen ton (boşluklu karşılaştırma, kayan nokta gürültüsüyle yanlış geçmesin)
	var expected_leaf_hue: float = ColorMath.lerp_hue(plant.leaf_green_hue, 0.80, plant.leaf_hue_pull)
	assert_almost_eq(ColorMath.hue_distance(fruit_hue, 0.80), 0.0, 0.01, "meyve genetik tonda")
	assert_almost_eq(ColorMath.hue_distance(leaf_hue, expected_leaf_hue), 0.0, 0.01, "yaprak yeşilden genetik tona doğru çekilmiş")
	assert_almost_eq(ColorMath.hue_distance(stem_hue, expected_leaf_hue), 0.0, 0.01, "gövde yaprakla aynı tonda")
	assert_true(ColorMath.hue_distance(leaf_hue, plant.leaf_green_hue) > 0.05, "yaprak saf yeşil olmamalı")


func test_the_palette_knobs_set_saturation_and_brightness_of_every_layer() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.80))

	var stem: Color = (plant.get_node("%Stem") as Sprite2D).modulate
	var leaf: Color = _leaf_sprites(plant)[0].modulate
	var fruit: Color = (plant.get_node("%Fruit") as Sprite2D).modulate
	assert_almost_eq(stem.s, plant.stem_saturation, 0.01, "gövde doygunluğu")
	assert_almost_eq(stem.v, plant.stem_value, 0.01, "gövde parlaklığı")
	assert_almost_eq(leaf.s, plant.leaf_saturation, 0.01, "yaprak doygunluğu")
	assert_almost_eq(leaf.v, plant.leaf_value, 0.01, "yaprak parlaklığı")
	assert_almost_eq(fruit.s, plant.fruit_saturation, 0.01, "meyve doygunluğu")
	assert_almost_eq(fruit.v, plant.fruit_value, 0.01, "meyve parlaklığı")


func test_the_golden_mutation_forces_the_fruit_tint() -> void:
	# Arrange
	var gene: PlantGene = _homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.30)
	gene.mutations = [&"golden"]

	# Act
	var plant: PlantInstance = _spawn(gene)

	# Assert: yeşil bir bitki bile altın meyve verir
	var tint: Color = (plant.get_node("%Fruit") as Sprite2D).modulate
	assert_almost_eq(tint.r, 1.0, 0.01, "altın kırmızı")
	assert_almost_eq(tint.g, 0.82, 0.01, "altın yeşil")
	assert_almost_eq(tint.b, 0.25, 0.01, "altın mavi")


# ------------------------------------------------------------------ parlama


func test_a_luminous_mutation_shows_the_halo_and_sets_the_glow_parameters() -> void:
	# Arrange
	var gene: PlantGene = _homozygous(&"stem_vine", &"leaf_fern", &"flower_star")
	gene.mutations = [&"luminescent"]

	# Act
	var plant: PlantInstance = _spawn(gene)

	# Assert
	var material: ShaderMaterial = (plant.get_node("%Stem") as Sprite2D).material as ShaderMaterial
	assert_not_null(material, "katmanlar gölgelendirici malzeme kullanır")
	var halo: Sprite2D = plant.get_node("%Halo") as Sprite2D
	var glow_color: Color = _ruleset.get_mutation(&"luminescent").glow_color
	assert_true(halo.visible, "halo görünür")
	assert_almost_eq(halo.modulate.a, plant.halo_alpha, EPSILON, "halo saydamlığı = halo_alpha x parlama gücü (1.0)")
	assert_almost_eq(halo.modulate.r, glow_color.r, EPSILON, "halo mutasyonun parlama renginde")
	assert_almost_eq(halo.modulate.g, glow_color.g, EPSILON, "halo mutasyonun parlama renginde")
	assert_almost_eq(float(material.get_shader_parameter("glow_strength")), 1.0, EPSILON, "parlama gücü")
	assert_true((material.get_shader_parameter("glow_color") as Color).is_equal_approx(glow_color), "gölgelendirici parlama rengi")


func test_a_plain_plant_has_no_halo_and_no_glow() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_vine", &"leaf_fern", &"flower_star"))

	var material: ShaderMaterial = (plant.get_node("%Stem") as Sprite2D).material as ShaderMaterial
	assert_false((plant.get_node("%Halo") as Sprite2D).visible, "halo gizli")
	assert_almost_eq(float(material.get_shader_parameter("glow_strength")), 0.0, EPSILON)
	assert_almost_eq(float(material.get_shader_parameter("shimmer")), 0.0, EPSILON)


func test_all_layers_of_a_plant_share_one_material() -> void:
	var gene: PlantGene = _homozygous(&"stem_vine", &"leaf_fern", &"flower_star")
	gene.mutations = [&"crystalline"]

	var plant: PlantInstance = _spawn(gene)

	var stem_material: Material = (plant.get_node("%Stem") as Sprite2D).material
	assert_eq((plant.get_node("%Fruit") as Sprite2D).material, stem_material, "meyve aynı malzemeyi kullanır")
	for leaf: Sprite2D in _leaf_sprites(plant):
		assert_eq(leaf.material, stem_material, "yaprak aynı malzemeyi kullanır")
	assert_almost_eq(float((stem_material as ShaderMaterial).get_shader_parameter("shimmer")), 1.0, EPSILON, "kristal parıltısı")


func test_each_plant_gets_its_own_material_so_glows_do_not_leak_between_plants() -> void:
	# Arrange: biri parlayan, biri sıradan iki bitki
	var glowing_gene: PlantGene = _homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry")
	glowing_gene.mutations = [&"luminescent"]
	var glowing: PlantInstance = _spawn(glowing_gene)
	var plain: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	# Assert
	var glowing_material: Material = (glowing.get_node("%Stem") as Sprite2D).material
	var plain_material: Material = (plain.get_node("%Stem") as Sprite2D).material
	assert_ne(glowing_material, plain_material, "malzeme paylaşılmamalı")
	assert_almost_eq(float((plain_material as ShaderMaterial).get_shader_parameter("glow_strength")), 0.0, EPSILON)


# ------------------------------------------------------------------- büyüme


func test_a_seedling_is_small_and_has_no_fruit_while_a_mature_plant_is_full_size() -> void:
	# Arrange
	var gene: PlantGene = _homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry")
	var seedling: PlantInstance = _spawn(gene, 0.1)
	var mature: PlantInstance = _spawn(gene, 1.0)

	# Assert
	var seedling_stem: Sprite2D = seedling.get_node("%Stem") as Sprite2D
	var seedling_fruit: Sprite2D = seedling.get_node("%Fruit") as Sprite2D
	assert_true(seedling_stem.scale.y < 0.5, "filiz kısa")
	assert_true(seedling_stem.scale.x < 0.9, "filiz ince")
	assert_false(seedling_fruit.visible, "filizde meyve gizli (sıfır ölçekli ama görünür sprite bırakılmaz)")
	var mature_stem: Sprite2D = mature.get_node("%Stem") as Sprite2D
	assert_almost_eq(mature_stem.scale.y, 1.0, EPSILON, "olgun bitki tam boy")
	assert_true((mature.get_node("%Fruit") as Sprite2D).visible, "olgun bitkide meyve görünür")
	assert_almost_eq((mature.get_node("%Fruit") as Sprite2D).scale.x, 1.0, EPSILON, "olgun bitkide meyve tam boy")


func test_the_fruit_pops_in_gradually_after_its_start_threshold() -> void:
	# Arrange: eşik ile olgunluk arasının tam ortası; smoothstep(0.5) = 0.5
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"), 0.0)

	# Act
	plant.growth = lerpf(plant.fruit_start_at, 1.0, 0.5)

	# Assert
	var fruit: Sprite2D = plant.get_node("%Fruit") as Sprite2D
	assert_true(fruit.visible, "eşiği geçince meyve görünür")
	assert_almost_eq(fruit.scale.x, 0.5, EPSILON, "yarı yolda meyve yarı boyda")


func test_leaves_appear_one_by_one_as_the_plant_grows() -> void:
	# Arrange: 3 yaprak; eşikler 0.25, 0.525, 0.8 (leaf_start_at → leaf_full_at arası eşit aralık), açılış süresi 0.15
	var gene: PlantGene = _homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry")
	var plant: PlantInstance = _spawn(gene, 0.0)
	assert_eq(_ruleset.get_part(&"stem_reed").leaf_mounts.size(), 3, "sınama koşulu: gövdede 3 yaprak bağlantısı")

	# Act
	var counts: Array[int] = []
	for growth_value: float in [0.0, 0.35, 0.6, 1.0]:
		plant.growth = growth_value
		counts.append(_leaf_sprites(plant).size())

	# Assert: yapraklar aynı anda değil, sırayla belirir
	assert_eq(counts[0], 0, "tohumda yaprak yok")
	assert_eq(counts[1], 1, "filizde yalnızca ilk yaprak")
	assert_eq(counts[2], 2, "ortada iki yaprak")
	assert_eq(counts[3], 3, "olgun bitkide tüm yapraklar")


func test_growth_is_clamped_to_the_zero_one_range() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	plant.growth = 7.0
	assert_almost_eq(plant.growth, 1.0, EPSILON, "üst sınır")
	plant.growth = -3.0
	assert_almost_eq(plant.growth, 0.0, EPSILON, "alt sınır")


func test_leaves_follow_the_stem_while_it_is_still_growing() -> void:
	# Arrange: 0.3'te ilk yaprak belirmiştir, gövde ise henüz tam boyda değildir
	var plant: PlantInstance = _spawn(_homozygous(&"stem_vine", &"leaf_fern", &"flower_tulip"), 0.3)
	var stem: Sprite2D = plant.get_node("%Stem") as Sprite2D
	var mounts: PackedVector2Array = _ruleset.get_part(&"stem_vine").leaf_mounts

	# Assert: yaprak konumu = bağlantı noktası x gövdenin güncel ölçeği
	var leaves: Array[Sprite2D] = _leaf_sprites(plant)
	assert_false(leaves.is_empty(), "sınama koşulu: ilk yaprak belirmiş")
	assert_true(stem.scale.y < 0.9, "sınama koşulu: gövde henüz tam boyda değil")
	assert_almost_eq(leaves[0].position.x, mounts[0].x * stem.scale.x, EPSILON, "yaprak x konumu gövdeyle ölçeklenir")
	assert_almost_eq(leaves[0].position.y, mounts[0].y * stem.scale.y, EPSILON, "yaprak y konumu gövdeyle ölçeklenir")


func test_the_fruit_and_the_halo_ride_the_top_of_the_growing_stem() -> void:
	# Arrange: varsayılan eğride meyve gövde tam boya erince belirir; ayar düğmeleriyle gövde büyürken belirtilir
	var gene: PlantGene = _homozygous(&"stem_vine", &"leaf_fern", &"flower_star")
	gene.mutations = [&"luminescent"]
	var plant: PlantInstance = _spawn(gene, 0.0)
	plant.stem_full_at = 1.0
	plant.fruit_start_at = 0.2

	# Act
	plant.growth = 0.5

	# Assert
	var stem: Sprite2D = plant.get_node("%Stem") as Sprite2D
	var fruit: Sprite2D = plant.get_node("%Fruit") as Sprite2D
	var halo: Sprite2D = plant.get_node("%Halo") as Sprite2D
	var mount: Vector2 = _ruleset.get_part(&"stem_vine").fruit_mount
	assert_true(fruit.visible, "sınama koşulu: meyve belirmiş")
	assert_true(stem.scale.y < 0.9, "sınama koşulu: gövde henüz tam boyda değil")
	assert_almost_eq(fruit.position.x, mount.x * stem.scale.x, EPSILON, "meyve x konumu gövdeyle ölçeklenir")
	assert_almost_eq(fruit.position.y, mount.y * stem.scale.y, EPSILON, "meyve y konumu gövdeyle ölçeklenir")
	assert_almost_eq(halo.position.x, fruit.position.x, EPSILON, "halo meyvenin üzerinde (x)")
	assert_almost_eq(halo.position.y, fruit.position.y, EPSILON, "halo meyvenin üzerinde (y)")


func test_the_halo_grows_with_the_plant() -> void:
	var gene: PlantGene = _homozygous(&"stem_vine", &"leaf_fern", &"flower_star")
	gene.mutations = [&"luminescent"]
	var plant: PlantInstance = _spawn(gene, 0.0)
	var halo: Sprite2D = plant.get_node("%Halo") as Sprite2D

	assert_almost_eq(halo.scale.x, 0.0, EPSILON, "tohumda halo yok")

	plant.growth = 1.0
	assert_almost_eq(halo.scale.x, plant.halo_size.x / float(halo.texture.get_width()), EPSILON, "olgunda halo tam boy")


# ------------------------------------------------------------------- hareket


func test_a_plant_with_sway_disabled_stands_upright() -> void:
	# `_spawn` salınımı kapatır
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))

	assert_almost_eq((plant.get_node("%Rig") as Node2D).rotation, 0.0, EPSILON)


func test_the_sway_can_be_switched_on_and_off_at_runtime() -> void:
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))
	var rig: Node2D = plant.get_node("%Rig") as Node2D

	plant.sway_enabled = true
	assert_true(absf(rig.rotation) > EPSILON, "salınım başladı")

	plant.sway_enabled = false
	assert_almost_eq(rig.rotation, 0.0, EPSILON, "salınım durdu, bitki dik")


func test_plants_with_different_signatures_pulse_out_of_phase() -> void:
	# Aynı anda nabız atan bir bahçe yapay görünür: faz imzadan türetilir
	var first: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry", 0.97))
	var second: PlantInstance = _spawn(_homozygous(&"stem_vine", &"leaf_fern", &"flower_tulip", 0.80))

	var first_phase: float = float(((first.get_node("%Stem") as Sprite2D).material as ShaderMaterial).get_shader_parameter("phase"))
	var second_phase: float = float(((second.get_node("%Stem") as Sprite2D).material as ShaderMaterial).get_shader_parameter("phase"))

	assert_ne(first_phase, second_phase, "farklı imza, farklı faz")


# -------------------------------------------------------------- gen değişimi


func test_changing_the_gene_rebuilds_the_visuals_and_announces_it() -> void:
	# Arrange
	var plant: PlantInstance = _spawn(_homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry"))
	var rebuilt: Dictionary = {"count": 0}
	plant.visuals_rebuilt.connect(func() -> void: rebuilt["count"] += 1)

	# Act
	plant.gene = _homozygous(&"stem_bamboo", &"leaf_spiky", &"flower_star")

	# Assert
	assert_eq((plant.get_node("%Stem") as Sprite2D).texture, _texture_of(&"stem_bamboo"), "yeni gövde")
	assert_eq((plant.get_node("%Fruit") as Sprite2D).texture, _texture_of(&"flower_star"), "yeni çiçek")
	assert_eq(rebuilt["count"], 1, "tam bir kez yeniden kurulmalı")


func test_a_null_gene_clears_the_visuals_without_error() -> void:
	# Arrange: parlayan bir bitki (halo da temizlenmeli)
	var gene: PlantGene = _homozygous(&"stem_reed", &"leaf_oval", &"fruit_berry")
	gene.mutations = [&"luminescent"]
	var plant: PlantInstance = _spawn(gene)
	assert_true((plant.get_node("%Halo") as Sprite2D).visible, "sınama koşulu: halo görünür")

	# Act
	plant.gene = null

	# Assert
	assert_null((plant.get_node("%Stem") as Sprite2D).texture, "gövde boşalır")
	assert_true(_leaf_sprites(plant).is_empty(), "yaprak kalmaz")
	assert_false((plant.get_node("%Fruit") as Sprite2D).visible, "meyve gizlenir")
	assert_false((plant.get_node("%Halo") as Sprite2D).visible, "halo gizlenir")
	assert_null(plant.get_phenotype(), "fenotip yok")


func test_a_stem_with_fewer_mount_points_hides_the_spare_leaf_sprites() -> void:
	# Arrange: tek yaprak bağlantılı bir gövde türü (yeni içerikte olabilir); kural setinin kopyasına eklenir
	var short_stem: PlantPartDef = PlantPartDef.new()
	short_stem.id = &"stem_test_short"
	short_stem.layer = PlantPartDef.Layer.STEM
	short_stem.texture = _texture_of(&"stem_bamboo")
	short_stem.leaf_mounts = PackedVector2Array([_ruleset.get_part(&"stem_bamboo").leaf_mounts[0]])
	var parts: Array[PlantPartDef] = []
	parts.assign(_ruleset.parts)
	parts.append(short_stem)
	var ruleset: GeneticsRuleset = GeneticsRuleset.new()
	ruleset.parts = parts
	ruleset.mutations = _ruleset.mutations

	var plant: PlantInstance = _scene.instantiate() as PlantInstance
	plant.sway_enabled = false
	plant.ruleset = ruleset
	plant.gene = _homozygous(&"stem_bamboo", &"leaf_oval", &"fruit_pod")
	add_to_tree(plant)
	assert_eq(_leaf_sprites(plant).size(), 3, "sınama koşulu: önce üç yaprak")

	# Act
	plant.gene = _homozygous(&"stem_test_short", &"leaf_oval", &"fruit_pod")

	# Assert: fazla havuz sprite'ları gizlenir, eski yapraklar ekranda kalmaz
	assert_eq(_leaf_sprites(plant).size(), 1, "tek bağlantı, tek yaprak")


func test_the_phenotype_accessor_matches_the_engine() -> void:
	var gene: PlantGene = _homozygous(&"stem_vine", &"leaf_fern", &"flower_star")
	gene.mutations = [&"golden"]

	var plant: PlantInstance = _spawn(gene)

	assert_eq(plant.get_phenotype().signature, GeneticsEngine.express(gene, _ruleset).signature)
